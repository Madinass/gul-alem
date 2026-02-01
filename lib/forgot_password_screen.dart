import 'package:flutter/material.dart';
import 'services/api_service.dart';

enum ForgotPasswordStep {
  enterPhone,
  verifyCode,
  setNewPassword,
  success,
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.enterPhone;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _resetToken;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_isSubmitting) return;
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      switch (_currentStep) {
        case ForgotPasswordStep.enterPhone:
          final email = _emailController.text.trim();
          final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
          if (!emailOk) {
            setState(() {
              _errorMessage = 'Дұрыс email енгізіңіз.';
            });
            return;
          }
          await ApiService.requestPasswordReset(email);
          setState(() {
            _currentStep = ForgotPasswordStep.verifyCode;
          });
          return;

        case ForgotPasswordStep.verifyCode:
          if (_codeController.text.length != 6) {
            setState(() {
              _errorMessage = 'Код 6 таңбадан тұруы керек.';
            });
            return;
          }
          final resetToken =
              await ApiService.verifyResetCode(_emailController.text.trim(), _codeController.text);
          if (resetToken.isEmpty) {
            setState(() {
              _errorMessage = 'Код қате. Қайта көріңіз.';
            });
            return;
          }
          _resetToken = resetToken;
          setState(() {
            _currentStep = ForgotPasswordStep.setNewPassword;
          });
          return;

        case ForgotPasswordStep.setNewPassword:
          if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
            setState(() {
              _errorMessage = 'Жаңа құпиясөзді енгізіп, растаңыз.';
            });
            return;
          }
          if (_passwordController.text != _confirmPasswordController.text) {
            setState(() {
              _errorMessage = 'Құпиясөздер сәйкес келмейді.';
            });
            return;
          }
          final password = _passwordController.text;
          if (password.length < 8 || password.length > 64) {
            setState(() {
              _errorMessage = 'Құпиясөз 8-64 таңба аралығында болуы керек.';
            });
            return;
          }
          final hasNumber = RegExp(r'\d').hasMatch(password);
          final hasSpecial = RegExp(r'[^\w\s]').hasMatch(password);
          if (!hasNumber || !hasSpecial) {
            setState(() {
              _errorMessage = 'Құпиясөзде кемінде бір сан және арнайы таңба болуы керек.';
            });
            return;
          }
          if (_resetToken == null || _resetToken!.isEmpty) {
            setState(() {
              _errorMessage = 'Қалпына келтіру мерзімі өтті. Жаңа код сұраңыз.';
            });
            return;
          }
          await ApiService.resetPassword(
            email: _emailController.text.trim(),
            resetToken: _resetToken!,
            newPassword: _passwordController.text,
          );
          setState(() {
            _currentStep = ForgotPasswordStep.success;
          });
          return;

        case ForgotPasswordStep.success:
          Navigator.of(context).pop();
          return;
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Қате пайда болды. Қайта көріңіз.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _prevStep() {
    if (_currentStep == ForgotPasswordStep.enterPhone) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _errorMessage = null;
      switch (_currentStep) {
        case ForgotPasswordStep.verifyCode:
          _currentStep = ForgotPasswordStep.enterPhone;
          break;
        case ForgotPasswordStep.setNewPassword:
          _currentStep = ForgotPasswordStep.verifyCode;
          break;
        case ForgotPasswordStep.success:
          _currentStep = ForgotPasswordStep.setNewPassword;
          break;
        case ForgotPasswordStep.enterPhone:
          break;
      }
    });
  }

  String get _title {
    switch (_currentStep) {
      case ForgotPasswordStep.enterPhone:
        return 'Email енгізу';
      case ForgotPasswordStep.verifyCode:
        return 'Кодты тексеру';
      case ForgotPasswordStep.setNewPassword:
        return 'Жаңа құпиясөз';
      case ForgotPasswordStep.success:
        return 'Сәтті';
    }
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_currentStep) {
      case ForgotPasswordStep.enterPhone:
        return _buildEmailInputStep();
      case ForgotPasswordStep.verifyCode:
        return _buildCodeVerificationStep();
      case ForgotPasswordStep.setNewPassword:
        return _buildNewPasswordStep();
      case ForgotPasswordStep.success:
        return _buildSuccessStep();
    }
  }

  Widget _buildEmailInputStep() {
    return Column(
      children: [
        const Text(
          'Қалпына келтіру кодын алу үшін email енгізіңіз.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Email адресі',
            errorText: _errorMessage,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildActionButton('Код жіберу', Icons.send),
      ],
    );
  }

  Widget _buildCodeVerificationStep() {
    return Column(
      children: [
        Text(
          '${_emailController.text} адресіне келген 6 таңбалы кодты енгізіңіз.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: 'Код',
            errorText: _errorMessage,
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildActionButton('Кодты растау', Icons.check_circle_outline),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      children: [
        const Text(
          'Жаңа құпиясөзді енгізіп, растаңыз (8-64 таңба, 1 сан және арнайы таңба).',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Жаңа құпиясөз',
            errorText: _errorMessage,
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.pink),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Құпиясөзді растаңыз',
            prefixIcon: const Icon(Icons.lock_reset, color: Colors.pink),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildActionButton('Құпиясөзді өзгерту', Icons.key_sharp),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.sentiment_very_satisfied,
          color: Colors.green,
          size: 80,
        ),
        const SizedBox(height: 20),
        const Text(
          'Құпиясөз сәтті өзгертілді!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 10),
        const Text(
          'Енді жаңа құпиясөзбен кіре аласыз.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 30),
        _buildActionButton('Кіру бетіне', Icons.arrow_back),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
        onPressed: _isSubmitting ? null : _nextStep,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink.shade50,
        elevation: 0,
        title: Text(
          _title,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _prevStep,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double verticalPadding = 30.0;
          final double minContentHeight = constraints.maxHeight;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(verticalPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minContentHeight - (verticalPadding * 2),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.pinkAccent,
                        blurRadius: 15,
                        spreadRadius: -5,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildStepContent(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
