import 'dart:io';
import 'package:intl/intl.dart';
import 'package:inventory/adapt_string_tamil.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'drawer.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class CartItem {
  String itemName;
  double quantity;
  double price;
  double gstPercentage;
  double buyingPrice;
  String unit; // New parameter to store the unit

  CartItem({
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.gstPercentage,
    required this.buyingPrice,
    required this.unit, // Include unit in the constructor
  });
}

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isVoiceSearchEnabled = false;
  List<String> _filteredItemNames = [];
  bool _isSearching = false;
  stt.SpeechToText _speech = stt.SpeechToText();
  List<CartItem> _cartItems = [];
  int _billNumber = 0; // Variable to store the current bill number

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _fetchLastBillNumber();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _fetchLastBillNumber() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bill_numbers')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        // If documents exist, set the bill number to the next available number
        setState(() {
          int lastBillNumber = snapshot.docs.first['bill_number'];
          _billNumber = _generateUniqueBillNumber(lastBillNumber);
        });
      } else {
        // If no documents exist, set the bill number to a random 4-digit number
        setState(() {
          _billNumber = _generateRandomUniqueBillNumber();
        });
      }
    } catch (e) {
      print('Error fetching last bill number: $e');
    }
  }

  int _generateUniqueBillNumber(int lastBillNumber) {
    int newBillNumber;
    do {
      newBillNumber = Random().nextInt(9000) + 1000;
    } while (newBillNumber == lastBillNumber);
    return newBillNumber;
  }

  int _generateRandomUniqueBillNumber() {
    List<int> usedNumbers = [];
    int newBillNumber;
    do {
      newBillNumber = Random().nextInt(9000) + 1000;
    } while (usedNumbers.contains(newBillNumber));
    usedNumbers.add(newBillNumber);
    return newBillNumber;
  }

  void _initializeSpeech() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // For Android and iOS, use the speech_to_text package
      bool available = await _initializeSpeechForMobile();
      if (available) {
      } else {}
    } else if (Platform.isWindows) {}
  }

  Future<bool> _initializeSpeechForMobile() async {
    bool available = await _speech.initialize();
    return available;
  }

  void _toggleVoiceSearch() {
    setState(() {
      _isVoiceSearchEnabled = !_isVoiceSearchEnabled;
      if (_isVoiceSearchEnabled) {
        _startListening();
      } else {
        _stopListening();
      }
    });
  }

  void _stopListening() {
    _speech.stop();
  }

  void _startListening() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // For Android and iOS, use the speech_to_text package
      await _startListeningForMobile();
    } else if (Platform.isWindows) {}
  }

  Future<void> _startListeningForMobile() async {
    bool available = await _speech.initialize(
      onStatus: (status) {},
      onError: (error) {},
    );
    if (available) {
      _speech.listen(
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
          });
          // Process user input and show related text
          _processUserInput(result.recognizedWords);
        },
        listenFor: const Duration(seconds: 10), // Adjust the duration as needed
        localeId: 'ta-IN', // Specify Tamil locale
        partialResults: true,
        // Enable partial results
      );
    } else {
      // Speech initialization failed
    }
  }

  void _processUserInput(String userInput) {
    // Clear the search list
    setState(() {
      _filteredItemNames.clear();
    });
    // Fetch item names related to the recognized words
    _fetchItemNames(userInput);
  }

  void _addToCart(String itemName, double quantity) {
    _fetchItemDetails(itemName).then((itemDetails) {
      if (itemDetails != null) {
        // Item details fetched successfully
        setState(() {
          // Check if quantity is less than 1 and unit is 'kg'
          if (quantity < 1 && itemDetails['unit'] == 'kg') {
            // Convert quantity to grams (1 kg = 1000 g)
            quantity *= 1000;
            // Adjust price based on the conversion
            itemDetails['price'] /=
                1000; // Divide the price by 1000 to get price per gram
            itemDetails['unit'] = 'g'; // Change unit to grams
          }
          // Add the item to the cart with the fetched details
          _cartItems.add(CartItem(
            itemName: itemName,
            quantity: quantity,
            price: itemDetails['price'],
            gstPercentage: itemDetails['gstPercentage'],
            buyingPrice: itemDetails['buyingPrice'],
            unit: itemDetails['unit'], // Provide the unit
          ));
        });
      }
    }).catchError((error) {});
  }

  Future<Map<String, dynamic>?> _fetchItemDetails(String itemName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('item_name', isEqualTo: itemName)
          .get();
      if (snapshot.docs.isNotEmpty) {
        // Assuming 'price', 'gstPercentage', 'buyingPrice', and 'unit' are fields in the item details
        return {
          'price': (snapshot.docs.first['price'] as num).toDouble(),
          'gstPercentage':
              (snapshot.docs.first['gst_percentage'] as num).toDouble(),
          'buyingPrice':
              (snapshot.docs.first['buying_price'] as num).toDouble(),
          'unit': snapshot.docs.first['unit'],
        };
      }
    } catch (e) {}
    return null; // Return null if item details are not found or an error occurs
  }

  void _fetchItemNames(String query) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('item_name', isGreaterThanOrEqualTo: query)
          .where('item_name', isLessThan: query + 'z')
          .get();
      List<String> itemNames =
          snapshot.docs.map((doc) => doc['item_name'] as String).toList();

      // Also, fetch Tamil item names
      QuerySnapshot tamilSnapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('item_name_tamil', isGreaterThanOrEqualTo: query)
          .where('item_name_tamil', isLessThan: query + 'ழ')
          .get();
      List<String> tamilItemNames = tamilSnapshot.docs
          .map((doc) => doc['item_name_tamil'] as String)
          .toList();

      // Search by product code
      QuerySnapshot codeSnapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('product_code', isEqualTo: query)
          .get();
      List<String> productCodeItemNames =
          codeSnapshot.docs.map((doc) => doc['item_name'] as String).toList();

      // Merge English, Tamil, and product code item names
      setState(() {
        _filteredItemNames = itemNames + tamilItemNames + productCodeItemNames;
      });
    } catch (e) {}
  }

  void _filterItemNames(String query) {
    // Trim the empty spaces at the beginning and end of the query
    query = query.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredItemNames.clear();
      });
      return;
    }
    _fetchItemNames(query);
  }

  void _showAddToCartDialog(String itemName) async {
    double quantity = 1.0; // Default quantity

    // Fetch price, GST percentage, and buying price of the item from Firestore
    ItemPrices itemPrices =
        await _fetchItemPrices(itemName); // Fetch all prices
    double price = itemPrices.price;
    double gstPercentage = await _fetchItemGSTPercentage(itemName);
    double buyingPrice =
        await _fetchItemBuyingPrice(itemName); // Fetch buying price
    String unit = await _fetchItemUnit(itemName);

    // Define options for the dropdown menu
    List<String> priceOptions = [
      'Regular Price',
      'Selling Price I',
      'Selling Price II'
    ];

    // Default selected option
    String selectedPriceOption = priceOptions[0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add to Cart'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Select price type:'),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedPriceOption,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedPriceOption = newValue;
                          // Update the price based on the selected option
                          if (newValue == 'Regular Price') {
                            price = itemPrices.price;
                          } else if (newValue == 'Selling Price I') {
                            price = itemPrices.sellingPricei;
                          } else if (newValue == 'Selling Price II') {
                            price = itemPrices.sellingPriceii;
                          }
                        });
                      }
                    },
                    items: priceOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Enter quantity for $itemName:'),
                  const SizedBox(height: 10),
                  TextFormField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Quantity',
                    ),
                    onChanged: (String? value) {
                      if (value != null) {
                        quantity = double.tryParse(value) ?? 1.0;
                      }
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Add item to cart with quantity, price, GST percentage, and buying price
                    setState(() {
                      _cartItems.add(CartItem(
                        itemName: itemName,
                        quantity: quantity,
                        price: price,
                        gstPercentage: gstPercentage,
                        buyingPrice: buyingPrice,
                        unit: unit, // Provide buying price
                      ));
                    });
                    Navigator.of(context).pop(); // Close dialog
                    // Clear search text and close search bar
                    _searchController.clear();
                    setState(() {
                      _isSearching = false;
                    });
                    // Update the list
                    _fetchItemNames('');
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<double> _fetchItemBuyingPrice(String itemName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('item_name', isEqualTo: itemName)
          .get();
      if (snapshot.docs.isNotEmpty) {
        dynamic buyingPrice = snapshot.docs.first['buying_price'];
        if (buyingPrice != null) {
          return (buyingPrice as num).toDouble();
        }
      }
    } catch (e) {}
    return 0.0; // Return a default value if buying price is not available
  }

  Future<ItemPrices> _fetchItemPrices(String itemName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('item_name', isEqualTo: itemName)
          .get();
      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> data =
            snapshot.docs.first.data() as Map<String, dynamic>;
        double price = (data['price'] as double?) ?? 0.0;
        double sellingPricei = (data['sellingPricei'] as double?) ?? price;
        double sellingPriceii = (data['sellingPriceii'] as double?) ?? price;

        return ItemPrices(
          price: price,
          sellingPricei: sellingPricei,
          sellingPriceii: sellingPriceii,
        );
      }
    } catch (e) {}
    // Return default values if prices are not available
    return ItemPrices(price: 0.0, sellingPricei: 0.0, sellingPriceii: 0.0);
  }

  Future<double> _fetchSellingPricei(String itemName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('item_name', isEqualTo: itemName)
          .get();
      if (snapshot.docs.isNotEmpty) {
        dynamic sellingPricei =
            snapshot.docs.first?['sellingPricei']; // Adding null check
        if (sellingPricei != null) {
          return (sellingPricei as num).toDouble();
        }
      }
    } catch (e) {}
    return 0.0; // Return a default value if sellingPricei is not available
  }

  Future<double> _fetchSellingPriceii(String itemName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('item_name', isEqualTo: itemName)
          .get();
      if (snapshot.docs.isNotEmpty) {
        dynamic sellingPriceii =
            snapshot.docs.first?['sellingPriceii']; // Adding null check
        if (sellingPriceii != null) {
          return (sellingPriceii as num).toDouble();
        }
      }
    } catch (e) {}
    return 0.0; // Return a default value if sellingPriceii is not available
  }

  Future<double> _fetchItemGSTPercentage(String itemName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('item_name', isEqualTo: itemName)
          .get();
      if (snapshot.docs.isNotEmpty) {
        dynamic gstPercentage = snapshot.docs.first['gst_percentage'];
        if (gstPercentage != null) {
          return (gstPercentage as num).toDouble();
        }
      }
    } catch (e) {}
    return 0.0; // Return a default value if GST percentage is not available
  }

  Map<String, double> calculateGSTAndSplit(double totalGSTAmount) {
    // Calculate CGST and SGST amounts
    double cgst = totalGSTAmount / 2;
    double sgst = totalGSTAmount / 2;

    return {
      'cgst': cgst,
      'sgst': sgst,
    };
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (var cartItem in _cartItems) {
      total += cartItem.quantity * cartItem.price;
    }
    return total;
  }

  double _calculateGSTAmount() {
    double totalGSTAmount = 0;
    for (var cartItem in _cartItems) {
      double itemTotal = cartItem.quantity * cartItem.price;
      double itemGSTAmount = itemTotal * cartItem.gstPercentage / 100;
      totalGSTAmount += itemGSTAmount;
    }
    return totalGSTAmount;
  }

  double _calculateTotalProfit() {
    double totalProfit = 0;
    for (var cartItem in _cartItems) {
      double totalAmount = cartItem.quantity * cartItem.price;
      double itemGSTAmount = (totalAmount * cartItem.gstPercentage) / 100;
      double totalCost = cartItem.quantity * cartItem.buyingPrice;
      double profit = totalAmount - totalCost - itemGSTAmount;
      totalProfit += profit;
    }
    return totalProfit;
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  void _handleSearch() {
    setState(() {
      _isSearching = true;
      _searchFocusNode.requestFocus();
      _toggleVoiceSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 45, 44, 124),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                onChanged: _filterItemNames,
                decoration: const InputDecoration(
                  hintText: 'Search item name...',
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              )
            : const Text(
                'Billing',
                style: TextStyle(color: Colors.white),
              ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (_isSearching) {
                  _searchFocusNode.requestFocus();
                  _toggleVoiceSearch(); // Start or stop voice recognition based on search state
                } else {
                  _searchController.clear();
                  _filteredItemNames.clear();
                }
              });
            },
            icon: Icon(_isSearching ? Icons.close : Icons.search),
          ),
          if (_isSearching)
            IconButton(
              onPressed: _toggleVoiceSearch, // Toggle voice recognition
              icon: Icon(_isVoiceSearchEnabled ? Icons.mic : Icons.mic_off),
            ),
        ],
      ),
      drawer: const CustomDrawer(
        initialSelectedIndex: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildCartItems(),
          ),
          // Total profit display
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.only(
                  top: 12, bottom: 5, left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Profit:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'INR ${_calculateTotalProfit().toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          // Total amount display
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.only(
                  top: 12, bottom: 5, left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'INR ${_calculateTotalAmount().toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          // GST amount display
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.only(
                  top: 12, bottom: 5, left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'GST Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'INR ${_calculateGSTAmount().toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          // Save bill button
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                onPressed: () {
                  _saveBill(context); // Call method to save bill
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 27, 221, 124),
                  side: const BorderSide(
                    color: Color.fromARGB(255, 87, 110, 105),
                    width: 3,
                  ),
                  shadowColor: Colors.black, // Set the shadow color
                  elevation: 5,
                ),
                child: const Text(
                  'Save Bill',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.all(1.0),
              child: ElevatedButton(
                onPressed: () {
                  _clearCart(); // Call method to clear cart items
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shadowColor: Colors.black, // Set the shadow color
                  elevation: 5, // Change button color to red
                ),
                child: const Text(
                  'Clear Cart', // Button text
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _filteredItemNames.length,
      itemBuilder: (context, index) {
        final itemName = _filteredItemNames[index];
        return Column(
          children: [
            ListTile(
              title: Text(itemName),
              onTap: () {
                // Clear the search list
                setState(() {
                  _filteredItemNames.clear();
                });
                // Hide the search bar
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                // Show dialog to add item to cart
                _showAddToCartDialog(itemName);
              },
            ),
            const Divider(), // Add a divider after each ListTile
          ],
        );
      },
    );
  }

  Future<double> _fetchItemCostPrice(String itemName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('item_name', isEqualTo: itemName)
          .get();
      if (snapshot.docs.isNotEmpty) {
        dynamic buyingPrice = snapshot.docs.first['buying_price'];
        if (buyingPrice != null) {
          return (buyingPrice as num).toDouble();
        }
      }
    } catch (e) {}
    return 0.0; // Return a default value if cost price is not available
  }

  Widget _buildCartItems() {
    return Expanded(
      child: ListView.builder(
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          final cartItem = _cartItems[index];
          final totalAmount = cartItem.quantity * cartItem.price;
          final gstAmount = (totalAmount * cartItem.gstPercentage) / 100;

          return FutureBuilder<double>(
            future: _fetchItemCostPrice(cartItem.itemName),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Replace CircularProgressIndicator with SizedBox.shrink()
                return const SizedBox.shrink();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                final buyingPrice = snapshot.data ?? 0.0;
                final totalCost = cartItem.quantity * buyingPrice;
                final profit = totalAmount - totalCost - gstAmount;
                final profitColor = profit >= 0 ? Colors.green : Colors.red;

                return Column(children: [
                  ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          // Ensures the item name wraps to the next line if it's too long
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<double>(
                                future: _fetchItemMRP(cartItem.itemName),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text('Loading MRP...');
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    return Text(
                                      '${cartItem.itemName} (\nMRP: ₹ ${snapshot.data!.toStringAsFixed(2)})',
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹ ${totalAmount.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'GST: ₹ ${gstAmount.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              'Profit: ₹ ${profit.toStringAsFixed(2)}',
                              style: TextStyle(color: profitColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        const Text('Quantity: '),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (cartItem.quantity > 1) {
                                cartItem.quantity--;
                              }
                            });
                          },
                        ),
                        Text(
                          '${cartItem.quantity.toString()}',
                          style: const TextStyle(
                              color: Colors.deepOrange, fontSize: 16),
                        ),
                        FutureBuilder<String>(
                          future: _fetchItemUnit(cartItem.itemName),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox.shrink();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              return Text(
                                ' ${snapshot.data}',
                                style: const TextStyle(fontSize: 16),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              cartItem.quantity++;
                            });
                          },
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditDialog(cartItem);
                          },
                        ),
                        const SizedBox(
                            width: 1), // Add some space between icons
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _showRemoveConfirmationDialog(cartItem);
                          },
                        ),
                      ],
                    ),
                  )
                ]);
              }
            },
          );
        },
      ),
    );
  }

  Future<String> _fetchItemUnit(String itemName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('item_name', isEqualTo: itemName)
          .get();
      if (snapshot.docs.isNotEmpty) {
        dynamic unit = snapshot.docs.first['unit'];
        if (unit != null) {
          return unit as String;
        }
      }
    } catch (e) {}
    return ''; // Return an empty string if unit is not available
  }

  void _showEditDialog(CartItem cartItem) {
    double price = cartItem.price;
    double quantity = cartItem.quantity;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                initialValue: cartItem.price.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price',
                ),
                onChanged: (value) {
                  price = double.tryParse(value) ?? cartItem.price;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: cartItem.quantity.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                ),
                onChanged: (value) {
                  quantity = double.tryParse(value) ?? cartItem.quantity;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  cartItem.price = price;
                  cartItem.quantity = quantity;
                });
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<double> _fetchItemMRP(String itemName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('item_name', isEqualTo: itemName)
          .get();
      if (snapshot.docs.isNotEmpty) {
        dynamic mrp = snapshot.docs.first['mrp'];
        if (mrp != null) {
          return (mrp as num).toDouble();
        }
      }
    } catch (e) {}
    return 0.0; // Return a default value if MRP is not available
  }

  void _showRemoveConfirmationDialog(CartItem cartItem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: Text(
              'Are you sure you want to remove ${cartItem.itemName} from the cart?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _cartItems.remove(cartItem);
                });
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCustomPriceDialog(CartItem cartItem) {
    double price = cartItem.price;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Enter new price for ${cartItem.itemName}:'),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: cartItem.price.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Price',
                ),
                onChanged: (value) {
                  price = double.tryParse(value) ?? 0.0;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  cartItem.price = price;
                });
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditQuantityDialog(CartItem cartItem) {
    double quantity = cartItem.quantity;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Enter new quantity for ${cartItem.itemName}:'),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: cartItem.quantity.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Quantity',
                ),
                onChanged: (value) {
                  quantity = double.tryParse(value) ?? 1.0;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  cartItem.quantity = quantity;
                });
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _saveBill(BuildContext context) async {
    // Check if the cart is empty
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add items to cart')),
      );
      return;
    }

    try {
      // Calculate total amount, total GST amount, and total profit
      double totalAmount = _calculateTotalAmount();
      double totalGSTAmount = _calculateGSTAmount();
      Map<String, double> gstSplit = calculateGSTAndSplit(totalGSTAmount);
      double totalCGST = gstSplit['cgst'] ?? 0;
      double totalSGST = gstSplit['sgst'] ?? 0;
      double totalProfit = _calculateTotalProfit(); // Calculate total profit

      // Increment the bill number for the next bill
      _billNumber++;

      // Create a new document in the 'bills' collection
      DocumentReference billRef =
          await FirebaseFirestore.instance.collection('bills').add({
        'bill_number': _billNumber, // Save the bill number
        'timestamp': DateTime.now(),
        'total_amount': totalAmount, // Store the total amount
        'total_gst_amount': totalGSTAmount,
        'total_cgst_amount': totalCGST,
        'total_sgst_amount': totalSGST,
        'total_profit': totalProfit, // Store the total profit
        'items': _cartItems.map((item) {
          double totalItemAmount = item.quantity * item.price;
          double itemGSTAmount = (totalItemAmount * item.gstPercentage) / 100;
          return {
            'item_name': item.itemName,
            'quantity': item.quantity,
            'price': item.price,
            'unit': item.unit, // Include unit
            'total_amount': totalItemAmount,
            'gst_amount': itemGSTAmount,
          };
        }).toList(),
      });

      await _generatePdf(context, _billNumber);
    } catch (e) {
      // Handle errors
    }
  }

  Future<String?> _showNameInputDialog(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Customer Name'),
          content: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Customer Name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(nameController.text.isNotEmpty
                    ? nameController.text
                    : null);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showPhoneInputDialog(BuildContext context) async {
    TextEditingController phoneController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Phone Number'),
          content: TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Phone Number'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(phoneController.text.isNotEmpty
                    ? phoneController.text
                    : null);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generatePdf(BuildContext context, int billNumber) async {
    // Fetch shop details from local storage
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String shopName = prefs.getString('shop_name') ?? 'enter Shop name';
    String gstNumber = prefs.getString('gst_number') ?? 'enter gstnumber';
    String shopAddress =
        prefs.getString('shop_address') ?? 'enter shop address';

    // Get current date and time
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('dd-MM-yyyy hh:mm a').format(now);

    // Load Tamil font file
    final fontData =
        await rootBundle.load("asset/fonts/custom_Anand_MuktaMalar.ttf");
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());

    // Create a PDF document
    final pdf = pw.Document();

    // Prompt user for customer details
    String? customerName = await _showNameInputDialog(context);
    String? phoneNumber = await _showPhoneInputDialog(context);

    // If there are items in the cart
    if (_cartItems.isNotEmpty) {
      // Calculate the number of pages needed based on the number of items
      int itemsPerPage = 16;
      int totalPages = (_cartItems.length / itemsPerPage).ceil();

      // Calculate total and GST amounts
      double totalAmount = _calculateTotalAmount();
      double totalGSTAmount = _calculateGSTAmount();
      double cgstAmount =
          totalGSTAmount / 2; // Split GST equally for CGST and SGST
      double sgstAmount = totalGSTAmount / 2;

      // Generate pages dynamically
      for (int page = 0; page < totalPages; page++) {
        // Create a list to hold item data for this page
        List<List<dynamic>> itemsData = List.generate(
          itemsPerPage,
          (index) {
            int itemIndex = page * itemsPerPage + index;
            if (itemIndex < _cartItems.length) {
              double quantity = _cartItems[itemIndex].quantity;
              String unit = _cartItems[itemIndex].unit;

              // Convert quantity to grams if unit is 'kg' and quantity is less than 1
              if (unit == 'kg' && quantity < 1) {
                quantity *= 1000; // Convert to grams
                unit = 'g'; // Change unit to grams
              }

              // Concatenate quantity and unit
              String quantityWithUnit = '$quantity $unit';

              return [
                index + 1,
                pw.Text(
                  _cartItems[itemIndex].itemName.toPrintPdf, // Tamil text here
                  style: pw.TextStyle(font: ttf, fontSize: 14),
                ),
                quantityWithUnit, // Quantity with unit
                '${_cartItems[itemIndex].quantity * _cartItems[itemIndex].price} INR', // Add 'INR' here
              ];
            } else {
              // Return empty cells if no more items
              return List.filled(4, '');
            }
          },
        );

        // Add content to the PDF document
        pdf.addPage(
          pw.MultiPage(
            pageFormat: pw.PdfPageFormat.a4,
            build: (pw.Context context) {
              return <pw.Widget>[
                // Table for shop details
                pw.TableHelper.fromTextArray(
                  border: const pw.TableBorder(
                    top: pw.BorderSide(width: 1.0),
                    left: pw.BorderSide(width: 1.0),
                    right: pw.BorderSide(width: 1.0),
                  ),
                  cellAlignment: pw.Alignment.center,
                  data: <List<dynamic>>[
                    [
                      pw.Text(
                        shopName,
                        style: pw.TextStyle(
                            font: ttf,
                            fontSize: 16,
                            fontWeight: pw.FontWeight
                                .bold), // Adjusted font size and added fontWeight
                      ),
                    ],
                    [shopAddress], // Only the shop name
                  ],
                ),
                // New table for additional shop details
                pw.TableHelper.fromTextArray(
                  border: const pw.TableBorder(
                    left: pw.BorderSide(width: 1.0),
                    right: pw.BorderSide(width: 1.0),
                    bottom: pw.BorderSide(width: 1.0),
                  ),
                  cellAlignment: pw.Alignment.center,
                  data: <List<dynamic>>[
                    ['Phone No:', phoneNumber, 'GSTIN:', gstNumber],
                  ],
                ),
                // New table for customer details
                pw.TableHelper.fromTextArray(
                  border: const pw.TableBorder(
                    top: pw.BorderSide(width: 1.0),
                    left: pw.BorderSide(width: 1.0),
                    right: pw.BorderSide(width: 1.0),
                  ),
                  cellAlignment: pw.Alignment.center,
                  data: <List<dynamic>>[
                    [
                      'Customer Name:',
                      'Customer Phone No:',
                      'Bill No:',
                      'Date:'
                    ],
                    [
                      customerName ?? 'N/A',
                      phoneNumber ?? 'N/A',
                      billNumber.toString(), // Use the provided bill number
                      DateFormat('dd-MM-yyyy').format(DateTime.now())
                    ],
                  ],
                ),
                // Table of items
                pw.TableHelper.fromTextArray(
                  border: const pw.TableBorder(
                    top: pw.BorderSide(width: 1.0),
                    left: pw.BorderSide(width: 1.0),
                    right: pw.BorderSide(width: 1.0),
                    bottom: pw.BorderSide(width: 1.0),
                    verticalInside: pw.BorderSide(width: 1.0),
                  ),
                  cellAlignment: pw.Alignment.center,
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  headerHeight: 20,
                  cellHeight: 20,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                  },
                  headers: <String>[
                    'Sno',
                    'Item Name',
                    'Quantity',
                    'Amount (INR)', // Added 'INR' here
                  ],
                  data: itemsData,
                ),
                // Container for total GST amount and total amount
                // Container for total GST amount and total amount
                if (page == totalPages - 1)
                  pw.Container(
                    child: pw.TableHelper.fromTextArray(
                      border: const pw.TableBorder(
                        top: pw.BorderSide(width: 1.0),
                        left: pw.BorderSide(width: 1.0),
                        right: pw.BorderSide(width: 1.0),
                        bottom: pw.BorderSide(width: 1.0),
                        horizontalInside: pw.BorderSide(width: 1.0),
                      ),
                      cellAlignment: pw.Alignment.center,
                      cellHeight: 25,
                      data: <List<dynamic>>[
                        [
                          pw.Text(
                            'CGST Amount',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(), // Placeholder for CGST
                          pw.Text(
                            '${cgstAmount.toStringAsFixed(2)} INR',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'SGST Amount',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(), // Placeholder for SGST
                          pw.Text(
                            '${sgstAmount.toStringAsFixed(2)} INR',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                        [
                          pw.Center(
                            // Centered Total GST Amount
                            child: pw.Text(
                              'Total GST Amount',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.SizedBox(),
                          pw.Center(
                            // Centered Total GST Amount value
                            child: pw.Text(
                              '${totalGSTAmount.toStringAsFixed(2)} INR',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                        [
                          pw.Center(
                            // Centered Total Amount
                            child: pw.Text(
                              'Total Amount',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.SizedBox(),
                          pw.Center(
                            // Centered Total Amount value
                            child: pw.Text(
                              '${totalAmount.toStringAsFixed(2)} INR',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ];
            },
          ),
        );
      }
    }

    // Save the PDF document to a file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/bill.pdf');
    await file.writeAsBytes(await pdf.save());

    // Print the PDF document
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}

class ItemPrices {
  final double price;
  final double sellingPricei;
  final double sellingPriceii;

  ItemPrices(
      {required this.price,
      required this.sellingPricei,
      required this.sellingPriceii});
}
