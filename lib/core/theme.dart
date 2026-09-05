import 'package:flutter/material.dart';

const kPrimary = Color(0xFF047857);
const kPrimaryDark = Color(0xFF064E3B);
const kPrimaryLight = Color(0xFF34D399);
const kAccent = Color(0xFF10B981);
const kBackground = Color(0xFFF0FDF4);
const kTextPrimary = Color(0xFF111827);
const kTextSecondary = Color(0xFF6B7280);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: kPrimary,
    scaffoldBackgroundColor: kBackground,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: kTextPrimary,
      displayColor: kTextPrimary,
    ),
  );
}