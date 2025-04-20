import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glucosync/auth/auth_state.dart';
// import 'package:glucosync/pages/login.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthStateScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15B392), // Greenish gradient background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Inverted drop icon
            Container(
              height: 150,
              child: Image.asset(
                'assets/Logo.png', // Replace with your image asset path
              ),
            ),
            const SizedBox(height: 10),
            // GlucoSync Text
            const Text(
              'GlucoSync',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle Text
            const Text(
              'Smart Glucose,\nSmarter You',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
