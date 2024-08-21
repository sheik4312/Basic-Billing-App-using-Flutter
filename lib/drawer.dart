import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for sign out
import 'package:inventory/add_item.dart';
import 'package:inventory/billpage.dart';
import 'package:inventory/calculations/bnavigation.dart';
import 'package:inventory/display.dart';
import 'package:inventory/setting/settingpage.dart';
import 'package:inventory/signin&up/login.dart'; // Import the login screen for navigation after logout
import 'bill.dart';

class CustomDrawer extends StatefulWidget {
  final int initialSelectedIndex;

  const CustomDrawer({super.key, required this.initialSelectedIndex});
  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out from Firebase

      // Navigate to the login screen after signing out
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    } catch (e) {
      // Handle errors if sign out fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 45, 44, 124),
            ),
            child: Text(
              'Billing',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add an item'),
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Additem()),
              );
            },
            selected: _selectedIndex == 0,
            selectedTileColor: Colors.blue.withOpacity(0.2),
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Item list'),
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Display()),
              );
            },
            selected: _selectedIndex == 1,
            selectedTileColor: Colors.blue.withOpacity(0.2),
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Generate Bill'),
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BillingScreen()),
              );
            },
            selected: _selectedIndex == 2,
            selectedTileColor: Colors.blue.withOpacity(0.2),
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Total Bills'),
            onTap: () {
              setState(() {
                _selectedIndex = 3;
              });
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BillsPage()),
              );
            },
            selected: _selectedIndex == 3,
            selectedTileColor: Colors.blue.withOpacity(0.2),
          ),
          ListTile(
            leading: const Icon(IconData(0xe57f, fontFamily: 'MaterialIcons')),
            title: const Text('Setting'),
            onTap: () {
              setState(() {
                _selectedIndex = 4;
              });
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
            selected: _selectedIndex == 4,
            selectedTileColor: Colors.blue.withOpacity(0.2),
          ),
          ListTile(
            leading: const Icon(IconData(0xe57f, fontFamily: 'MaterialIcons')),
            title: const Text('Payouts'),
            onTap: () {
              setState(() {
                _selectedIndex = 5;
              });
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const BottomNavBarApp()),
              );
            },
            selected: _selectedIndex == 5,
            selectedTileColor: Colors.blue.withOpacity(0.2),
          ),
          const Divider(), // Adds a divider before the logout button
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: _logout,
            selected: false,
          ),
        ],
      ),
    );
  }
}
