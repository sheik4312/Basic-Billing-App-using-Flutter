import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AmountPage extends StatefulWidget {
  @override
  _AmountPageState createState() => _AmountPageState();
}

class _AmountPageState extends State<AmountPage> {
  String _selectedSeller = '';
  String _selectedFilter = 'All';
  String? _selectedDocumentId;
  bool _showDetailView = false;
  Map<String, dynamic>? _currentDocumentData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedSeller.isEmpty ? 'Amount Page' : _selectedSeller),
        leading: _showDetailView || _selectedSeller.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (_showDetailView) {
                      _showDetailView = false;
                      _currentDocumentData = null;
                    } else {
                      _selectedSeller = '';
                      _showDetailView = false;
                      _currentDocumentData = null;
                    }
                  });
                },
              )
            : null,
        actions: !_showDetailView
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: CustomSearchDelegate(
                        onSellerSelected: (String sellerName) {
                          setState(() {
                            _selectedSeller = sellerName;
                          });
                        },
                      ),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (String result) {
                    setState(() {
                      _selectedFilter = result;
                    });
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(value: 'All', child: Text('All')),
                    const PopupMenuItem(
                        value: 'Fully Paid', child: Text('Fully Paid')),
                    const PopupMenuItem(
                        value: 'Partially Paid', child: Text('Partially Paid')),
                    const PopupMenuItem(
                        value: 'Not Paid', child: Text('Not Paid')),
                  ],
                ),
              ]
            : [],
      ),
      body: _showDetailView
          ? _buildDetailView()
          : _selectedSeller.isEmpty
              ? _buildSellerList()
              : _buildBorrowList(),
    );
  }

  Widget _buildSellerList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sellers').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No sellers available'));
        }

        List<DocumentSnapshot> sellerDocuments = snapshot.data!.docs;

        return ListView(
          children: sellerDocuments.map((DocumentSnapshot sellerDoc) {
            String sellerName = sellerDoc.id;

            return ListTile(
              title: Text(sellerName),
              onTap: () {
                setState(() {
                  _selectedSeller = sellerName;
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBorrowList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sellers')
          .doc(_selectedSeller)
          .collection('borrow')
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No bills found for $_selectedSeller'));
        }

        List<DocumentSnapshot> documents = snapshot.data!.docs;

        List<DocumentSnapshot> filteredDocuments = documents.where((document) {
          Map<String, dynamic> data = document.data() as Map<String, dynamic>;
          double billAmount = _parseToDouble(data['BillAmount']);
          double paidAmount = _parseToDouble(data['PaidAmount']);
          double remainingAmount = billAmount - paidAmount;

          switch (_selectedFilter) {
            case 'Fully Paid':
              return remainingAmount <= 0;
            case 'Partially Paid':
              return paidAmount > 0 && remainingAmount > 0;
            case 'Not Paid':
              return paidAmount <= 0;
            default:
              return true;
          }
        }).toList();

        return ListView(
          children: filteredDocuments.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;

            double billAmount = _parseToDouble(data['BillAmount']);
            double paidAmount = _parseToDouble(data['PaidAmount']);
            double remainingAmount = billAmount - paidAmount;

            IconData statusIcon;
            Color statusColor;

            if (remainingAmount <= 0) {
              statusIcon = Icons.check_circle;
              statusColor = Colors.green;
            } else if (paidAmount > 0) {
              statusIcon = Icons.payment;
              statusColor = Colors.orange;
            } else {
              statusIcon = Icons.error;
              statusColor = Colors.red;
            }

            return ListTile(
              leading: Icon(statusIcon, color: statusColor),
              title: Text(data['Billno'] ?? 'No Bill Number'),
              subtitle: Text(
                  'Bill Amount: $billAmount\nPaid Amount: $paidAmount\nDate: ${data['date']}'),
              onTap: () {
                setState(() {
                  _selectedDocumentId = document.id;
                  _currentDocumentData = data;
                  _showDetailView = true;
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDetailView() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('sellers')
          .doc(_selectedSeller)
          .collection('borrow')
          .doc(_selectedDocumentId)
          .get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Document does not exist'));
        }

        Map<String, dynamic> data =
            snapshot.data!.data() as Map<String, dynamic>;

        double billAmount = _parseToDouble(data['BillAmount']);
        double paidAmount = _parseToDouble(data['PaidAmount']);
        double remainingAmount = billAmount - paidAmount;

        List<dynamic> payments = data['payments'] ?? [];
        String? imageUrl = data['imageUrl']; // Retrieve image URL

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    // Show full-screen image dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: InteractiveViewer(
                            child: Image.network(imageUrl, fit: BoxFit.contain),
                          ),
                        );
                      },
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text('Bill Amount: $billAmount',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              Text('Paid Amount: $paidAmount',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              Text('Remaining Amount: $remainingAmount',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Billno: ${data['Billno'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text('Date: ${data['date'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              const Text('Payment History:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Column(
                children: payments.map((payment) {
                  return ListTile(
                    title: Text('Amount Paid: ${payment['amountPaid']}'),
                    subtitle: Text('Date & Time: ${payment['timestamp']}'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (remainingAmount > 0) ...[
                // Show payment buttons only if there is a remaining amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showPaymentDialog(data, isFullAmount: false);
                      },
                      child: const Text('Partial Amount'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _showPaymentDialog(data, isFullAmount: true);
                      },
                      child: const Text('Full Amount'),
                    ),
                  ],
                ),
              ] else ...[
                // Show 'Paid Successful' message if the remaining amount is 0 or less
                const Center(
                  child: Text('Payment Successful',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  double _parseToDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else {
      return 0.0;
    }
  }

  void _showPaymentDialog(Map<String, dynamic> data,
      {required bool isFullAmount}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double paymentAmount = isFullAmount ? 0.0 : 0.0;

        // Calculate remaining amount
        double billAmount = _parseToDouble(data['BillAmount']);
        double paidAmount = _parseToDouble(data['PaidAmount']);
        double remainingAmount = billAmount - paidAmount;

        return AlertDialog(
          title:
              Text(isFullAmount ? 'Pay Full Amount' : 'Enter Partial Payment'),
          content: isFullAmount
              ? Text(
                  'Full amount will be paid. Remaining Amount: $remainingAmount')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Remaining Amount: $remainingAmount'),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        paymentAmount = double.tryParse(value) ?? 0.0;
                      },
                      decoration:
                          const InputDecoration(hintText: 'Payment Amount'),
                    ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (isFullAmount) {
                  paymentAmount = remainingAmount;
                }
                if (paymentAmount > remainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Payment amount exceeds the remaining amount.'),
                    ),
                  );
                  return;
                }
                _processPayment(paymentAmount);
                Navigator.of(context).pop();
              },
              child: const Text('Pay'),
            ),
          ],
        );
      },
    );
  }

  void _processPayment(double amount) {
    if (amount <= 0 || _selectedDocumentId == null) return;

    FirebaseFirestore.instance
        .collection('sellers')
        .doc(_selectedSeller)
        .collection('borrow')
        .doc(_selectedDocumentId)
        .update({
      'PaidAmount': FieldValue.increment(amount),
      'payments': FieldValue.arrayUnion([
        {
          'amountPaid': amount,
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())
        }
      ]),
    }).then((_) {
      setState(() {
        _showDetailView = false;
      });
    }).catchError((error) {
      print('Failed to update payment: $error');
    });
  }
}

class CustomSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSellerSelected;

  CustomSearchDelegate({required this.onSellerSelected});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _fetchSellers(query),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        List<String> sellers = snapshot.data!;

        return ListView(
          children: sellers.map((sellerName) {
            return ListTile(
              title: Text(sellerName),
              onTap: () {
                onSellerSelected(sellerName);
                close(context, sellerName);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<String>> _fetchSellers(String query) async {
    if (query.isEmpty) return [];

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('sellers')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: query)
        .where(FieldPath.documentId, isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
