import 'dart:io';
import 'dart:typed_data'; // Untuk menangani format byte gambar dari API
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Package untuk HTTP Request
import '../widgets/custom_action_button.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  File? _selectedImage;
  Uint8List? _processedImage; // Menyimpan gambar hasil dari AI
  bool _isLoading = false; // Status loading saat menunggu AI bekerja

  final ImagePicker _picker = ImagePicker();

  // 1. Fungsi mengambil gambar dari Kamera / Galeri
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _processedImage = null; // Reset hasil sebelumnya jika milih foto baru
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil gambar: $e");
    }
  }

  // 2. Fungsi mengirim gambar ke Backend Python
  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // PENTING: IP Address Server
      final uri = Uri.parse('http://10.10.80.41:8000/process-image/');
      
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        // Ambil gambar balasan dari server dalam bentuk bytes
        var responseData = await response.stream.toBytes();
        setState(() {
          _processedImage = responseData;
        });
      } else {
        _showErrorSnackBar('Gagal memproses gambar. Server mengembalikan status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Tidak dapat terhubung ke server. Pastikan server Python menyala.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
            const SizedBox(height: 10),
            
            // Area Preview Gambar
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF124559).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF598392), width: 2),
                ),
                child: _isLoading 
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFAEC3B0)),
                    )
                  : _processedImage != null
                      // Menampilkan hasil dari AI
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(
                            _processedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : _selectedImage != null
                          // Menampilkan foto asli sebelum diproses
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
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
            const SizedBox(height: 20),

            // Tombol Proses AI (Hanya muncul jika gambar sudah dipilih dan belum diproses)
            if (_selectedImage != null && _processedImage == null)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAEC3B0),
                    foregroundColor: const Color(0xFF01161E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isLoading ? null : _processImage,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'PROSES KONTUR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            
            const SizedBox(height: 15),
            
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
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}