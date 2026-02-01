import 'package:flutter/material.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Фон - екі түске бөлінген
          Row(
            children: [
              Expanded(child: Container(color: Colors.white)), // Сол жақ - Ақ
              // Оң жақ - Түс F4CDCD-ға өзгертілді
              Expanded(child: Container(color: const Color(0xFFF4CDCD))), 
            ],
          ),

          // Орталық бөлік (Мәтін және Сурет)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 'Gul alem' мәтінін оңға жылжыту
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 40), // Оңға жылжыту ені
                    const Text(
                      "Gul alem",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Гүл суреті
                Image.asset(
                  "assets/icon_flower.png",
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          // 'Ary qarai' батырмасы
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: SizedBox(
                width: 260,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Батырманың түсі F4CDCD болып қалды
                    backgroundColor: const Color.fromARGB(255, 96, 91, 91), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Ары қарай >",
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255), 
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
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
// import 'package:flutter/material.dart';
// import 'register.dart';

// class HomeScreen extends StatelessWidget{
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//   return Scaffold(
//     body: Stack(
//       children: [
//         Row(
//           children: [
//             Expanded(child: Container(color: Colors.white)),
//             Expanded(child: Container(color: Colors.pink[100])),
//           ],
//           ),
        
//         Center(
//           child:Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "Gul alem",
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.w400,
//                   color: Colors.black,
//                 )
//               ),
//               const SizedBox(height: 40),
//               Image.asset(
//                 "assets/icon_flower.png",
//                 width: 120,
//                 height: 120,
//               ),
//             ],
//           ),
//           ),

//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Padding(
//               padding: const EdgeInsets.only(bottom: 40),
//               child: SizedBox(
//                 width: 160,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.black,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const RegisterScreen(),
//                         ),
//                         );
//                   },
//                   child: const Text(
//                     "Ary qarai >",
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 )
//               ),
//               ),
//               ),
//       ],
//     ),
//   );
//   }
// }
