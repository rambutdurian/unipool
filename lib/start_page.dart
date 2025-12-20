import 'package:flutter/material.dart';
import 'login_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Start()));
  }
}

class Start extends StatelessWidget {
  const Start({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      height: 844,
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(
            left: 131,
            top: 344,
            child: SizedBox(
              width: 108,
              child: Text(
                'WELCOME TO',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ),

          Positioned(
            left: 136,
            top: 367,
            child: Text(
              'UNIPOOL',
              style: TextStyle(color: Colors.black, fontSize: 28),
            ),
          ),

          Positioned(
            left: 138,
            top: 403,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: Container(
                width: 120,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  "START",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
