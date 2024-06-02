import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory/language.dart';

class EditItemScreen extends StatefulWidget {
  final String documentId; // Document ID of the item

  const EditItemScreen(
      {super.key, required this.documentId, required void Function() onBack});

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late TextEditingController _itemNameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _mrpController;
  late TextEditingController _buyingPriceController;
  late TextEditingController _gstPercentageController;
  late TextEditingController _productCodeController;
  late TextEditingController
      _sellingPrice2Controller; // New controller for sellingPrice2
  late TextEditingController
      _sellingPrice3Controller; // New controller for sellingPrice3

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController();
    _unitController = TextEditingController();
    _mrpController = TextEditingController();
    _buyingPriceController = TextEditingController();
    _gstPercentageController = TextEditingController();
    _productCodeController = TextEditingController();
    _sellingPrice2Controller =
        TextEditingController(); // Initialize sellingPrice2 controller
    _sellingPrice3Controller =
        TextEditingController(); // Initialize sellingPrice3 controller

    fetchItemDetails();
  }

  void fetchItemDetails() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .doc(widget.documentId)
          .get();
      if (snapshot.exists) {
        setState(() {
          _itemNameController.text = snapshot['item_name'];
          _priceController.text = snapshot['price'].toString();
          _quantityController.text = snapshot['quantity'].toString();
          _unitController.text = snapshot['unit'];
          _mrpController.text = snapshot['mrp'].toString();
          _buyingPriceController.text = snapshot['buying_price'].toString();
          _gstPercentageController.text = snapshot['gst_percentage'].toString();
          _productCodeController.text = snapshot['product_code'] ?? '';
          _sellingPrice2Controller.text = snapshot['sellingPricei'].toString();
          _sellingPrice3Controller.text = snapshot['sellingPriceii'].toString();
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  bool isValidNumber(String value) {
    final numberRegExp = RegExp(r'^-?\d*\.?\d+$');
    return numberRegExp.hasMatch(value);
  }

  bool isValidGstPercentage(String value) {
    final gstValues = ['0', '5', '12', '18', '28'];
    return gstValues.contains(value);
  }

  void updateItem() async {
    if (!isValidNumber(_priceController.text) ||
        !isValidNumber(_quantityController.text) ||
        !isValidNumber(_mrpController.text) ||
        !isValidNumber(_buyingPriceController.text) ||
        !isValidNumber(_gstPercentageController.text) ||
        !isValidGstPercentage(_gstPercentageController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid numeric value or GST percentage')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('inventory')
          .doc(widget.documentId)
          .update({
        'item_name': _itemNameController.text,
        'price': double.parse(_priceController.text),
        'quantity': double.parse(_quantityController.text),
        'unit': _unitController.text,
        'mrp': double.parse(_mrpController.text),
        'buying_price': double.parse(_buyingPriceController.text),
        'gst_percentage': int.parse(_gstPercentageController.text),
        'product_code': _productCodeController.text,
        'sellingPrice2': _sellingPrice2Controller.text, // Update sellingPrice2
        'sellingPrice3': _sellingPrice3Controller.text, // Update sellingPrice3
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully')),
      );
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 45, 44, 124),
        title: Text(
          AppLocalizations.translate(context, 'edit_item'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _itemNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.translate(context, 'item_name'),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _productCodeController,
                decoration: InputDecoration(
                    labelText: AppLocalizations.translate(
                  context,
                  'product_code',
                )),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.translate(context, 'selling_price'),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller:
                    _sellingPrice2Controller, // Selling Price 2 text field
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.translate(context, 'selling_price2'),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller:
                    _sellingPrice3Controller, // Selling Price 3 text field
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.translate(context, 'selling_price3'),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.translate(context, 'quantity'),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _mrpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.translate(context, 'mrp'),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _buyingPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.translate(context, 'buying_price'),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _unitController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.translate(context, 'unit'),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _gstPercentageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.translate(context, 'gst_percentage'),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: updateItem,
                child: Text(
                  AppLocalizations.translate(context, 'update_item'),
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 81, 79, 202),
                  shadowColor: Colors.black, // Set the shadow color
                  elevation: 6, // Set the background color to blue
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _mrpController.dispose();
    _buyingPriceController.dispose();
    _gstPercentageController.dispose();
    _productCodeController.dispose();
    _sellingPrice2Controller.dispose(); // Dispose sellingPrice2 controller
    _sellingPrice3Controller.dispose(); // Dispose sellingPrice3 controller
    super.dispose();
  }
}
