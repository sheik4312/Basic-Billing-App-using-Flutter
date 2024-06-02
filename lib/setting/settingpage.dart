import 'package:flutter/material.dart';
import '../drawer.dart';
import 'shopdetails.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 45, 44, 124),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
      drawer: const CustomDrawer(
        initialSelectedIndex: 4,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Language'),
            trailing: const Icon(Icons.language),
            onTap: () {
              // Show language selection dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Select Language'),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: [
                          GestureDetector(
                            child: const Text('English'),
                            onTap: () {
                              // Set language to English
                              // Implement language setting functionality
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            child: const Text('Tamil'),
                            onTap: () {
                              // Set language to Tamil
                              // Implement language setting functionality
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          ListTile(
            title: const Text('Shop Details'),
            trailing: const Icon(Icons.store),
            onTap: () {
              // Navigate to shop details page
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ShopDetailsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
