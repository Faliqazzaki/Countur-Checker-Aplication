import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/custom_action_button.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Variabel untuk menyimpan file gambar yang dipilih
  File? _selectedImage;
  
  // Inisialisasi ImagePicker
  final ImagePicker _picker = ImagePicker();

  // Fungsi utama untuk mengambil gambar
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Kompresi sedikit agar tidak terlalu berat saat dikirim ke server nanti
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil gambar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contour Checker',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Area Preview Gambar (Dinamis)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF124559).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF598392), width: 2),
                ),
                // Logika kondisional: Jika gambar ada, tampilkan. Jika tidak, tampilkan placeholder.
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover, // Memastikan gambar memenuhi kotak dengan rapi
                          width: double.infinity,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, size: 80, color: Color(0xFF598392)),
                          SizedBox(height: 10),
                          Text(
                            'Pilih atau ambil foto area tanah',
                            style: TextStyle(color: Color(0xFF598392)),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Baris Tombol Aksi (Kamera & Galeri)
            Row(
              children: [
                Expanded(
                  child: CustomActionButton(
                    icon: Icons.camera_alt,
                    title: 'Kamera',
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: CustomActionButton(
                    icon: Icons.photo_library,
                    title: 'Galeri',
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}