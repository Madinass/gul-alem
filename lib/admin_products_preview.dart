import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'admin_products_screen.dart';
import 'app_language.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final languageController = AppLanguageController();
  await languageController.load();

  runApp(
    AppLanguageScope(
      controller: languageController,
      child: const AdminProductsPreviewApp(),
    ),
  );
}

class AdminProductsPreviewApp extends StatelessWidget {
  const AdminProductsPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLanguageScope.watch(context).locale;
    final baseTheme = ThemeData(
      fontFamily: 'Rubik',
      fontFamilyFallback: const ['NotoSans'],
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale.flutterLocale,
      supportedLocales: AppLocale.values.map((locale) => locale.flutterLocale),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: baseTheme,
      home: const AdminProductsScreen(),
    );
  }
}
