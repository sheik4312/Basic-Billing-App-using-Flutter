import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import the intl package
import 'billdetailsscreen.dart';
import 'drawer.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({Key? key});

  @override
  _BillsPageState createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  String? selectedBillId;
  DateTimeRange? selectedDateRange;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }

  Stream<QuerySnapshot> _getBillsStream() {
    Query query = FirebaseFirestore.instance.collection('bills');

    if (selectedDateRange != null) {
      query = query
          .where('timestamp', isGreaterThanOrEqualTo: selectedDateRange!.start)
          .where('timestamp', isLessThanOrEqualTo: selectedDateRange!.end);
    }

    return query.snapshots();
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 45, 44, 124),
        title: const Text(
          'Bills',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      drawer: const CustomDrawer(
        initialSelectedIndex: 3,
      ),
      body: StreamBuilder(
        stream: _getBillsStream(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No bills found'),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              int billNumber = data['bill_number'];
              Timestamp timestamp = data['timestamp'];
              String formattedDate =
                  DateFormat('yyyy-MM-dd').format(timestamp.toDate());
              double? totalProfit =
                  data['total_profit']; // Retrieve total profit

              return Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BillDetailsScreen(billId: document.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bill Number: $billNumber',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Date: $formattedDate',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              if (totalProfit !=
                                  null) // Check if totalProfit is not null
                                Text(
                                  'TP: INR${totalProfit.toStringAsFixed(2)}', // Display total profit
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.green),
                                ),
                              if (totalProfit ==
                                  null) // If totalProfit is null, display a message
                                const Text(
                                  'Total Profit: Not available',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildWindowsLayout() {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 45, 44, 124),
        title: const Text(
          'Bills',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      drawer: const CustomDrawer(
        initialSelectedIndex: 3,
      ),
      body: Row(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _getBillsStream(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
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

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No bills found'),
                  );
                }

                return ListView(
                  children:
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data() as Map<String, dynamic>;
                    int billNumber = data['bill_number'];
                    Timestamp timestamp = data['timestamp'];
                    String formattedDate =
                        DateFormat('yyyy-MM-dd').format(timestamp.toDate());
                    double? totalProfit = data['total_profit'];

                    return Card(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedBillId = document.id;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bill Number: $billNumber',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Date: $formattedDate',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              if (totalProfit != null)
                                Text(
                                  'TP: INR${totalProfit.toStringAsFixed(2)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.green),
                                ),
                              if (totalProfit == null)
                                const Text(
                                  'Total Profit: Not available',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Expanded(
            child: WillPopScope(
              onWillPop: () async {
                if (selectedBillId != null) {
                  setState(() {
                    selectedBillId = null;
                  });
                  return false;
                }
                return true;
              },
              child: selectedBillId != null
                  ? BillDetailsScreen(billId: selectedBillId!)
                  : const Center(
                      child: Text('Select a bill to see details'),
                    ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows || kIsWeb) {
      return _buildWindowsLayout();
    } else {
      return _buildMobileLayout();
    }
  }
}
