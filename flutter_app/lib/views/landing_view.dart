import 'package:flutter/material.dart';
import 'home_view.dart';

class LandingView extends StatelessWidget {
  const LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.terrain_outlined, // Ikon merepresentasikan tanah/kontur
                size: 120,
                color: Color(0xFFAEC3B0), // aec3b0
              ),
              const SizedBox(height: 40),
              
              const Text(
                'Contour Checker',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEFF6E0),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              
              const Text(
                'Ubah foto pemandangan tanah biasa menjadi visualisasi peta kontur elevasi secara instan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF598392), // 598392
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 60),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAEC3B0),
                    foregroundColor: const Color(0xFF01161E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    // Berpindah ke HomeView dan menghapus LandingView dari tumpukan (tidak bisa di-back)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeView()),
                    );
                  },
                  child: const Text(
                    'START',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}