import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import 'views/landing_view.dart';

void main() async {
  // 2. Wajib ditambahkan agar Flutter siap menjalankan proses sebelum UI dirender
  WidgetsFlutterBinding.ensureInitialized();
  
  // 3. Menyalakan mesin Hive
  await Hive.initFlutter();
  
  // 4. Membuka kotak penyimpanan bernama 'historyBox'
  await Hive.openBox('historyBox');

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
        scaffoldBackgroundColor: const Color(0xFF01161E),
        primaryColor: const Color(0xFF124559),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF124559),
          foregroundColor: Color(0xFFEFF6E0),
          elevation: 0,
        ),
      ),
      home: const LandingView(),
    );
  }
}