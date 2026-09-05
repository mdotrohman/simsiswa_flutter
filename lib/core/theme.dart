import 'package:flutter/material.dart';

// Identitas brand madrasah (dipakai di mode terang & gelap).
const kPrimary = Color(0xFF047857);
const kPrimaryDark = Color(0xFF064E3B);
const kPrimaryLight = Color(0xFF34D399);
const kAccent = Color(0xFF10B981);
const kBackground = Color(0xFFF0FDF4);
const kTextPrimary = Color(0xFF111827);
const kTextSecondary = Color(0xFF6B7280);
const kNavGreen = Color(0xFF00664F);

/// Tema premium: terang & gelap. Bila [dynamicScheme] diberikan (dari
/// DynamicColorBuilder — warna adaptif wallpaper ala Android 12+/16),
/// skema itu dipakai sebagai sumber warna; jika tidak, fallback seed emerald.
ThemeData buildAppTheme(Brightness brightness, {ColorScheme? dynamicScheme}) {
  final light = brightness == Brightness.light;
  final scheme = dynamicScheme ??
      ColorScheme.fromSeed(
        seedColor: kPrimary,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.content,
      );

  final appBar = light ? kPrimaryDark : const Color(0xFF01231C);

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        light ? kBackground : const Color(0xFF081512),
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: appBar,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    textTheme: base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: scheme.onPrimary,
      ),
    ),
  );
}