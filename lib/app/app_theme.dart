import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static Color primaryColor = Colors.green;
  static Color secondaryColor = Colors.grey.shade300;
  static Color backgroundColor = Colors.grey.shade100;
  static Color primaryDarkColor = Colors.green.shade900;
  static Color accentColor = Colors.green.shade300;
  static Color successColor = Colors.green.shade700;
  static Color warningColor = Colors.yellow.shade700;
  static Color errorColor = Colors.red.shade700;
  static Color infoColor = Colors.blue.shade700;
  static Color titleColor = Colors.grey.shade800;
  static Color subTitleColor = Colors.grey.shade600;

  // Status Color
  static Color noDataColor = Colors.grey;
  static Color inactiveColor = Colors.blue.shade700;
  static Color stopColor = Colors.red.shade700;
  static Color idleColor = Colors.yellow.shade700;
  static Color runningColor = Colors.green.shade600;
  static Color overspeedColor = Colors.orange.shade600;

  // Source Sans 3 Text Styles
  static TextStyle get sourceSans3Regular => GoogleFonts.sourceSans3();
  static TextStyle get sourceSans3Bold =>
      GoogleFonts.sourceSans3(fontWeight: FontWeight.bold);
  static TextStyle get sourceSans3SemiBold =>
      GoogleFonts.sourceSans3(fontWeight: FontWeight.w600);
  static TextStyle get sourceSans3Light =>
      GoogleFonts.sourceSans3(fontWeight: FontWeight.w300);
  static TextStyle get sourceSans3Medium =>
      GoogleFonts.sourceSans3(fontWeight: FontWeight.w500);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.sourceSans3TextTheme(),

      scaffoldBackgroundColor: backgroundColor,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onError: Colors.white,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: titleColor,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: titleColor,
        ),
        iconTheme: IconThemeData(color: titleColor),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: secondaryColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: secondaryColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle: TextStyle(
          color: subTitleColor,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          color: subTitleColor.withOpacity(0.5),
          fontSize: 12,
        ),
        errorStyle: TextStyle(
          color: errorColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
