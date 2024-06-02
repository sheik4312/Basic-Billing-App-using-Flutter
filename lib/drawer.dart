import 'package:flutter/material.dart';
import 'package:inventory/add_item.dart';
import 'package:inventory/billpage.dart';
import 'package:inventory/display.dart';
import 'package:inventory/setting/settingpage.dart';
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
        ],
      ),
    );
  }
}
