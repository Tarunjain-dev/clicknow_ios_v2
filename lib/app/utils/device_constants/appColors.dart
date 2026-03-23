import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// -- Newly Added System Colors
  static const Color purple1 = Color(0xff9235B1);
  static const Color purple2 = Color(0xff570173);
  static const Color purple3 = Color(0xff360248);
  static const Color white = Color(0xffFFFFFF);
  static const Color black = Color(0xff000000);
  static const Color grey = Color(0xff515151);
  static const Color lightGrey = Color(0xffE0E0E0);
  static const Color blue = Color(0xff2F4BE9);
  static const Color transparent = Colors.transparent;

  /// -- Divider Colors
  static const Color dividerColor = Color(0xff515151);

  /// -- Button Colors
  static const Color buttonBackground = Color(0xffFFFFFF);
  static const Color buttonForeground = Color(0xff360248);


  /// -- Text Colors
  Color titleColor = Color(0xffffffff).withValues(alpha: 1.0);
  static final Color descriptionColor = Color(0xffffffff).withValues(alpha: 0.6);

  /// -- Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xff000000),
      Color(0xff150A26),
      Color(0xff291349),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [
      0.20,
      0.68,
      1.80
    ]
  );
}