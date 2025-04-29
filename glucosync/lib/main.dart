import 'package:flutter/material.dart';
// import 'package:glucosync/pages/login.dart';
import 'package:glucosync/pages/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: 'Enter your Supabase Url',
      anonKey:
          'Enter your Supabase Anon Key');
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
