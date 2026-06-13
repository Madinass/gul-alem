import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry? _activeToastEntry;
Timer? _activeToastTimer;

void _clearActiveToast() {
  _activeToastTimer?.cancel();
  _activeToastTimer = null;

  final entry = _activeToastEntry;
  if (entry != null && entry.mounted) {
    entry.remove();
  }
  _activeToastEntry = null;
}

void showTopToast(
  BuildContext context,
  String message, {
  Color backgroundColor = const Color(0xFF2E2E2E),
  Color foregroundColor = Colors.white,
  Duration duration = const Duration(seconds: 3),
}) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return;

  _clearActiveToast();

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(trimmed),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  _activeToastEntry = OverlayEntry(
    builder: (context) {
      final top = MediaQuery.viewPaddingOf(context).top + 12;
      return Positioned(
        top: top,
        left: 16,
        right: 16,
        child: IgnorePointer(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Text(
                      trimmed,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(_activeToastEntry!);
  _activeToastTimer = Timer(duration, () {
    _clearActiveToast();
  });
}
