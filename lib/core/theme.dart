import 'package:flutter/material.dart';

// Warna seed brand madrasah — dipakai hanya sebagai fallback (saat dynamic
// color tidak tersedia). Dengan dynamic scheme (Material You), warna asli
// diambil dari color scheme yang mengikuti wallpaper Android.
const kPrimary = Color(0xFF047857);

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

  final appBar = light
      ? scheme.primary
      : Color.lerp(scheme.primary, Colors.black, 0.4)!;

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: appBar,
      foregroundColor: scheme.onPrimary,
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