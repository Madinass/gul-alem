
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'register.dart';
import 'bas_bet_screen.dart';
import 'catalog_screen.dart'; 
import 'main_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final hasSession = token != null && token.isNotEmpty;
  runApp(MyApp(initialHasSession: hasSession));
}

class MyApp extends StatelessWidget {
  final bool initialHasSession;

  const MyApp({super.key, required this.initialHasSession});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: initialHasSession ? const MainWrapper() : const HomeScreen(),
    );
  }
}

