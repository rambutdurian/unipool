import 'package:flutter/material.dart';
import 'home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Login()));
  }
}

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      height: 844,
      decoration: BoxDecoration(color: Colors.white),
      child: Stack(
        children: [
          // “WHO ARE”
          Positioned(
            left: 131,
            top: 344,
            child: SizedBox(
              width: 108,
              child: Text(
                'WHO ARE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),

          // “YOU”
          Positioned(
            left: 168,
            top: 367,
            child: Text(
              'YOU',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontFamily: 'Roboto',
              ),
            ),
          ),

          // OK BUTTON
          Positioned(
            left: 138,
            top: 403,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
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
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
