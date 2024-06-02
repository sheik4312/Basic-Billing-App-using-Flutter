import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:inventory/language.dart';
import 'drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class Additem extends StatefulWidget {
  const Additem({super.key});

  @override
  _AdditemState createState() => _AdditemState();
}

class _AdditemState extends State<Additem> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _buyingPriceController = TextEditingController();
  final TextEditingController _categoryEditingController =
      TextEditingController(); // Controller for manual category entry
  String _selectedCategory = ''; // Selected category
  int _selectedGST = 18;
  String _selectedUnit = 'kg';
  final List<String> _unitOptions = ['kg', 'g', 'l', 'ml', 'packet', 'Dozen'];
  final List<String> _languages = ['English', 'Tamil'];
  String _selectedLanguage = 'English';
  List<String> _categoryOptions = []; // List to store categories
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _sellingPrice2Controller =
      TextEditingController();
  final TextEditingController _sellingPrice3Controller =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load saved data and categories
    _loadData();
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _itemNameController.text = prefs.getString('itemName') ?? '';
      _priceController.text = prefs.getString('price') ?? '';
      _quantityController.text = prefs.getString('quantity') ?? '';
      _mrpController.text = prefs.getString('mrp') ?? '';
      _buyingPriceController.text = prefs.getString('buyingPrice') ?? '';
      _sellingPrice2Controller.text = prefs.getString('sellingPricei') ?? '';
      _sellingPrice3Controller.text = prefs.getString('sellingPriceii') ?? '';
      _selectedUnit = prefs.getString('selectedUnit') ?? 'kg';
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
      _selectedGST = prefs.getInt('selectedGST') ?? 18;
      _productCodeController.text = prefs.getString('product_code') ?? '';
      _categoryOptions = prefs.getStringList('categories') ?? [];
      if (_categoryOptions.isNotEmpty) {
        _selectedCategory =
            _categoryOptions[0]; // Set the initial value to the first category
      }
    });
  }

  void _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('itemName', _itemNameController.text);
    prefs.setString('price', _priceController.text);
    prefs.setString('quantity', _quantityController.text);
    prefs.setString('mrp', _mrpController.text);
    prefs.setString('buyingPrice', _buyingPriceController.text);
    prefs.setString('selectedUnit', _selectedUnit);
    prefs.setString('selectedLanguage', _selectedLanguage);
    prefs.setInt('selectedGST', _selectedGST);
    prefs.setStringList('categories', _categoryOptions);
    prefs.setString('sellingPrice2',
        _sellingPrice2Controller.text); // Saving selling price 2
    prefs.setString('sellingPrice3', _sellingPrice3Controller.text);
    prefs.setString('product_code', _productCodeController.text);
  }

  void _addItem() async {
    // Check if all fields are filled
    if (_itemNameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _mrpController.text.isEmpty ||
        _buyingPriceController.text.isEmpty ||
        _selectedCategory.isEmpty ||
        _productCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
        ),
      );
      return;
    }

    // Save data before adding item
    _saveData();

    try {
      if (!_categoryOptions.contains(_categoryEditingController.text)) {
        setState(() {
          _categoryOptions.add(_categoryEditingController.text);
        });
      }
      _saveData(); // Save categories
      await _firestore.collection('inventory').add({
        'item_name': _itemNameController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'quantity': double.tryParse(_quantityController.text) ?? 0.0,
        'mrp': double.tryParse(_mrpController.text) ?? 0.0,
        'buying_price': double.tryParse(_buyingPriceController.text) ?? 0.0,
        'unit': _selectedUnit,
        'gst_percentage': _selectedGST,
        'category': _selectedCategory,
        'product_code': _productCodeController.text, // Add product code
        'sellingPricei': double.tryParse(_sellingPrice2Controller.text) ??
            0.0, // Save sellingPrice2
        'sellingPriceii': double.tryParse(_sellingPrice3Controller.text) ??
            0.0, // Save sellingPrice3
      });
      _clearData(); // Clear data after adding item
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.translate(context, 'item_added')),
        ),
      );
    } catch (e) {}
  }

  void _clearData() {
    setState(() {
      _itemNameController.clear();
      _priceController.clear();
      _quantityController.clear();
      _mrpController.clear();
      _buyingPriceController.clear();
      _productCodeController.clear();
      _categoryEditingController.clear();
      _selectedUnit = 'kg';
      _selectedLanguage = 'English';
      _selectedGST = 0;
      _sellingPrice2Controller.clear();
      _sellingPrice3Controller.clear();
    });
    _saveData(); // Save cleared data
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
      AppLocalizations.setLocale(language == 'English' ? 'en' : 'ta');
    });
  }

  void _addNewCategory() async {
    String newCategory = _categoryEditingController.text.trim();
    if (newCategory.isNotEmpty && !_categoryOptions.contains(newCategory)) {
      setState(() {
        _categoryOptions.add(newCategory);
        _selectedCategory = newCategory;
        _categoryEditingController.clear(); // Clear the text field after adding
      });
      _saveData(); // Save the updated category list

      // Add the new category to a separate collection
      try {
        await _firestore.collection('categories').add({
          'category_name': newCategory,
        });
      } catch (e) {}
    }
  }

  void _importExcelData() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      var sheet = excel.tables.keys.first;
      var table = excel.tables[sheet];
      // Assuming the first row contains headers and data starts from the second row
      for (var row in table!.rows.skip(1)) {
        setState(() {
          _itemNameController.text = row[0]?.value?.toString() ?? '';
          _priceController.text = row[1]?.value?.toString() ?? '';
          _sellingPrice2Controller.text = row[2]?.value?.toString() ?? '';
          _sellingPrice3Controller.text = row[3]?.value?.toString() ?? '';
          _buyingPriceController.text = row[4]?.value?.toString() ?? '';
          _quantityController.text = row[5]?.value?.toString() ?? '';
          _mrpController.text = row[6]?.value?.toString() ?? '';
          _selectedUnit = row[7]?.value?.toString() ?? '';
          _selectedCategory = row[8]?.value?.toString() ?? '';
          _selectedGST = int.tryParse(row[9]?.value?.toString() ?? '') ?? 18;
          _productCodeController.text =
              row[10]?.value?.toString() ?? ''; // Added product code
        });

        // Check if an item with the same name already exists
        var existingItem = await _getItemByName(_itemNameController.text);

        if (existingItem != null) {
          // Update existing item fields
          setState(() {
            existingItem['price'] =
                double.tryParse(_priceController.text) ?? 0.0;
            existingItem['selling_price2'] =
                double.tryParse(_sellingPrice2Controller.text) ?? 0.0;
            existingItem['selling_price3'] =
                double.tryParse(_sellingPrice3Controller.text) ?? 0.0;
            existingItem['buying_price'] =
                double.tryParse(_buyingPriceController.text) ?? 0.0;
            existingItem['quantity'] =
                double.tryParse(_quantityController.text) ?? 0.0;
            existingItem['mrp'] = double.tryParse(_mrpController.text) ?? 0.0;
            existingItem['unit'] = _selectedUnit;
            existingItem['gst_percentage'] = _selectedGST;
            existingItem['category'] = _selectedCategory;
            existingItem['product_code'] =
                _productCodeController.text; // Added product code
          });

          // Save the updated item to Firestore
          _updateItem(existingItem);
        } else {
          // Add a new item
          _addItem();
        }

        // Add the category to the categories collection if it doesn't already exist
        await _addCategoryIfNotExists(_selectedCategory);
      }
    } else {}
  }

  // Helper function to add a category to the categories collection if it doesn't already exist
  Future<void> _addCategoryIfNotExists(String category) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('category_name', isEqualTo: category)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Add the category to the categories collection
        await FirebaseFirestore.instance.collection('categories').add({
          'category_name': category,
        });
      }
    } catch (e) {}
  }

  // Helper function to get an item by its name from Firestore
  Future<Map<String, dynamic>?> _getItemByName(String itemName) async {
    // Fetch the item from Firestore
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .where('item_name', isEqualTo: itemName)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {}
    return null; // Return null if the item doesn't exist
  }

  // Helper function to update an existing item in Firestore
  void _updateItem(Map<String, dynamic> item) async {
    try {
      await FirebaseFirestore.instance
          .collection('inventory')
          .doc(item['id'])
          .update(item);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return _buildWindowsLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 45, 44, 124),
        title: Text(
          AppLocalizations.translate(context, 'app_title'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      drawer: const CustomDrawer(
        initialSelectedIndex: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildFormContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildWindowsLayout() {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 45, 44, 124),
        title: Text(
          AppLocalizations.translate(context, 'app_title'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      drawer: const CustomDrawer(
        initialSelectedIndex: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildFormContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormContent() {
    return [
      Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 60, 73,
              150), // Set the background color of the DropdownButton
          borderRadius:
              BorderRadius.circular(10), // Optional: to make it rounded
        ),
        padding: EdgeInsets.symmetric(
            horizontal: 10), // Optional: to give some padding
        child: DropdownButton<String>(
          value: _selectedLanguage,
          dropdownColor: Color.fromARGB(
              255, 60, 73, 150), // Set the dropdown menu background color
          onChanged: (String? newValue) {
            if (newValue != null) {
              _changeLanguage(newValue);
            }
          },
          style: TextStyle(color: Colors.white), // Set the text color
          iconEnabledColor: Colors.white, // Set the icon color
          items: _languages.map((String language) {
            return DropdownMenuItem<String>(
              value: language,
              child: Text(language),
            );
          }).toList(),
        ),
      ),
      TextFormField(
        controller: _itemNameController,
        onChanged: (_) => _saveData(),
        decoration: InputDecoration(
          labelText: AppLocalizations.translate(context, 'item_name'),
        ),
      ),
      const SizedBox(height: 16.0),
      TextFormField(
        controller: _productCodeController,
        onChanged: (_) => _saveData(),
        decoration: InputDecoration(
          labelText: AppLocalizations.translate(context, 'product_code'),
        ),
      ),
      const SizedBox(height: 16.0),
      TextFormField(
        controller: _priceController,
        onChanged: (_) => _saveData(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: AppLocalizations.translate(context, 'selling_price'),
        ),
      ),
      const SizedBox(height: 16.0),
      TextFormField(
        controller: _sellingPrice2Controller,
        onChanged: (_) => _saveData(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: AppLocalizations.translate(context, 'selling_price2'),
        ),
      ),
      const SizedBox(height: 16.0),
      TextFormField(
        controller: _sellingPrice3Controller,
        onChanged: (_) => _saveData(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: AppLocalizations.translate(context, 'selling_price3'),
        ),
      ),
      const SizedBox(height: 16.0),
      TextFormField(
        controller: _buyingPriceController,
        onChanged: (_) => _saveData(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: AppLocalizations.translate(context, 'buying_price'),
        ),
      ),
      const SizedBox(height: 16.0),
      Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _quantityController,
              onChanged: (_) => _saveData(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.translate(context, 'quantity'),
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _selectedUnit,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedUnit = newValue!;
                });
                _saveData();
              },
              items: _unitOptions
                  .map((unit) => DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      ))
                  .toList(),
              decoration: InputDecoration(
                labelText: AppLocalizations.translate(context, 'unit'),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16.0),
      TextFormField(
        controller: _mrpController,
        onChanged: (_) => _saveData(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: AppLocalizations.translate(context, 'mrp'),
        ),
      ),
      const SizedBox(height: 16.0),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: _categoryOptions
                  .map((category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              decoration: InputDecoration(
                labelText: AppLocalizations.translate(context, 'category'),
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: TextFormField(
              controller: _categoryEditingController,
              onChanged: (_) => _saveData(),
              decoration: InputDecoration(
                labelText:
                    AppLocalizations.translate(context, 'add_new_category'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewCategory,
          ),
        ],
      ),
      const SizedBox(height: 16.0),
      DropdownButtonFormField<int>(
        value: _selectedGST,
        onChanged: (int? newValue) {
          setState(() {
            _selectedGST = newValue!;
          });
          _saveData();
        },
        items:
            <int>[0, 3, 5, 12, 18, 28].map<DropdownMenuItem<int>>((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text(
                '$value% ${AppLocalizations.translate(context, 'gst_percentage')}'),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: AppLocalizations.translate(context, 'gst_percentage'),
        ),
      ),
      const SizedBox(height: 16.0),
      ElevatedButton(
        onPressed: _addItem,
        child: Text(
          AppLocalizations.translate(context, 'add_item'),
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 81, 79, 202),
          shadowColor: Colors.black, // Set the shadow color
          elevation: 6, // Set the background color to blue
        ),
      ),
      const SizedBox(height: 16.0),
      ElevatedButton(
        onPressed: _importExcelData,
        child: Text(
          AppLocalizations.translate(context, 'import_excel'),
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 81, 79, 202),
          shadowColor: Colors.black, // Set the shadow color
          elevation: 6, // Set the background color to blue
        ),
      ),
    ];
  }
}
