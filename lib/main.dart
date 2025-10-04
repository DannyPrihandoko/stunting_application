import 'package:flutter/material.dart';
import 'dart:async';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Pages
import 'pages/calculator_page.dart';
import 'pages/edukasi_page.dart';
import 'pages/srs_page.dart';
import 'pages/cek_perkembangan_kehamilan_page.dart';
import 'package:stunting_application/pages/srs_history_page.dart';

void main() async {
  print('DEBUG MAIN: start');
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('DEBUG MAIN: Firebase OK');
  } catch (e) {
    print('DEBUG MAIN: Firebase error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF64B5F6); // Warna biru pastel lembut

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SITUNTAS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        useMaterial3: true,
        fontFamilyFallback: const [
          'Roboto',
          'Noto Sans Symbols 2',
          'Noto Sans',
        ],
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4,
        ),
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: Colors.blue.shade50, // Background biru pastel
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------------- SPLASH SCREEN ----------------
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
      backgroundColor: Color(0xFF64B5F6), // Biru pastel untuk background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care_outlined, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "SITUNTAS",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text("Sistem Deteksi Stunting Tuntas", style: TextStyle(fontSize: 18, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

// ---------------- HOME PAGE ----------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h >= 4 && h < 11) return 'Selamat pagi';
    if (h >= 11 && h < 15) return 'Selamat siang';
    if (h >= 15 && h < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;

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
        "title": "Riwayat Perhitungan SRS",
        "icon": Icons.history,
        "page": const SrsHistoryPage(),
        "color": Colors.indigo.shade700,
        "subTitle": "Lihat Hasil Lama",
      },
      {
        "title": "Ganti Bahasa",
        "icon": Icons.language_outlined,
        "page": null,
        "color": Colors.lightGreen.shade700,
        "subTitle": "Fitur mendatang",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.blue.shade50, // Background biru muda
      body: Stack(
        children: [
          // === BACKGROUND AWAN ===
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.5), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              // 1. Header / Greeting
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                elevation: 0,
                backgroundColor: primaryColor,
                title: null, // << hapus tulisan "Fitur Utama"
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.zero,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient dasar
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withOpacity(0.78)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Ikon dekoratif samar
                      Positioned(
                        right: -6,
                        top: 36,
                        child: Icon(
                          Icons.pregnant_woman_outlined,
                          size: 110,
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      Positioned(
                        left: -8,
                        bottom: 8,
                        child: Icon(
                          Icons.local_dining_outlined,
                          size: 128,
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      // Konten sapaan
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Icon(Icons.volunteer_activism_outlined, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_timeGreeting()},',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Halo, Pengguna SITUNTAS 👋',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Pantau tumbuh kembang si kecil—mulai dari gizi, MP-ASI, hingga kebersihan rumah tangga.",
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                              ),
                              const SizedBox(height: 12),

                              // Quick Actions
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      // Add your quick action logic here
                                    },
                                    child: const Text("Quick Action 1"),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Add your quick action logic here
                                    },
                                    child: const Text("Quick Action 2"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Grid Feature Cards
              SliverPadding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: menuItems.map((item) {
                    return _buildFeatureCard(
                      context,
                      item["title"],
                      item["icon"],
                      item["page"],
                      item["color"],
                      item["subTitle"],
                    );
                  }).toList(),
                ),
              ),

              // 3. Footer
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
        ],
      ),
    );
  }

  // -------- Feature Card --------
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget? page,
    Color color,
    String? subTitle,
  ) {
    return InkWell(
      onTap: () {
        if (page == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$title akan datang!"),
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => page,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeOut;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          );
        }
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  subTitle ??
                      (title.contains("Kalkulator")
                          ? "Hitung Cepat"
                          : title.contains("Edukasi")
                              ? "Panduan Lengkap"
                              : title.contains("Stunting")
                                  ? "Deteksi Dini"
                                  : title.contains("Kehamilan")
                                      ? "Jurnal Bumil"
                                      : "Pengaturan"),
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
