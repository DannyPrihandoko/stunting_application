import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Import untuk menggunakan ImageFilter

class EdukasiPage extends StatelessWidget {
  const EdukasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return DefaultTabController(
      length: 6, // Jumlah tab sekarang menjadi 6
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        appBar: AppBar(
          title: const Text('Edukasi Stunting'),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4,
          bottom: const TabBar(
            isScrollable: true, // Membuat tab bisa digeser
            tabAlignment: TabAlignment.start, // Rata kiri jika bisa di-scroll
            tabs: [
              Tab(text: 'Materi 1'),
              Tab(text: 'Materi 2'),
              Tab(text: 'Materi 3'),
              Tab(text: 'Materi 4'),
              Tab(text: 'Materi 5'),
              Tab(text: 'Materi 6'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ImageMateriTab(materiNumber: 1),
            _ImageMateriTab(materiNumber: 2),
            _ImageMateriTab(materiNumber: 3),
            _ImageMateriTab(materiNumber: 4),
            _ImageMateriTab(materiNumber: 5),
            _ImageMateriTab(materiNumber: 6),
          ],
        ),
      ),
    );
  }
}

// ========================= WIDGET PEMBUKA GAMBAR (Tampilan Penuh) =========================
class _FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const _FullScreenImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Latar belakang utama transparan
      body: Stack(
        children: [
          // Lapisan Latar Belakang Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.6), // Overlay gelap tipis
              ),
            ),
          ),
          // Konten Utama (Gambar dan Tombol Tutup)
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Hero(
                      tag: imagePath,
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.8,
                        maxScale: 4.0,
                        // === PERBAIKAN UTAMA DI SINI ===
                        // Mengizinkan gambar untuk dirender di luar batas aslinya saat di-zoom.
                        clipBehavior: Clip.none,
                        child: Image.asset(imagePath),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========================= WIDGET FLEKSIBEL UNTUK SETIAP TAB MATERI =========================
class _ImageMateriTab extends StatefulWidget {
  final int materiNumber;

  const _ImageMateriTab({required this.materiNumber});

  @override
  State<_ImageMateriTab> createState() => _ImageMateriTabState();
}

class _ImageMateriTabState extends State<_ImageMateriTab> {
  late Future<List<String>> _imagePathsFuture;

  @override
  void initState() {
    super.initState();
    _imagePathsFuture = _loadAssetImages();
  }

  // Fungsi untuk memuat semua gambar dari folder aset secara dinamis
  Future<List<String>> _loadAssetImages() async {
    final List<String> paths = [];
    int i = 1;
    while (true) {
      final path = 'assets/edukasi/tab${widget.materiNumber}/$i.jpg';
      try {
        // Coba muat aset. Jika gagal, akan melempar exception.
        await DefaultAssetBundle.of(context).load(path);
        paths.add(path);
        i++;
      } catch (_) {
        // Hentikan loop jika gambar tidak ditemukan
        break;
      }
    }
    return paths;
  }

  void _showFullScreenImage(String imagePath) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FullScreenImageViewer(imagePath: imagePath),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _imagePathsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Materi Belum Tersedia',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                   const SizedBox(height: 8),
                  Text(
                    'Pastikan folder "assets/edukasi/tab${widget.materiNumber}/" berisi gambar.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final imagePaths = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: imagePaths.length,
          itemBuilder: (context, index) {
            final path = imagePaths[index];
            return GestureDetector(
              onTap: () => _showFullScreenImage(path),
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Hero(
                  tag: path,
                  child: Image.asset(path, fit: BoxFit.contain, width: double.infinity),
                ),
              ),
            );
          },
        );
      },
    );
  }
}