import 'package:flutter/material.dart';
import 'dart:async';

// PENTING: Dua import di bawah ini yang membutuhkan setup Firebase CLI yang benar.
// Pastikan kamu sudah menjalankan 'flutter pub get' dan 'flutterfire configure'
// Jika ada error di sini, itu berarti setup Firebase-mu belum selesai/benar.
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // File ini dihasilkan oleh 'flutterfire configure'

// IMPORT FILE TERPISAH (Kelas-kelas ini diaktifkan dan diasumsikan sudah ada di folder pages/)
import 'pages/calculator_page.dart';
import 'pages/edukasi_page.dart';
import 'pages/srs_page.dart'; // Ini halaman SRS yang akan mengirim data ke Realtime Database
import 'pages/cek_perkembangan_kehamilan_page.dart';

// UBAH main() MENJADI ASYNC DAN TAMBAHKAN INIALISASI FIREBASE
void main() async {
  // Pastikan Flutter siap sebelum menginisialisasi Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase dengan opsi spesifik untuk platform saat ini
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

// ---------------- APP SETUP ----------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengubah seedColor menjadi warna oranye/coral yang lebih profesional
    const Color primaryCoral = Color(0xFFFF7043);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SITUNTAS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryCoral),
        useMaterial3: true,
        fontFamilyFallback: const [
          'Roboto',
          'Noto Sans Symbols 2',
          'Noto Sans',
        ],
        // Tema AppBar untuk halaman selain home
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryCoral,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4, // Menambahkan sedikit shadow
        ),
        // Menetapkan warna utama untuk aplikasi
        primaryColor: primaryCoral,
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------------- SPLASH SCREEN (TETAP SAMA) ----------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      // Durasi dikurangi
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFF7043), // Menggunakan warna coral
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care_outlined, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "SITUNTAS",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Sistem Deteksi Stunting Tuntas",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- HOME PAGE (Redesigned) ----------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;

    // Data menu dengan ikon dan tujuan yang lebih terstruktur
    final List<Map<String, dynamic>> menuItems = [
      {
        "title": "Kalkulator Gizi & BB",
        "icon": Icons.calculate_outlined,
        "page": const CalculatorPage(),
        "color": primaryColor.withOpacity(0.9),
      },
      {
        "title": "Edukasi Kesehatan",
        "icon": Icons.menu_book_outlined,
        "page": const EdukasiPage(),
        "color": Colors.blueGrey.shade700,
      },
      {
        "title": "Prediksi Stunting (SRS)",
        "icon": Icons.assessment_outlined,
        "page": const SrsPage(),
        "color": Colors.deepOrange.shade800,
      },
      {
        "title": "Cek Kehamilan",
        "icon": Icons.pregnant_woman_outlined,
        "page": const CekPerkembanganKehamilanPage(),
        "color": Colors.pink.shade700,
      },
      {
        "title": "Ganti Bahasa",
        "icon": Icons.language_outlined,
        "page": null, // Placeholder untuk fitur yang akan datang
        "color": Colors.lightGreen.shade700,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // 1. Custom Header / Greeting Area
          SliverAppBar(
            expandedHeight: screenWidth * 0.5,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              centerTitle: false,
              title: Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: const Text(
                  'Fitur Utama',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_pin_circle_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Halo, Pengguna SITUNTAS!",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Pantau tumbuh kembang si kecil dengan mudah di sini.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Konten (Grid Feature Cards)
          SliverPadding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              // Menggunakan rasio aspek 1.0 (Square) untuk memberi ruang vertikal yang cukup
              childAspectRatio: 1.0,
              children: menuItems.map((item) {
                return _buildFeatureCard(
                  context,
                  item["title"],
                  item["icon"],
                  item["page"],
                  item["color"],
                );
              }).toList(),
            ),
          ),

          // 3. Footer (Diletakkan di bagian bawah scroll view)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                width: double.infinity,
                color: Colors.white,
                child: const Text(
                  "© 2025 SITUNTAS - Sistem Deteksi Stunting Tuntas",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk kartu fitur
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget? page,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        if (page == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Fitur ganti bahasa akan datang!"),
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => page,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOut;
                    var tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
            ),
          );
        }
      },
      child: Card(
        // Desain kartu dengan elevasi dan sudut membulat
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white, // Background putih di dalam card
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ikon dengan warna yang lebih menonjol
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 10),
                // Judul fitur
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // Sub-judul opsional (dapat ditambahkan jika perlu)
                Text(
                  title.contains("Kalkulator")
                      ? "Hitung Cepat"
                      : title.contains("Edukasi")
                      ? "Panduan Lengkap"
                      : title.contains("Stunting")
                      ? "Deteksi Dini"
                      : title.contains("Kehamilan")
                      ? "Jurnal Bumil"
                      : "Pengaturan",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
