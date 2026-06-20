import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Kontur',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      // ValueListenableBuilder akan "mendengarkan" perubahan pada Hive
      body: ValueListenableBuilder(
        valueListenable: Hive.box('historyBox').listenable(),
        builder: (context, Box box, _) {
          // Jika kosong, tampilkan pesan
          if (box.values.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Color(0xFF598392)),
                  SizedBox(height: 15),
                  Text(
                    'Belum ada riwayat pemindaian.',
                    style: TextStyle(color: Color(0xFF598392), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Jika ada isinya, tampilkan dalam bentuk ListView
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: box.length,
            itemBuilder: (context, index) {
              // Kita balik index-nya agar riwayat terbaru muncul di urutan paling atas
              int reversedIndex = box.length - 1 - index;
              Map data = box.getAt(reversedIndex);

              String rawDate = data['date']; 
              String dateFormatted = rawDate.split('.')[0]; // Membuang milidetik agar rapi
              String mode = data['mode'];
              Uint8List processedBytes = data['processed_bytes'];

              return Card(
                color: const Color(0xFF124559),
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  // Gambar thumbnail (Kotak sebelah kiri)
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      processedBytes,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Teks Mode
                  title: Text(
                    'Mode: ${mode.toUpperCase()}',
                    style: const TextStyle(
                      color: Color(0xFFEFF6E0), 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  // Teks Tanggal
                  subtitle: Text(
                    dateFormatted,
                    style: const TextStyle(color: Color(0xFFAEC3B0), fontSize: 13),
                  ),
                  // Tombol Hapus (Tong Sampah)
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      // Menampilkan dialog konfirmasi sebelum menghapus
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF01161E),
                          title: const Text('Hapus Riwayat?', style: TextStyle(color: Color(0xFFEFF6E0))),
                          content: const Text('Tindakan ini tidak bisa dibatalkan.', style: TextStyle(color: Color(0xFF598392))),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal', style: TextStyle(color: Color(0xFFAEC3B0))),
                            ),
                            TextButton(
                              onPressed: () {
                                box.deleteAt(reversedIndex); // Hapus data dari Hive
                                Navigator.pop(context); // Tutup dialog
                              },
                              child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}