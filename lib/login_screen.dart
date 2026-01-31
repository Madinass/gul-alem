import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'forgot_password_screen.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isObscure = true; // Құпиясөзді көрсету/жасыру үшін
  bool _isLoading = false; // Жүктелу индикаторы үшін

Future<void> _onLoginPressed() async {
  final loginInput = _phoneController.text.trim(); // Бұл жерде енді телефон да, email да болуы мүмкін
  final password = _passwordController.text.trim();

  if (loginInput.isEmpty) {
    _showSnackBar("Логин немесе Email жазыңыз", Colors.redAccent);
    return;
  }
  
  if (password.length < 8) {
    _showSnackBar("Құпиясөз тым қысқа", Colors.redAccent);
    return;
  }

  setState(() => _isLoading = true);

  try {
    final response = await http.post(
      Uri.parse("http://127.0.0.1:3000/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "login": loginInput, // Серверге 'login' деген атпен жібереміз
        "password": password
      }),
    );

    if (response.statusCode == 200) {
      _showSnackBar("Қош келдіңіз!", Colors.green);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar("Логин немесе құпиясөз қате!", Colors.redAccent);
    }
  } catch (e) {
    _showSnackBar("Сервермен байланыс жоқ!", Colors.redAccent);
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showForgotPasswordFlow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🌸 Гүл суреті (Сенің дизайның)
          Positioned(
            top: 0,
            right: -30,
            child: SizedBox(
              width: 250,
              height: 250,
              child: Image.asset(
                'assets/glavflow.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.favorite, size: 250, color: Color(0xFFFFC0CB)),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // 🔑 Кілт суреті
                        SizedBox(
                          width: 140, height: 140,
                          child: Image.asset('assets/key.png', fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.vpn_key, size: 100, color: Color(0xFFE91E63)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text("Кіріп, жақыныңызды қуантыңыз!", 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                        const SizedBox(height: 25),

                        // 📱 Телефон өрісі
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                          decoration: _inputStyle("Телефон нөмірі", prefix: "+7 "),
                        ),
                        const SizedBox(height: 16),

                        // 🔒 Құпиясөз өрісі + "Көз" иконкасы
                        TextField(
                          controller: _passwordController,
                          obscureText: _isObscure,
                          decoration: _inputStyle("Құпиясөз").copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.pink),
                              onPressed: () => setState(() => _isObscure = !_isObscure),
                            ),
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotPasswordFlow(context),
                            child: Text("Құпиясөзді ұмыттыңыз ба?", style: TextStyle(color: Colors.pink.shade400, fontSize: 13)),
                          ),
                        ),

                        const SizedBox(height: 10),
                        // ✅ Кіру батырмасы
                        _isLoading 
                          ? const CircularProgressIndicator(color: Colors.pink)
                          : SizedBox(
                              width: double.infinity, height: 50,
                              child: ElevatedButton.icon(
                                style: _buttonStyle(Colors.pink.shade50, Colors.pink.shade300),
                                onPressed: _onLoginPressed,
                                icon: const Icon(Icons.login, color: Colors.pink),
                                label: const Text("Кіру", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🌸 "Тіркелу" батырмасы
          Positioned(
            bottom: 40, right: 30,
            child: SizedBox(
              width: 180, height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 8,
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterApp())),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text("Тіркелу", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Дизайныңды сақтау үшін стильдерді жеке шығардым
  InputDecoration _inputStyle(String hint, {String? prefix}) {
    return InputDecoration(
      prefixText: prefix,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
      ),
    );
  }

  ButtonStyle _buttonStyle(Color bg, Color border) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border, width: 1.5),
      ),
      elevation: 4,
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'forgot_password_screen.dart';
// import 'register.dart'; // Тіркелу беті осында

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   void _showForgotPasswordFlow(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => const ForgotPasswordScreen(),
//       ),
//     );
//   }

//   String? _validatePhone(String value) {
//     final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
//     if (cleaned.length != 10) {
//       return 'Нөмір 10 цифрдан тұруы керек';
//     }
//     return null;
//   }

//   String? _validatePassword(String value) {
//     final regex = RegExp(r'^[A-Z][A-Za-z0-9]*[0-9]+[A-Za-z0-9]*$');
//     if (!regex.hasMatch(value)) {
//       return 'Құпиясөз бас әріптен басталып, ағылшынша және цифр болуы керек';
//     }
//     return null;
//   }

//   void _onLoginPressed() {
//     final phoneError = _validatePhone(_phoneController.text);
//     final passError = _validatePassword(_passwordController.text);

//     if (phoneError != null || passError != null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(phoneError ?? passError!),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       return;
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Кіру логикасы әлі қосылмаған!")),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           Positioned(
//             top: 0,
//             right: -30,
//             child: SizedBox(
//               width: 250,
//               height: 250,
//               child: Image.asset(
//                 'assets/glavflow.png',
//                 fit: BoxFit.contain,
//                 errorBuilder: (context, error, stackTrace) {
//                   return const Icon(Icons.favorite,
//                       size: 250, color: Color(0xFFFFC0CB));
//                 },
//               ),
//             ),
//           ),
//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 320,
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.95),
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: const [
//                         BoxShadow(
//                           color: Colors.black12,
//                           blurRadius: 10,
//                           offset: Offset(0, 5),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         const SizedBox(height: 10),
//                         Container(
//                           width: 180,
//                           height: 180,
//                           decoration: const BoxDecoration(
//                             color: Colors.transparent,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(10),
//                             child: Image.asset(
//                               'assets/key.png',
//                               fit: BoxFit.contain,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return const Icon(Icons.vpn_key,
//                                     size: 120, color: Color(0xFFE91E63));
//                               },
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         const Text(
//                           "Кіріп, жақыныңызды қуантыңыз!",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.black,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 25),
//                         TextField(
//                           controller: _phoneController,
//                           keyboardType: TextInputType.phone,
//                           inputFormatters: [
//                             FilteringTextInputFormatter.digitsOnly,
//                             LengthLimitingTextInputFormatter(10),
//                           ],
//                           decoration: InputDecoration(
//                             prefixText: "+7 ",
//                             prefixStyle:
//                                 const TextStyle(color: Colors.black, fontSize: 16),
//                             hintText: "Телефон нөмірі",
//                             hintStyle: const TextStyle(color: Colors.black54),
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 14,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide(
//                                   color: Colors.pink.shade300, width: 2),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         TextField(
//                           controller: _passwordController,
//                           obscureText: true,
//                           inputFormatters: [
//                             FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
//                           ],
//                           decoration: InputDecoration(
//                             hintText: "Құпиясөз",
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 14,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide(
//                                   color: Colors.pink.shade300, width: 2),
//                             ),
//                           ),
//                         ),
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton(
//                             onPressed: () => _showForgotPasswordFlow(context),
//                             child: Text(
//                               "Құпиясөзді ұмыттыңыз ба?",
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.pink.shade400,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         SizedBox(
//                           width: double.infinity,
//                           height: 50,
//                           child: ElevatedButton.icon(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.pink.shade50,
//                               foregroundColor: Colors.black,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                                 side: BorderSide(
//                                     color: Colors.pink.shade300, width: 1.5),
//                               ),
//                               elevation: 4,
//                             ),
//                             onPressed: _onLoginPressed,
//                             icon: const Icon(
//                               Icons.login,
//                               color: Colors.pink,
//                             ),
//                             label: const Text(
//                               "Кіру",
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // "Тіркелу" батырмасы
//           Positioned(
//             bottom: 40,
//             right: 30,
//             child: SizedBox(
//               width: 200,
//               height: 55,
//               child: ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.pink.shade400,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   elevation: 8,
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const RegisterApp(),
//                     ),
//                   );
//                 },
//                 icon: const Icon(
//                   Icons.arrow_forward_rounded,
//                   size: 26,
//                 ),
//                 label: const Text(
//                   "Тіркелу",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'forgot_password_screen.dart'; // Жаңа бетті импорттау

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   // Құпиясөзді қалпына келтіру ағынын бастау функциясы
//   void _showForgotPasswordFlow(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => const ForgotPasswordScreen(),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           // 🌸 Гүл суреті — толық көріну үшін
//           Positioned(
//             top: 0,
//             right: -30,
//             child: SizedBox(
//               width: 250,
//               height: 250,
//               child: Image.asset(
//                 'assets/glavflow.png',
//                 fit: BoxFit.contain,
//               ),
//             ),
//           ),

//           // 📦 Кіру формасының контейнері
//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 320,
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       // Контейнердің фоны
//                       color: Colors.white.withOpacity(0.95), // Сәл аз мөлдірлік
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: const [
//                         BoxShadow(
//                           color: Colors.black12,
//                           blurRadius: 10,
//                           offset: Offset(0, 5),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         const SizedBox(height: 10),

//                         // 🔑 Кілт суретінің контейнері (Үлкейтілді: 140x140)
//                         Container(
//                           width: 140, 
//                           height: 140, 
//                           decoration: const BoxDecoration(
//                             // Фоны мөлдір, негізгі контейнердің түсімен үйлеседі.
//                             color: Colors.transparent,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(10),
//                             child: Image.asset(
//                               'assets/key.png',
//                               fit: BoxFit.contain,
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 10),

//                         const Text(
//                           "Кіріп, жақыныңызды қуантыңыз!",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.black,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),

//                         const SizedBox(height: 25),

//                         // 📱 Телефон нөмірі өрісі (тек телефон)
//                         TextField(
//                           keyboardType: TextInputType.phone,
//                           decoration: InputDecoration(
//                             // PrefixText арқасында "+7 " әрқашан көрініп тұрады
//                             prefixText: "+7 ", 
//                             hintStyle: const TextStyle(color: Colors.black54), // PrefixText-пен үйлестіру
//                             hintText: "Телефон нөмірі", 
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 14,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 16),

//                         // 🔒 Құпиясөз өрісі
//                         TextField(
//                           obscureText: true,
//                           decoration: InputDecoration(
//                             hintText: "Құпиясөз",
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 14,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
//                             ),
//                           ),
//                         ),

//                         // ❓ Құпиясөзді ұмыттыңыз ба? сілтемесі
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton(
//                             onPressed: () => _showForgotPasswordFlow(context), // Жаңа экранға өту
//                             child: Text(
//                               "Құпиясөзді ұмыттыңыз ба?",
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.pink.shade400,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 10),

//                         // ✅ Кіру батырмасы
//                         SizedBox(
//                           width: double.infinity,
//                           height: 50,
//                           child: ElevatedButton.icon(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.pink.shade50,
//                               foregroundColor: Colors.black,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                                 side: BorderSide(color: Colors.pink.shade300, width: 1.5),
//                               ),
//                               elevation: 4,
//                             ),
//                             onPressed: () {
//                               // Кіру логикасы
//                             },
//                             icon: const Icon(
//                               Icons.login, // Иконка логинге сай
//                               color: Colors.pink,
//                             ),
//                             label: const Text(
//                               "Кіру",
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // 🌸 "Тіркелу" батырмасы — экранның төменгі оң жақ бұрышында
//           Positioned(
//             bottom: 40,
//             right: 30,
//             child: SizedBox(
//               width: 200,
//               height: 55,
//               child: ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.pink.shade400,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   elevation: 8,
//                 ),
//                 onPressed: () {
//                   // Тіркелу бетіне өту логикасы
//                 },
//                 icon: const Icon(
//                   Icons.arrow_forward_rounded, // Стрелка иконкасы
//                   size: 26,
//                 ),
//                 label: const Text(
//                   "Тіркелу",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



