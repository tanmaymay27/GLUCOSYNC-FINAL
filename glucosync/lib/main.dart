import 'package:flutter/material.dart';
// import 'package:glucosync/pages/login.dart';
import 'package:glucosync/pages/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: 'https://bsrpkcxkcsxtofgknujk.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzcnBrY3hrY3N4dG9mZ2tudWprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE0MzI3MTYsImV4cCI6MjA1NzAwODcxNn0.9cXdWpjlf0Z2eNAqXls4vl3lJZF_pnNvxNUbPyqBImc');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GlucoSync',
      home: Splashscreen(),
    );
  }
}
