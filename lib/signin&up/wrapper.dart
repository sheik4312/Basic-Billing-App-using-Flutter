import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../add_item.dart';
import 'login.dart';

// ignore: camel_case_types
class wrapper extends StatefulWidget {
  const wrapper({super.key});

  @override
  State<wrapper> createState() => _wrapperState();
}

// ignore: camel_case_types
class _wrapperState extends State<wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const Additem();
          } else {
            return const Login();
          }
        },
      ),
    );
  }
}
