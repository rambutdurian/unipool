import 'package:flutter/material.dart';
import 'bottom_nav.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("This is The", style: TextStyle(fontSize: 16)),
            Text("Chats Page", style: TextStyle(fontSize: 28)),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}
