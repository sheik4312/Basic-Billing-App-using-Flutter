import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inventory/drawer.dart';
import 'package:inventory/signin&up/wrapper.dart';
import 'cartitemprovider.dart'; // Import the CartItemsProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBcgzBe4PsNnUv8tmwWNzZRcQoMYHdmtAQ",
      appId: "1:455047355477:android:f8d470101cef0e2ff048dc",
      messagingSenderId: "455047355477",
      projectId: "inventory-bd189",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a custom trace for MyApp widget

    return MaterialApp(
      title: 'Grocery Billing Software',
      theme: ThemeData.light(),
      home: const CartItemsProvider(
        child: Scaffold(
          body: GroceryBillingApp(),
          drawer: CustomDrawer(
            initialSelectedIndex: 0,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
    // Stop the trace when the widget tree is built
  }
}

class GroceryBillingApp extends StatelessWidget {
  const GroceryBillingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery Billing Software',
      theme: Theme.of(context), // Use the current theme from MaterialApp
      home: const wrapper(), // Corrected the casing for Wrapper
      debugShowCheckedModeBanner: false,
    );
  }
}
