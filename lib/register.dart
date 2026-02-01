import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Форматтау үшін

import 'bas_bet_screen.dart'; // Сақтау
import 'login_screen.dart'; // Сақтау
// Мына импортты қосыңыз немесе түзетіңіз:
import 'main_wrapper.dart'; 
import 'services/api_service.dart';

class RegisterApp extends StatelessWidget {
  const RegisterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RegisterScreen(),
    );
  }
}
 
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    nameController.dispose();
    numberController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegistration() async {
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    // Құпия сөздің ұзындығы және шарттар
    if (password.length < 8 || password.length > 64) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Құпия сөз 8-64 таңба аралығында болуы керек."), backgroundColor: Colors.red),
      );
      return;
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Құпия сөзде кемінде бір сан болуы керек."), backgroundColor: Colors.red),
      );
      return;
    }
    if (!RegExp(r'[^\w\s]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Құпия сөзде кемінде бір арнайы таңба болуы керек."), backgroundColor: Colors.red),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Құпия сөздер сәйкес келмейді!"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final data = await ApiService.register(
        name: nameController.text.trim(),
        phone: numberController.text.trim(),
        email: emailController.text.trim(),
        password: password,
      );

      await ApiService.storeSession(
        token: data['token'] ?? '',
        role: data['role'] ?? 'user',
        email: data['email'] ?? '',
        name: data['name'] ?? '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Тіркелу сәтті өтті!"), backgroundColor: Colors.green),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Серверге қосылу қатесі: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isPassword,
    bool isVisible,
    Function(bool) toggleVisibility, [
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  ]) {
    final primaryColor = const Color.fromARGB(255, 238, 111, 151);

    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: primaryColor),
        counterText: maxLength != null ? "" : null,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: primaryColor,
                ),
                onPressed: () => toggleVisibility(!isVisible),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const softPink = Color.fromARGB(255, 255, 245, 247);
    const darkPink = Color.fromARGB(255, 230, 0, 100);
    final Size screenSize = MediaQuery.of(context).size;

    const String placeholderAssetPath = 'assets/icon_profile.png';
    const double imageSize = 100.0;

    return Scaffold(
      backgroundColor: softPink,
      body: Stack(
        children: [
          Positioned(
            top: -screenSize.height * 0.1,
            right: -screenSize.width * 0.1,
            child: Container(
              width: screenSize.width * 0.8,
              height: screenSize.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: darkPink.withOpacity(0.05),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 80, bottom: 120, left: 25, right: 25),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
                elevation: 15,
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        placeholderAssetPath,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: imageSize,
                            height: imageSize,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 192, 203),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Center(
                              child: Icon(Icons.person, size: 50, color: Colors.white),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Тіркеліп, жақыныңызды қуантыңыз!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildTextField(
                        nameController,
                        "Аты-жөніңіз",
                        Icons.person_outline,
                        false,
                        false,
                        (v) {},
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        numberController,
                        "Телефон нөмірі",
                        Icons.phone_android,
                        false,
                        false,
                        (v) {},
                        TextInputType.phone,
                        null,
                        11,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        emailController,
                        "Эл. пошта",
                        Icons.email_outlined,
                        false,
                        false,
                        (v) {},
                        TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        passwordController,
                        "Құпия сөз",
                        Icons.lock_outline,
                        true,
                        _isPasswordVisible,
                        (v) => setState(() => _isPasswordVisible = v),
                        TextInputType.text,
                        null,
                        64,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        confirmPasswordController,
                        "Құпия сөзді қайталау",
                        Icons.lock_reset,
                        true,
                        _isConfirmPasswordVisible,
                        (v) => setState(() => _isConfirmPasswordVisible = v),
                        TextInputType.text,
                        null,
                        64,
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Тіркелгенсіз бе?",
                            style: TextStyle(color: Colors.black54),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            child: Text(
                              "Кіру",
                              style: TextStyle(color: darkPink, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkPink,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 10,
                  ),
                  onPressed: _handleRegistration,
                  child: const Text(
                    "Тіркелуден өту",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
// import 'shop_screen.dart';
// import 'login_screen.dart';

// class RegisterApp extends StatelessWidget{
//     const RegisterApp({super.key});


//     @override
//     Widget build(BuildContext context) {
//         return MaterialApp(
//             debugShowCheckedModeBanner: false,
//             home: const RegisterScreen(),
//         );
// }
// }

// class RegisterScreen extends StatefulWidget{
//     const RegisterScreen({super.key});
//     @override 
//     State<RegisterScreen> createState() => _RegisterScreenState();
// }
// class _RegisterScreenState extends State<RegisterScreen>{
//     final TextEditingController emailController = TextEditingController();
//     final TextEditingController passwordController = TextEditingController();
//     final TextEditingController numberController = TextEditingController();
//     final TextEditingController nameController = TextEditingController();

//     @override
//     Widget build(BuildContext context) {
//         return Scaffold(
//             body: Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                         colors:[const Color.fromARGB(255, 247, 122, 228),const Color.fromARGB(255, 137, 240, 114)],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                     ), 
//                 ), 
//                 child: Center(
//                     child: SingleChildScrollView(
//                         child:Card(
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.all(Radius.circular(20)),
//                             ), 
//                             elevation: 8,
//                             child: Padding(
//                                 padding: const EdgeInsets.all(24),
//                                 child: Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                         Icon(Icons.person,size: 80,color: Colors.indigo,),
//                                         const SizedBox(height: 20,),
//                                         const Text(
//                                             "Тіркелуден өтіңіз",
//                                             style: TextStyle(
//                                                 fontSize: 22,
//                                                 fontWeight: FontWeight.bold,
//                                             ), 
//                                         ),
//                                         const SizedBox(height: 20),
//                                         TextField(
//                                             controller: nameController,
//                                             decoration: InputDecoration(
//                                                 labelText: "Name",
//                                                 border: OutlineInputBorder(
//                                                     borderRadius: BorderRadius.circular(15),
//                                                 ), 
//                                             ), 
//                                          ),
//                                         const SizedBox(height: 20),
//                                         TextField(
//                                             controller: numberController,
//                                             decoration: InputDecoration(
//                                                 labelText: "Phone number",
//                                                 border: OutlineInputBorder(
//                                                     borderRadius: BorderRadius.circular(15),
//                                                 ), 
//                                             ), 
//                                          ),                                                                                 
//                                         const SizedBox(height: 20),
//                                         TextField(
//                                             controller: emailController,
//                                             decoration: InputDecoration(
//                                                 prefixIcon: const Icon(Icons.email),
//                                                 labelText: "Email",
//                                                 border: OutlineInputBorder(
//                                                     borderRadius: BorderRadius.circular(15),
//                                                 ), 
//                                             ), 
//                                          ),
//                                         const SizedBox(height: 20),
//                                          TextField(
//                                             controller: passwordController,
//                                                 obscureText: true,
//                                                 decoration: InputDecoration(
//                                                 prefixIcon: const Icon(Icons.lock),
//                                                 labelText: "Password",
//                                                 border: OutlineInputBorder(
//                                                     borderRadius: BorderRadius.circular(15),
//                                                 ), 
//                                             ), 
//                                          ),  

                                         
//                                          const SizedBox(height: 30,),
//                                          SizedBox(
//                                             width: double.infinity,
//                                             child: ElevatedButton(
                                               
//                                                 style: ElevatedButton.styleFrom(
//                                                     padding: const EdgeInsets.symmetric(vertical: 15),
//                                                     shape: RoundedRectangleBorder(
//                                                         borderRadius: BorderRadius.circular(15),
//                                                     ),
//                                                 ),
//                                                 onPressed: (){
//                                                     String name = nameController.text;
//                                                     String number = numberController.text; 
//                                                     String email = emailController.text;
//                                                     String password = passwordController.text;
//                                                     ScaffoldMessenger.of(context).showSnackBar(
//                                                         SnackBar(content: Text("Регистрация: $name, $number,$email, $password")),
//                                                     );
//                                                     Navigator.pushReplacement(
//                                                       context,
//                                                       MaterialPageRoute(
//                                                         builder: (context) => const ShopScreen(), 
//                                                         ),
//                                                         );
//                                                 },
//                                                 child: const Text("Тіркелуден өту",style: TextStyle(fontSize: 18),),
//                                             ), 
//                                          ), 
//                                                 const SizedBox(height: 10),
//                                                 Row(
//                                                 mainAxisAlignment: MainAxisAlignment.center,
//                                                children: [
//                                                   const Text("Тіркелгенсіз бе?"),
//                                                 TextButton(
//                                                onPressed: () {
//                                               Navigator.push(
//                                              context,
//                                              MaterialPageRoute(builder: (context) => const LoginScreen()),
//                                              );
//                                              },
//                                             child: const Text(
//                                              "Кіру",
//                                              style: TextStyle(color: Colors.indigo),
//                                              ),
//                                              ),
//                                               ],
//                                              ),

//                                     ],
//                                 ), 
//                             ), 
//                         ), 
//                     ), 
//                 ), 
//             ), 
//         );  
//     }
// }
