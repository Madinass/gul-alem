import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'app_language.dart';
import 'home_screen.dart';
import 'main_wrapper.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageController = AppLanguageController();
  final hasStoredSession = ApiService.hasStoredSession();
  await Future.wait<void>([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    languageController.load(),
  ]);
  runApp(
    AppLanguageScope(
      controller: languageController,
      child: MyApp(initialHasSession: await hasStoredSession),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool initialHasSession;

  const MyApp({super.key, required this.initialHasSession});

  @override
  Widget build(BuildContext context) {
    final locale = AppLanguageScope.watch(context).locale;
    final baseTheme = ThemeData(
      fontFamily: 'Rubik',
      fontFamilyFallback: const ['NotoSans'],
    );
    final textTheme = _bolderTextTheme(baseTheme.textTheme);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale.flutterLocale,
      supportedLocales: AppLocale.values.map((locale) => locale.flutterLocale),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: baseTheme.copyWith(
        textTheme: textTheme,
        primaryTextTheme: _bolderTextTheme(baseTheme.primaryTextTheme),
      ),
      home: _SessionGate(initialHasSession: initialHasSession),
    );
  }
}

class _SessionGate extends StatefulWidget {
  final bool initialHasSession;

  const _SessionGate({required this.initialHasSession});

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  late bool _hasSession;

  @override
  void initState() {
    super.initState();
    _hasSession = widget.initialHasSession;
    if (_hasSession) {
      unawaited(_validateSession());
    }
  }

  Future<void> _validateSession() async {
    final isValid = await ApiService.validateStoredSession();
    if (!mounted || isValid != false) return;
    setState(() => _hasSession = false);
  }

  @override
  Widget build(BuildContext context) {
    return _hasSession ? const MainWrapper() : const HomeScreen();
  }
}

TextTheme _bolderTextTheme(TextTheme textTheme) {
  TextStyle? bolder(TextStyle? style) {
    if (style == null) return null;
    final weight = _strongerFontWeight(style.fontWeight);
    return style.copyWith(
      fontWeight: weight,
      fontVariations: [FontVariation('wght', _fontVariationWeight(weight))],
    );
  }

  return textTheme.copyWith(
    displayLarge: bolder(textTheme.displayLarge),
    displayMedium: bolder(textTheme.displayMedium),
    displaySmall: bolder(textTheme.displaySmall),
    headlineLarge: bolder(textTheme.headlineLarge),
    headlineMedium: bolder(textTheme.headlineMedium),
    headlineSmall: bolder(textTheme.headlineSmall),
    titleLarge: bolder(textTheme.titleLarge),
    titleMedium: bolder(textTheme.titleMedium),
    titleSmall: bolder(textTheme.titleSmall),
    bodyLarge: bolder(textTheme.bodyLarge),
    bodyMedium: bolder(textTheme.bodyMedium),
    bodySmall: bolder(textTheme.bodySmall),
    labelLarge: bolder(textTheme.labelLarge),
    labelMedium: bolder(textTheme.labelMedium),
    labelSmall: bolder(textTheme.labelSmall),
  );
}

FontWeight _strongerFontWeight(FontWeight? weight) {
  if (weight == null || weight.index <= FontWeight.w400.index) {
    return FontWeight.w600;
  }
  if (weight == FontWeight.w500) return FontWeight.w600;
  return weight;
}

double _fontVariationWeight(FontWeight weight) {
  return (weight.index + 1) * 100.0;
}
