import 'package:flutter/material.dart';
import 'app_language.dart';
import 'forgot_password_screen.dart';
import 'main_wrapper.dart';
import 'register.dart';
import 'services/api_service.dart';
import 'widgets/language_switcher.dart';
import 'widgets/top_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;

  bool get _canSubmit =>
      _phoneController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      !_isLoading;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onInputChanged);
    _passwordController.removeListener(_onInputChanged);
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  String? _normalizedLogin(String value) {
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      final emailOk = RegExp(
        r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$',
      ).hasMatch(trimmed);
      return emailOk ? trimmed.toLowerCase() : null;
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10 && digits.length <= 11) return digits;
    return null;
  }

  Future<void> _onLoginPressed() async {
    if (_isLoading) return;
    final t = context.t;
    final loginInput = _normalizedLogin(_phoneController.text);
    final password = _passwordController.text;

    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar(t.loginRequired, Colors.redAccent);
      return;
    }
    if (loginInput == null) {
      _showSnackBar(t.invalidLoginFormat, Colors.redAccent);
      return;
    }

    if (password.length < 8) {
      _showSnackBar(t.passwordTooShort, Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await ApiService.login(loginInput, password);
      await ApiService.storeSession(
        token: data['token'] ?? '',
        role: data['role'] ?? 'user',
        email: data['email'] ?? '',
        name: data['name'] ?? '',
      );
      if (!mounted) return;
      _showSnackBar(t.welcome, Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(t.loginFailed, Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    showTopToast(context, message, backgroundColor: color);
  }

  void _showForgotPasswordFlow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
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
                      children: [
                        const Align(
                          alignment: Alignment.centerRight,
                          child: LanguageSwitcher(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: Image.asset(
                            'assets/icon_key.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.vpn_key,
                                  size: 100,
                                  color: Color(0xFFE91E63),
                                ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.loginSubtitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 25),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _inputStyle(t.phoneOrEmail),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _isObscure,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (_canSubmit) _onLoginPressed();
                          },
                          decoration: _inputStyle(t.password).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.pink,
                              ),
                              onPressed: () =>
                                  setState(() => _isObscure = !_isObscure),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotPasswordFlow(context),
                            child: Text(
                              t.forgotPassword,
                              style: TextStyle(
                                color: Colors.pink.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.pink,
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: _buttonStyle(
                                    Colors.pink.shade50,
                                    Colors.pink.shade300,
                                  ),
                                  onPressed: _canSubmit
                                      ? _onLoginPressed
                                      : null,
                                  icon: const Icon(
                                    Icons.login,
                                    color: Colors.pink,
                                  ),
                                  label: Text(
                                    t.login,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
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
                  MaterialPageRoute(builder: (context) => const RegisterApp()),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  t.register,
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
      disabledBackgroundColor: bg,
      foregroundColor: Colors.black87,
      disabledForegroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border, width: 1.5),
      ),
      elevation: 4,
    );
  }
}
