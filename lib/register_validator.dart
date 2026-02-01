class RegisterValidator {
  static String? validatePassword(
    String password,
    String confirmPassword,
  ) {
    if (password.length < 8) {
      return "Құпия сөз кемінде 8 таңбадан тұруы керек.";
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Құпия сөз кемінде бір бас әріптен (А-Я) тұруы керек.";
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Құпия сөз кемінде бір саннан (0-9) тұруы керек.";
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
