import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopDetailsPage extends StatefulWidget {
  const ShopDetailsPage({super.key});

  @override
  _ShopDetailsPageState createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  late TextEditingController _shopNameController;
  late TextEditingController _shopAddressController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _gstNumberController;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController();
    _shopAddressController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _gstNumberController = TextEditingController();

    // Load shop details from local storage if available
    loadShopDetails();
  }

  void loadShopDetails() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _shopNameController.text = prefs.getString('shop_name') ?? '';
        _shopAddressController.text = prefs.getString('shop_address') ?? '';
        _phoneNumberController.text = prefs.getString('phone_number') ?? '';
        _gstNumberController.text = prefs.getString('gst_number') ?? '';
      });
    } catch (e) {}
  }

  void saveShopDetailsLocally() async {
    if (_phoneNumberController.text.length != 10) {
      // Show an error message if phone number is not exactly 10 digits
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number must be 10 digits long'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // Exit the method without saving
    }

    if (_gstNumberController.text.length != 15) {
      // Show an error message if GST number is not exactly 15 characters
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GST number must be 15 characters long'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // Exit the method without saving
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('shop_name', _shopNameController.text);
    prefs.setString('shop_address', _shopAddressController.text);
    prefs.setString('phone_number', _phoneNumberController.text);
    prefs.setString('gst_number', _gstNumberController.text);

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shop details saved locally!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _shopNameController,
              decoration: const InputDecoration(labelText: 'Shop Name'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _shopAddressController,
              decoration: const InputDecoration(labelText: 'Shop Address'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _gstNumberController,
              decoration: const InputDecoration(labelText: 'GST Number'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                saveShopDetailsLocally(); // Save shop details locally
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _phoneNumberController.dispose();
    _gstNumberController.dispose();
    super.dispose();
  }
}
