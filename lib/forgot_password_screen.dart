import 'package:flutter/material.dart';

// Қадамдардың атаулары
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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Қате туралы хабарламаны көрсету үшін
  String? _errorMessage;

  // Келесі қадамға өту логикасы
  void _nextStep() {
    setState(() {
      _errorMessage = null; // Әрбір қадамда қатені тазалау

      switch (_currentStep) {
        case ForgotPasswordStep.enterPhone:
          // 1. Телефон нөмірін тексеру (мысалы, кем дегенде 9 таңба)
          if (_phoneController.text.length < 9) {
            _errorMessage = "Дұрыс телефон нөмірін енгізіңіз.";
            break;
          }
          // TODO: Телефон нөмірін тексеру және код жіберу логикасын қосыңыз
          _currentStep = ForgotPasswordStep.verifyCode;
          break;

        case ForgotPasswordStep.verifyCode:
          // 2. Кодты тексеру (мысалы, 6 таңба)
          if (_codeController.text.length != 6) {
            _errorMessage = "Растау коды 6 таңбадан тұруы керек.";
            break;
          }
          // TODO: Кодты тексеру логикасын қосыңыз
          _currentStep = ForgotPasswordStep.setNewPassword;
          break;

        case ForgotPasswordStep.setNewPassword:
          // 3. Құпиясөздерді тексеру
          if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
            _errorMessage = "Құпиясөзді енгізіңіз және растаңыз.";
            break;
          }
          if (_passwordController.text != _confirmPasswordController.text) {
            _errorMessage = "Құпиясөздер сәйкес келмейді.";
            break;
          }
          if (_passwordController.text.length < 6) {
             _errorMessage = "Құпиясөз кем дегенде 6 таңбадан тұруы керек.";
            break;
          }
          // TODO: Жаңа құпиясөзді сақтау логикасын қосыңыз
          _currentStep = ForgotPasswordStep.success;
          break;

        case ForgotPasswordStep.success:
          // 4. Сәтті аяқталғаннан кейін кіру бетіне оралу
          Navigator.of(context).pop();
          break;
      }
    });
  }

  // Артқа қайту логикасы
  void _prevStep() {
    if (_currentStep == ForgotPasswordStep.enterPhone) {
      Navigator.of(context).pop(); // Егер бірінші қадам болса, артқа қайту
      return;
    }
    setState(() {
      _errorMessage = null; // Артқа қайтқанда қатені тазалау
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


  // Қадамға байланысты тақырыпты қайтарады
  String get _title {
    switch (_currentStep) {
      case ForgotPasswordStep.enterPhone:
        return "Нөмірді енгізіңіз";
      case ForgotPasswordStep.verifyCode:
        return "Кодты растаңыз";
      case ForgotPasswordStep.setNewPassword:
        return "Жаңа құпиясөз";
      case ForgotPasswordStep.success:
        return "Сәтті аяқталды";
    }
  }

  // Негізгі контентті қадамға байланысты құрастырады
  Widget _buildStepContent(BuildContext context) {
    switch (_currentStep) {
      case ForgotPasswordStep.enterPhone:
        return _buildPhoneInputStep();
      case ForgotPasswordStep.verifyCode:
        return _buildCodeVerificationStep();
      case ForgotPasswordStep.setNewPassword:
        return _buildNewPasswordStep();
      case ForgotPasswordStep.success:
        return _buildSuccessStep();
    }
  }

  // Қадам 1: Телефон нөмірін енгізу
  Widget _buildPhoneInputStep() {
    return Column(
      children: [
        const Text(
          "Қалпына келтіру үшін телефон нөміріңізді енгізіңіз.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            prefixText: "+7 ",
            hintText: "Телефон нөміріңіз",
            errorText: _errorMessage, // Қате хабарламасын көрсету
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildActionButton("Код жіберу", Icons.send),
      ],
    );
  }

  // Қадам 2: Кодты растау
  Widget _buildCodeVerificationStep() {
    return Column(
      children: [
        Text(
          "Сіздің нөміріңізге (+7 ${_phoneController.text}) жіберілген 6 таңбалы кодты енгізіңіз.",
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
            hintText: "Код",
            errorText: _errorMessage,
            counterText: "", // maxLength-тен кейінгі санауышты жасыру
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildActionButton("Кодты растау", Icons.check_circle_outline),
      ],
    );
  }

  // Қадам 3: Жаңа құпиясөзді енгізу
  Widget _buildNewPasswordStep() {
    return Column(
      children: [
        const Text(
          "Жаңа құпиясөзді енгізіп, оны растаңыз. (Кем дегенде 6 таңба)",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        // Жаңа құпиясөз
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Жаңа құпиясөз",
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
        // Құпиясөзді қайталау
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Құпиясөзді қайта растаңыз",
            prefixIcon: const Icon(Icons.lock_reset, color: Colors.pink),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildActionButton("Құпиясөзді өзгерту", Icons.key_sharp),
      ],
    );
  }

  // Қадам 4: Сәтті аяқталу
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
          "Құпиясөз сәтті өзгертілді!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 10),
        const Text(
          "Енді жаңа құпиясөзіңізбен кіре аласыз.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 30),
        _buildActionButton("Кіру бетіне өту", Icons.arrow_back),
      ],
    );
  }

  // Әрекет батырмасының жалпы үлгісі
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
        onPressed: _nextStep,
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
      // Контейнерді вертикальды түрде ортаға қою үшін ConstrainedBox және LayoutBuilder қолдану
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Пайдаланушының body-ге берген 30 padding-ін ескеру
          const double verticalPadding = 30.0;
          
          // LayoutBuilder-ден қолжетімді биіктікті аламыз
          final double minContentHeight = constraints.maxHeight;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(verticalPadding),
            // Егер контент экраннан кіші болса, оны ортаға қою үшін minHeight қолданылады
            child: ConstrainedBox(
              // Минималды биіктік: қолжетімді биіктік минус жалпы вертикалды padding (30 + 30)
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
