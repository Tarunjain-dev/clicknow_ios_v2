import 'package:flutter/material.dart';

class AppTheme{
  AppTheme._(); // private constructor

  /// -- Light Theme Data
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
  );

  /// -- Dark Theme Data
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
  );
}