import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../widgets/custom_action_button.dart';
import 'package:hive/hive.dart';
import 'history_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  File? _selectedImage;
  Uint8List? _processedImage;
  bool _isLoading = false;

  // Variabel baru untuk menyimpan mode yang dipilih (default: 'contour')
  String _selectedMode = 'contour';

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
          _processedImage = null; // Reset hasil AI jika memilih foto baru
          _selectedMode = 'contour'; // Kembalikan ke opsi default
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil gambar: $e");
    }
  }

  // 2. Fungsi mengirim gambar dan opsi mode ke Backend Python
  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // PENTING: Gunakan 10.0.2.2 untuk emulator, atau IP Laptop untuk HP fisik
      final uri = Uri.parse('http://192.168.1.3:8000/process-image/');

      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedImage!.path),
      );

      // Mengirimkan mode yang dipilih ke Python
      request.fields['mode'] = _selectedMode;

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        setState(() {
          _processedImage = responseData;
        });
      } else {
        _showErrorSnackBar(
          'Gagal memproses gambar. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showErrorSnackBar(
        'Tidak dapat terhubung ke server. Pastikan server Python menyala.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk mereset tampilan agar bisa mencoba gambar lain dengan cepat
  void _resetView() {
    setState(() {
      _selectedImage = null;
      _processedImage = null;
      _selectedMode = 'contour';
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFAEC3B0),
        action: SnackBarAction(
          label: 'OK',
          textColor: const Color(0xFF01161E),
          onPressed: () {},
        ),
      ),
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
        actions: [
          // Tombol Reset
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFAEC3B0)),
              tooltip: 'Coba Gambar Lain',
              onPressed: _resetView,
            ),
          // Tombol Riwayat (Ditambahkan di sini)
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFFAEC3B0)),
            tooltip: 'Lihat Riwayat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryView()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // --- AREA PREVIEW GAMBAR ---
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
                        child: CircularProgressIndicator(
                          color: Color(0xFFAEC3B0),
                        ),
                      )
                    : _processedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(
                          _processedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : _selectedImage != null
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
                          Icon(
                            Icons.terrain_outlined,
                            size: 80,
                            color: Color(0xFF598392),
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Pilih atau ambil foto area tanah',
                            style: TextStyle(
                              color: Color(0xFF598392),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // --- MENU PILIHAN GAYA OUTPUT (Hanya muncul sebelum diproses) ---
            if (_selectedImage != null && _processedImage == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'contour', label: Text('Garis')),
                    ButtonSegment(
                      value: 'topographic',
                      label: Text('Peta'),
                    ), // MODE PETA TOPOGRAFI
                  ],
                  selected: {_selectedMode},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedMode = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected))
                        return const Color(0xFFAEC3B0);
                      return const Color(0xFF124559);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected))
                        return const Color(0xFF01161E);
                      return const Color(0xFFEFF6E0);
                    }),
                  ),
                ),
              ),

            // --- TOMBOL PROSES AI ---
            if (_selectedImage != null && _processedImage == null)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAEC3B0),
                    foregroundColor: const Color(0xFF01161E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _isLoading ? null : _processImage,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'PROSES GAMBAR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // Jarak tambahan jika tombol proses hilang
            if (_processedImage != null) const SizedBox(height: 15),

            // --- TOMBOL KAMERA & GALERI ---
            if (_processedImage ==
                null) // Sembunyikan tombol ini jika AI sudah selesai memproses
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

            // --- TOMBOL SIMPAN HASIL (Hanya muncul jika sudah ada hasil AI) ---
            if (_processedImage != null)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF124559),
                    foregroundColor: const Color(0xFFEFF6E0),
                    side: const BorderSide(color: Color(0xFFAEC3B0), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    // Memanggil kotak penyimpanan Hive
                    var box = Hive.box('historyBox');

                    // Menyimpan data sebagai Map (Kamus)
                    box.add({
                      'date': DateTime.now().toString(),
                      'mode': _selectedMode,
                      'original_path': _selectedImage!.path,
                      'processed_bytes':
                          _processedImage, // Uint8List langsung disimpan!
                    });

                    _showSuccessSnackBar(
                      "Hasil berhasil disimpan ke dalam Riwayat!",
                    );
                  },
                  icon: const Icon(Icons.save_alt),
                  label: const Text(
                    'SIMPAN KE RIWAYAT',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
