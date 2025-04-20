import 'package:flutter/material.dart';
import 'package:glucosync/pages/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glucosync/pages/login.dart';
import 'package:glucosync/supabase_config.dart';

class AuthStateScreen extends StatelessWidget {
  const AuthStateScreen({super.key});

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final session = supabase.auth.currentSession;

    if (session != null) {
      // Save session in shared preferences
      await prefs.setBool('isLoggedIn', true);
      return true;
    }

    // Clear session if not valid
    await prefs.setBool('isLoggedIn', false);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isUserLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isLoggedIn = snapshot.data ?? false;
        return isLoggedIn ? const Dashboard() : const Login();
      },
    );
  }
}
