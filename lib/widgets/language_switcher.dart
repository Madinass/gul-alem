import 'package:flutter/material.dart';

import '../app_language.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  static const List<AppLocale> _locales = [
    AppLocale.ru,
    AppLocale.en,
    AppLocale.kz,
  ];

  @override
  Widget build(BuildContext context) {
    final controller = AppLanguageScope.watch(context);

    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFD7E1)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 6, right: 4),
              child: Icon(
                Icons.language_rounded,
                color: Color(0xFFE60064),
                size: 18,
              ),
            ),
            ..._locales.map((locale) {
              final selected = controller.locale == locale;
              return _LanguageOption(
                locale: locale,
                selected: selected,
                onTap: () {
                  controller.setLocale(locale);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final AppLocale locale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Tooltip(
      message: _name(t),
      child: Semantics(
        button: true,
        selected: selected,
        label: _name(t),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: selected ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: locale == AppLocale.en ? 44 : 36,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFFE6EB) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? const Color(0xFFE60064) : Colors.transparent,
              ),
            ),
            child: Text(
              _label,
              style: TextStyle(
                color: selected ? const Color(0xFFE60064) : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _label {
    switch (locale) {
      case AppLocale.ru:
        return 'RU';
      case AppLocale.en:
        return 'ENG';
      case AppLocale.kz:
        return 'KZ';
    }
  }

  String _name(AppText t) {
    switch (locale) {
      case AppLocale.ru:
        return t.russian;
      case AppLocale.en:
        return t.english;
      case AppLocale.kz:
        return t.kazakh;
    }
  }
}
