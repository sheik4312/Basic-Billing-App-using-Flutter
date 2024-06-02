import 'package:flutter/material.dart';
import 'bill.dart'; // Update this import statement to point to the correct file

class CartItemsProvider extends StatefulWidget {
  final Widget child;

  const CartItemsProvider({super.key, required this.child});

  static _CartItemsProviderState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_CartItemsProvider>()
        ?.data;
  }

  @override
  _CartItemsProviderState createState() => _CartItemsProviderState();
}

class _CartItemsProviderState extends State<CartItemsProvider> {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  void addToCart(CartItem cartItem) {
    setState(() {
      _cartItems.add(cartItem);
    });
  }

  void removeFromCart(CartItem cartItem) {
    setState(() {
      _cartItems.remove(cartItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _CartItemsProvider(
      data: this,
      child: widget.child,
    );
  }
}

class _CartItemsProvider extends InheritedWidget {
  final _CartItemsProviderState data;

  const _CartItemsProvider({required this.data, required super.child});

  @override
  bool updateShouldNotify(_CartItemsProvider oldWidget) {
    return true;
  }
}
