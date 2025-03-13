import 'package:flutter/material.dart';

class AppThemes {
  // 🌞 Light Mode Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white, // Màu chữ AppBar
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black), // Màu chữ trong Light Mode
    ),
  );

  // 🌙 Dark Mode Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blueGrey,
    scaffoldBackgroundColor: Colors.black87,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blueGrey,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white), // Màu chữ trong Dark Mode
    ),
  );
}
