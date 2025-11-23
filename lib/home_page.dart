import 'package:flutter/material.dart';
import 'bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("This is The", style: TextStyle(fontSize: 16)),
            Text("Home Page", style: TextStyle(fontSize: 28)),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}
