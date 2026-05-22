import 'package:flutter/material.dart';
import 'views/landing_view.dart';

void main() {
  runApp(const ContourApp());
}

class ContourApp extends StatelessWidget {
  const ContourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contour Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF01161E), // 01161e
        primaryColor: const Color(0xFF124559), // 124559
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF124559),
          foregroundColor: Color(0xFFEFF6E0), // eff6e0
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFEFF6E0)),
          titleLarge: TextStyle(color: Color(0xFFEFF6E0)),
        ),
      ),
      home: const LandingView(), 
    );
  }
}