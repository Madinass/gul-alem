

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'register.dart';
import 'bas_bet_screen.dart';
import 'catalog_screen.dart'; // 1. ОСЫ ЖЕРДІ ҚОС
import 'main_wrapper.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(), // Сенің сол "приветствие" бетің
    );
  }
}

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Gul Alem',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 230, 0, 100)),
//       ),
//       home: const HomeScreen(),
//       routes: {
//         '/login': (context) => const LoginScreen(),
//         '/register': (context) => const RegisterApp(),
//         '/basbet': (context) => const BasBetScreen(),
//         '/catalog': (context) => const CatalogScreen(), // 2. ОСЫ ЖЕРДІ ҚОС
//       },
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

