import 'package:flutter/material.dart';
import 'package:inventory/calculations/amountpage.dart';
import 'package:inventory/calculations/dashboard.dart';
import 'package:inventory/calculations/newpayer.dart';

class BottomNavBarApp extends StatefulWidget {
  const BottomNavBarApp({super.key});

  @override
  _BottomNavBarAppState createState() => _BottomNavBarAppState();
}

class _BottomNavBarAppState extends State<BottomNavBarApp> {
  int _selectedIndex = 0;

  // List of pages corresponding to each BottomNavigationBar item
  final List<Widget> _pages = [
    DashboardPage(),
    BorrowForm(),
    AmountPage(),
  ];

  // Function to handle tap on a BottomNavigationBar item
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Add Payer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Amount',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
