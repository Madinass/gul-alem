class RegisterValidator {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _nameLetterPattern = RegExp(
    r"[A-Za-zА-Яа-яЁёӘәІіҢңҒғҮүҰұҚқӨөҺһ]",
  );
  static final RegExp _nameAllowedPattern = RegExp(
    r"^[A-Za-zА-Яа-яЁёӘәІіҢңҒғҮүҰұҚқӨөҺһ\s'.-]+$",
  );

  static String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  static bool isValidFullName(String name) {
    final value = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    return value.length >= 2 &&
        value.length <= 80 &&
        _nameLetterPattern.hasMatch(value) &&
        _nameAllowedPattern.hasMatch(value);
  }

  static bool isValidPhone(String phone) {
    final digits = normalizePhone(phone);
    return digits.length >= 10 && digits.length <= 11;
  }

  static bool isValidEmail(String email) {
    final value = email.trim();
    return value.length <= 254 && _emailPattern.hasMatch(value);
  }

  static String? validatePassword(String password, String confirmPassword) {
    if (password.length < 8 || password.length > 64) {
      return "Құпия сөз 8-64 таңба аралығында болуы керек.";
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return "Құпия сөз кемінде бір саннан (0-9) тұруы керек.";
    }
    if (!RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[^\w\s]').hasMatch(password) ||
        RegExp(r'\s').hasMatch(password)) {
      return "Құпия сөзде кемінде бір арнайы таңба болуы керек.";
    }
    if (password != confirmPassword) {
      return "Құпия сөздер сәйкес келмейді!";
    }
    return null;
  }
}

// class RegisterValidator {
//   static String? validatePassword(
//     String password,
//     String confirmPassword,
//   ) {
//     if (password.length < 8) {
//       return "Құпия сөз кемінде 8 таңбадан тұруы керек.";
//     }
//     if (!RegExp(r'[A-Z]').hasMatch(password)) {
//       return "Құпия сөз кемінде бір бас әріптен (A-Z) тұруы керек.";
//     }
//     if (!RegExp(r'[0-9]').hasMatch(password)) {
//       return "Құпия сөз кемінде бір саннан (0-9) тұруы керек.";
//     }
//     if (password != confirmPassword) {
//       return "Құпия сөздер сәйкес келмейді!";
//     }
//     return null;
//   }
// }
