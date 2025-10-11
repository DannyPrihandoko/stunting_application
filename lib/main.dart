// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/date_symbol_data_local.dart';

// Pages
import 'pages/calculator_page.dart';
import 'pages/edukasi_page.dart';
import 'pages/srs_page.dart';
import 'pages/cek_perkembangan_kehamilan_page.dart';
import 'pages/srs_history_page.dart';
import 'pages/profil_bunda_page.dart';
import 'pages/data_anak_page.dart';
import 'pages/rekap_menu_page.dart';
import 'pages/gizi_status_page.dart';
import 'pages/pin_entry_page.dart';
import 'pages/change_pin_page.dart';


// Providers
import 'providers/gizi_status_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(20 * 1024 * 1024);
    }
    print('DEBUG MAIN: Firebase OK + RealtimeDB offline cache aktif');
  } catch (e) {
    print('DEBUG MAIN: Firebase error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GiziStatusNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF64B5F6);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SITUNTAS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        useMaterial3: true,
        fontFamilyFallback: const ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans'],
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4,
        ),
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: Colors.blue.shade50,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilBundaPage(),
        '/calculator': (context) => const CalculatorPage(),
        '/edukasi': (context) => const EdukasiPage(),
        '/srs': (context) => const SrsPage(),
        '/kehamilan': (context) => const CekPerkembanganKehamilanPage(),
        '/data-anak': (context) => const DataAnakPage(),
        '/rekap-menu': (context) => const RekapMenuPage(),
        '/srs-history': (context) => const SrsHistoryPage(),
        '/gizi-status': (context) => const GiziStatusPage(),
        '/pin-entry': (context) => const PinEntryPage(),
        '/change-pin': (context) => const ChangePinPage(),
      },
    );
  }
}

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
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF64B5F6),
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

    // --- PERBAIKAN: Nama file disesuaikan dengan screenshot ---
    final List<Map<String, dynamic>> menuItems = [
      {
        "title": "Identitas Bunda",
        "subTitle": "Profil & Data Diri",
        "icon": Icons.person_outline,
        "route": "/profile",
        "color": Colors.teal.shade700,
        "assetPath": "assets/Illustrations/profil_bunda.jpg",
      },
      {
        "title": "Perhitungan Gizi",
        "subTitle": "Kalkulator Risiko Stunting",
        "icon": Icons.calculate_outlined,
        "route": "/calculator",
        "color": Colors.blue.shade700,
        "assetPath": "assets/Illustrations/calculator_gizi.png", // Ekstensi .png
      },
      {
        "title": "Materi Edukasi",
        "subTitle": "Panduan & Informasi",
        "icon": Icons.menu_book_outlined,
        "route": "/edukasi",
        "color": Colors.blueGrey.shade700,
        "assetPath": "assets/Illustrations/edukasi.png", // Ekstensi .png
      },
      {
        "title": "Prediksi Risiko (SRS)",
        "subTitle": "Deteksi Dini Stunting",
        "icon": Icons.assessment_outlined,
        "route": "/srs",
        "color": Colors.deepOrange.shade800,
        "assetPath": null, // Tidak ada aset spesifik, akan menggunakan warna
      },
      {
        "title": "Jurnal Kehamilan",
        "subTitle": "Pantau Perkembangan",
        "icon": Icons.pregnant_woman_outlined,
        "route": "/kehamilan",
        "color": Colors.pink.shade700,
        "assetPath": "assets/Illustrations/rekap_pregnancy.jpg",
      },
      {
        "title": "Manajemen Anak",
        "subTitle": "Tambah & Lihat Data",
        "icon": Icons.family_restroom_outlined,
        "route": "/data-anak",
        "color": Colors.green.shade700,
        "assetPath": "assets/Illustrations/rekap_height.jpg",
      },
      {
        "title": "Laporan Rekap",
        "subTitle": "Grafik & Statistik",
        "icon": Icons.donut_large_outlined,
        "route": "/rekap-menu",
        "color": Colors.purple.shade700,
        "assetPath": "assets/Illustrations/rekap_data.png", // Ekstensi .png
      },
      {
        "title": "Riwayat (Admin)",
        "subTitle": "Akses Data Perhitungan",
        "icon": Icons.history,
        "onTap": (BuildContext context) => Navigator.pushNamed(context, '/pin-entry'),
        "route": null,
        "color": Colors.indigo.shade700,
        "assetPath": null,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.78)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -6, top: 36,
                    child: Icon(Icons.pregnant_woman_outlined, size: 110, color: Colors.white.withOpacity(0.10)),
                  ),
                  Positioned(
                    left: -8, bottom: 8,
                    child: Icon(Icons.local_dining_outlined, size: 128, color: Colors.white.withOpacity(0.10)),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      // --- PERBAIKAN: Menggunakan Column dan Expanded untuk fleksibilitas ---
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44, height: 44,
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
                                    Text('${_timeGreeting()},', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    const Text('Halo, Pengguna SITUNTAS 👋', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Pantau tumbuh kembang—gizi, MP-ASI, hingga kebersihan rumah tangga.",
                            style: TextStyle(color: Colors.white.withOpacity(0.90), fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          // --- PERBAIKAN: Expanded agar Wrap bisa di-scroll jika perlu ---
                          Expanded(
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8, runSpacing: 8,
                                children: [
                                  _qa(context, label: 'Profil', icon: Icons.person_outline, onTap: () => Navigator.pushNamed(context, '/profile')),
                                  _qa(context, label: 'Kalkulator', icon: Icons.calculate_outlined, onTap: () => Navigator.pushNamed(context, '/calculator')),
                                  _qa(context, label: 'SRS', icon: Icons.assessment_outlined, onTap: () => Navigator.pushNamed(context, '/srs')),
                                  _qa(context, label: 'Edukasi', icon: Icons.menu_book_outlined, onTap: () => Navigator.pushNamed(context, '/edukasi')),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: menuItems.map((item) {
                return _buildAssetMenuCard(
                  context,
                  item["title"] as String,
                  item["icon"] as IconData,
                  item["route"] as String?,
                  item["color"] as Color,
                  item["subTitle"] as String?,
                  item["assetPath"] as String?,
                  item["onTap"] as Function(BuildContext)?,
                );
              }).toList(),
            ),
          ),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                width: double.infinity,
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

  Widget _qa(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.blue.shade800),
      label: Text(label, style: TextStyle(color: Colors.blue.shade800)),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.92),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(10, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  Widget _buildAssetMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    String? route,
    Color color,
    String? subTitle,
    String? assetPath,
    Function(BuildContext)? onTapCallback,
  ) {
    final radius = BorderRadius.circular(16);

    return Material(
      elevation: 6,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (onTapCallback != null) {
            onTapCallback(context);
          } else if (route != null) {
            Navigator.pushNamed(context, route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$title akan datang!"), duration: const Duration(seconds: 1)),
            );
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: color.withOpacity(0.85),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (assetPath != null)
                Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: color.withOpacity(0.2));
                  },
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 28, color: color),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1,1))],
                          ),
                        ),
                        if (subTitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subTitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.95),
                              shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}