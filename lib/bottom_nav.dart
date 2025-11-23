import 'package:flutter/material.dart';
import 'home_page.dart';
import 'orders_page.dart';
import 'chats_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,

      onTap: (index) {
        Widget page;

        switch (index) {
          case 0:
            page = const HomePage();
            break;
          case 1:
            page = const OrdersPage();
            break;
          case 2:
            page = const ChatsPage();
            break;
          case 3:
            page = const HistoryPage();
            break;
          case 4:
            page = const SettingsPage();
            break;
          default:
            page = const HomePage();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },

      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Orders"),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      ],
    );
  }
}
