import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillDetailsScreen extends StatelessWidget {
  final String billId;

  const BillDetailsScreen({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 45, 44, 124),
        title: const Text(
          'Bill Details',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('bills')
            .doc(billId)
            .snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return const Center(
              child: Text('No data found for this bill'),
            );
          }

          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> items = data['items'];
          double totalAmount = data['total_amount'];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Total Amount: INR $totalAmount',
                style: const TextStyle(
                    fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Items:',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Item Name')),
                  DataColumn(label: Text('Quantity')),
                  DataColumn(label: Text('Total')),
                ],
                rows: items.map<DataRow>((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text('${item['item_name']}')),
                      DataCell(Text('${item['quantity']}')),
                      DataCell(Text('${item['total_amount']}')),
                    ],
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
