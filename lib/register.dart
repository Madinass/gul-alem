import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Форматтау үшін

import 'app_language.dart';
import 'login_screen.dart'; // Сақтау
// Мына импортты қосыңыз немесе түзетіңіз:
import 'main_wrapper.dart';
import 'register_validator.dart';
import 'services/api_service.dart';

class RegisterApp extends StatelessWidget {
  const RegisterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegisterScreen();
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
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

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
    final t = context.t;
    final name = nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final phone = RegisterValidator.normalizePhone(numberController.text);
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    void showValidationError(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }

    if (!RegisterValidator.isValidFullName(name)) {
      showValidationError(t.invalidFullName);
      return;
    }
    if (!RegisterValidator.isValidPhone(phone)) {
      showValidationError(t.invalidPhone);
      return;
    }
    if (!RegisterValidator.isValidEmail(email)) {
      showValidationError(t.invalidEmail);
      return;
    }

    // Құпия сөздің ұзындығы және шарттар
    if (password.length < 8 || password.length > 64) {
      showValidationError(t.passwordLengthRule);
      return;
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      showValidationError(t.passwordNumberRule);
      return;
    }
    if (!RegExp(r'[^\w\s]').hasMatch(password)) {
      showValidationError(t.passwordSpecialRule);
      return;
    }
    if (password != confirmPassword) {
      showValidationError(t.passwordsDoNotMatch);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await ApiService.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );

      await ApiService.storeSession(
        token: data['token'] ?? '',
        role: data['role'] ?? 'user',
        email: data['email'] ?? '',
        name: data['name'] ?? '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.registrationSuccess),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.localizedErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: label,
        counterText: maxLength != null ? "" : null,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.pink,
                ),
                onPressed: () => toggleVisibility(!isVisible),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
        ),
        prefixIcon: Icon(icon, color: Colors.pink.shade300, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: -30,
            child: SizedBox(
              width: 250,
              height: 250,
              child: Image.asset(
                'assets/glavflow.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.favorite,
                  size: 250,
                  color: Color(0xFFFFC0CB),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Image.asset(
                        'assets/icon_profile.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person,
                              size: 100,
                              color: Color(0xFFE91E63),
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t.registerSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                      nameController,
                      t.fullName,
                      Icons.person_outline,
                      false,
                      false,
                      (v) {},
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      numberController,
                      t.phoneNumber,
                      Icons.phone_android,
                      false,
                      false,
                      (v) {},
                      TextInputType.phone,
                      [FilteringTextInputFormatter.digitsOnly],
                      11,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      emailController,
                      t.email,
                      Icons.email_outlined,
                      false,
                      false,
                      (v) {},
                      TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      passwordController,
                      t.password,
                      Icons.lock_outline,
                      true,
                      _isPasswordVisible,
                      (v) => setState(() => _isPasswordVisible = v),
                      TextInputType.text,
                      null,
                      64,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      confirmPasswordController,
                      t.confirmPassword,
                      Icons.lock_reset,
                      true,
                      _isConfirmPasswordVisible,
                      (v) => setState(() => _isConfirmPasswordVisible = v),
                      TextInputType.text,
                      null,
                      64,
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.pink)
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: _buttonStyle(
                                Colors.pink.shade50,
                                Colors.pink.shade300,
                              ),
                              onPressed: _handleRegistration,
                              icon: const Icon(
                                Icons.person_add_alt_1,
                                color: Colors.pink,
                              ),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  t.registerAction,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 30,
            child: SizedBox(
              width: 180,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(
                  t.login,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
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
