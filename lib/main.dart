// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';

/// Pages
import 'pages/calculator_page.dart';
import 'pages/edukasi_page.dart';
import 'pages/srs_page.dart';
import 'pages/cek_perkembangan_kehamilan_page.dart';
import 'pages/srs_history_page.dart';
import 'pages/profil_bunda_page.dart';
import 'pages/data_anak_page.dart';
import 'pages/rekap_menu_page.dart';

// --- Tambahkan import untuk inisialisasi tanggal ---
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // --- Inisialisasi format tanggal untuk locale Indonesia ---
  await initializeDateFormatting('id_ID', null);

  try {
    // Inisialisasi Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Aktifkan cache offline Realtime Database
    if (!kIsWeb) {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(20 * 1024 * 1024);
    }

    print('DEBUG MAIN: Firebase OK + RealtimeDB offline cache aktif');
  } catch (e) {
    print('DEBUG MAIN: Firebase error: $e');
  }

  // Menjalankan aplikasi
  runApp(const MyApp());
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
        scaffoldBackgroundColor: Colors.blue.shade50,
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

// --- PERBAIKAN: Fungsi navigasi dipindahkan ke luar kelas ---
void _go(BuildContext context, Widget page) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondary) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ),
  );
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

  String shortTitle(String title) {
    if (title.contains('Profil')) return 'Profil Bunda';
    if (title.contains('Kalkulator')) return 'Kalkulator';
    if (title.contains('Edukasi')) return 'Edukasi';
    if (title.contains('Prediksi') || title.contains('SRS'))
      return 'Prediksi SRS';
    if (title.contains('Kehamilan')) return 'Kehamilan';
    if (title.contains('Riwayat')) return 'Riwayat SRS';
    if (title.contains('Rekap')) return 'Rekap Data';
    if (title.contains('Bahasa')) return 'Bahasa';
    if (title.contains('Data Anak')) return 'Data Anak';
    return title;
  }

  String shortHint(String title) {
    if (title.contains('Profil')) return 'Data ibu';
    if (title.contains('Kalkulator')) return 'Hitung cepat';
    if (title.contains('Edukasi')) return 'Panduan ringkas';
    if (title.contains('Prediksi') || title.contains('SRS'))
      return 'Deteksi dini';
    if (title.contains('Kehamilan')) return 'Jurnal bumil';
    if (title.contains('Rekap')) return 'Ringkasan Statistik';
    if (title.contains('Bahasa')) return 'Fitur mendatang';
    if (title.contains('Data Anak')) return 'Anak per Ibu';
    return 'Buka fitur';
  }

  Future<void> _showPinDialog(BuildContext context) async {
    final pinController = TextEditingController();
    const String correctPin = '1234';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Masukkan PIN Admin'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'PIN',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              child: const Text('Masuk'),
              onPressed: () {
                if (pinController.text == correctPin) {
                  Navigator.of(context).pop();
                  _go(context, const SrsHistoryPage());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN salah!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> menuItems = [
      {
        "title": "Profil Bunda",
        "icon": Icons.person_outline,
        "page": const ProfilBundaPage(),
        "color": Colors.teal.shade700,
        "assetPath": "assets/Illustrations/rekap_pregnancy.jpg",
        "subTitle": "Data ibu",
      },
      {
        "title": "Kalkulator Gizi & BB",
        "icon": Icons.calculate_outlined,
        "page": const CalculatorPage(),
        "color": primaryColor.withOpacity(0.90),
        "assetPath": "assets/Illustrations/rekap_weight.jpg",
        "subTitle": "Hitung cepat",
      },
      {
        "title": "Edukasi Kesehatan",
        "icon": Icons.menu_book_outlined,
        "page": const EdukasiPage(),
        "color": Colors.blueGrey.shade700,
        "assetPath": null,
        "subTitle": "Panduan ringkas",
      },
      {
        "title": "Prediksi Stunting (SRS)",
        "icon": Icons.assessment_outlined,
        "page": const SrsPage(),
        "color": Colors.deepOrange.shade800,
        "assetPath": null,
        "subTitle": "Deteksi dini",
      },
      {
        "title": "Cek Kehamilan",
        "icon": Icons.pregnant_woman_outlined,
        "page": const CekPerkembanganKehamilanPage(),
        "color": Colors.pink.shade700,
        "assetPath": "assets/Illustrations/rekap_pregnancy.jpg",
        "subTitle": "Jurnal bumil",
      },
      {
        "title": "Data Anak",
        "icon": Icons.family_restroom_outlined,
        "page": const DataAnakPage(),
        "color": Colors.green.shade700,
        "assetPath": "assets/Illustrations/rekap_height.jpg",
        "subTitle": "Anak per Ibu",
      },
      {
        "title": "Rekap Data",
        "icon": Icons.donut_large_outlined,
        "page": const RekapMenuPage(),
        "color": Colors.purple.shade700,
        "assetPath": "assets/Illustrations/rekap_height.jpg",
        "subTitle": "Ringkasan Statistik",
      },
      {
        "title": "Riwayat Perhitungan SRS",
        "icon": Icons.history,
        "onTap": (BuildContext context) => _showPinDialog(context),
        "page": null,
        "color": Colors.indigo.shade700,
        "assetPath": null,
        "subTitle": "Lihat hasil lama",
      },
      {
        "title": "Ganti Bahasa",
        "icon": Icons.language_outlined,
        "page": null,
        "color": Colors.lightGreen.shade700,
        "assetPath": null,
        "subTitle": "Fitur mendatang",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.50), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                elevation: 0,
                backgroundColor: primaryColor,
                title: null,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.zero,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.78),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
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
                                    child: const Icon(
                                      Icons.volunteer_activism_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                "Pantau tumbuh kembang—gizi, MP-ASI, hingga kebersihan rumah tangga.",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.90),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _qa(
                                    context,
                                    label: 'Profil',
                                    icon: Icons.person_outline,
                                    color: Colors.white,
                                    onTap: () =>
                                        _go(context, const ProfilBundaPage()),
                                  ),
                                  _qa(
                                    context,
                                    label: 'Kalkulator',
                                    icon: Icons.calculate_outlined,
                                    color: Colors.white,
                                    onTap: () =>
                                        _go(context, const CalculatorPage()),
                                  ),
                                  _qa(
                                    context,
                                    label: 'SRS',
                                    icon: Icons.assessment_outlined,
                                    color: Colors.white,
                                    onTap: () => _go(context, const SrsPage()),
                                  ),
                                  _qa(
                                    context,
                                    label: 'Edukasi',
                                    icon: Icons.menu_book_outlined,
                                    color: Colors.white,
                                    onTap: () =>
                                        _go(context, const EdukasiPage()),
                                  ),
                                  _qa(
                                    context,
                                    label: 'Kehamilan',
                                    icon: Icons.pregnant_woman_outlined,
                                    color: Colors.white,
                                    onTap: () => _go(
                                      context,
                                      const CekPerkembanganKehamilanPage(),
                                    ),
                                  ),
                                  _qa(
                                    context,
                                    label: 'Anak',
                                    icon: Icons.family_restroom_outlined,
                                    color: Colors.white,
                                    onTap: () =>
                                        _go(context, const DataAnakPage()),
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
                      shortTitle(item["title"] as String),
                      item["title"] as String,
                      item["icon"] as IconData,
                      item["page"] as Widget?,
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

  Widget _qa(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.blue.shade800),
      label: Text(label, style: TextStyle(color: Colors.blue.shade800)),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: color.withOpacity(0.92),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(10, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  Widget _buildAssetMenuCard(
    BuildContext context,
    String shortTitleText,
    String originalTitle,
    IconData icon,
    Widget? page,
    Color color,
    String? subTitle,
    String? assetPath,
    Function(BuildContext)? onTapCallback,
  ) {
    final radius = BorderRadius.circular(16);
    final fallbackColor = color.withOpacity(0.85);

    return Material(
      elevation: 6,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (onTapCallback != null) {
            onTapCallback(context);
          } else if (page != null) {
            _go(context, page);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("$originalTitle akan datang!"),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        child: Ink(
          decoration: assetPath != null
              ? BoxDecoration(
                  borderRadius: radius,
                  image: DecorationImage(
                    image: AssetImage(assetPath),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.05),
                      BlendMode.darken,
                    ),
                  ),
                )
              : BoxDecoration(
                  borderRadius: radius,
                  color: fallbackColor,
                  gradient: LinearGradient(
                    colors: [fallbackColor, fallbackColor.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortTitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subTitle ?? shortHint(originalTitle),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
