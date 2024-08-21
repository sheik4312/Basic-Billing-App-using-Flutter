import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailPage extends StatefulWidget {
  final String documentId;

  DetailPage({required this.documentId});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final TextEditingController _partialAmountController =
      TextEditingController();
  late double remainingAmount;

  @override
  void initState() {
    super.initState();
    remainingAmount = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail View'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('borrow')
            .doc(widget.documentId)
            .get(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Document does not exist'));
          }

          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;

          double billAmount = _parseToDouble(data['BillAmount']);
          double paidAmount = _parseToDouble(data['PaidAmount']);
          remainingAmount = billAmount - paidAmount;

          List<dynamic> payments = data['payments'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${data['Name'] ?? 'No Name'}',
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text('Bill Amount: $billAmount',
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text('Paid Amount: $paidAmount',
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text('Remaining Amount: $remainingAmount',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('Billno: ${data['Billno'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text('Date: ${data['date'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),
                Text('Payment History:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      var payment = payments[index];
                      return ListTile(
                        title: Text('Amount Paid: ${payment['amountPaid']}'),
                        subtitle: Text('Date & Time: ${payment['dateTime']}'),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                if (remainingAmount > 0) ...[
                  TextField(
                    controller: _partialAmountController,
                    decoration: InputDecoration(
                      labelText: 'Enter Partial Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () => _payPartialAmount(data),
                        child: Text('Pay Partial'),
                      ),
                      ElevatedButton(
                        onPressed: () => _payFullAmount(data),
                        child: Text('Pay Full'),
                      ),
                    ],
                  ),
                ] else ...[
                  Center(
                    child: Text(
                      'Paid Successfully',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  double _parseToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _payPartialAmount(Map<String, dynamic> data) {
    double partialAmount =
        double.tryParse(_partialAmountController.text) ?? 0.0;

    if (partialAmount <= 0 || partialAmount > remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a valid partial amount')),
      );
      return;
    }

    double newPaidAmount = _parseToDouble(data['PaidAmount']) + partialAmount;
    String currentDateTime = _getCurrentDateTime();

    FirebaseFirestore.instance
        .collection('borrow')
        .doc(widget.documentId)
        .update({
      'PaidAmount': newPaidAmount,
      'lastPaidDateTime': currentDateTime, // Update with current date and time
      'payments': FieldValue.arrayUnion([
        // Add the new payment record
        {'amountPaid': partialAmount, 'dateTime': currentDateTime}
      ])
    });

    setState(() {
      remainingAmount -= partialAmount;
      _partialAmountController.clear();
    });
  }

  void _payFullAmount(Map<String, dynamic> data) {
    double remainingAmount =
        _parseToDouble(data['BillAmount']) - _parseToDouble(data['PaidAmount']);

    if (remainingAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill is already fully paid')),
      );
      return;
    }

    String currentDateTime = _getCurrentDateTime();

    FirebaseFirestore.instance
        .collection('borrow')
        .doc(widget.documentId)
        .update({
      'PaidAmount': _parseToDouble(data['BillAmount']),
      'lastPaidDateTime': currentDateTime, // Update with current date and time
      'payments': FieldValue.arrayUnion([
        // Add the new payment record
        {'amountPaid': remainingAmount, 'dateTime': currentDateTime}
      ])
    });

    setState(() {
      remainingAmount = 0;
    });
  }

  String _getCurrentDateTime() {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  }
}
