import 'package:flutter/material.dart';
import 'bottom_nav.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("This is The", style: TextStyle(fontSize: 16)),
            Text("Orders Page", style: TextStyle(fontSize: 28)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}
