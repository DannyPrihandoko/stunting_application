import 'package:flutter/material.dart';
import 'dart:async';

// IMPORT FILE TERPISAH
import 'pages/calculator_page.dart';
import 'pages/edukasi_page.dart';
import 'pages/srs_page.dart';
import 'pages/cek_perkembangan_kehamilan_page.dart'; // <-- halaman baru

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SITUNTAS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamilyFallback: const ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans'],
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          displayMedium: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
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
    Timer(const Duration(seconds: 3), () {
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
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "SITUNTAS",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Sistem Deteksi Stunting Tuntas",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- HOME PAGE ----------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SITUNTAS - Sistem Deteksi Stunting Tuntas"),
      ),
      body: Column(
        children: [
          // ---------- HEADER ---------- 
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.green.shade100,
            child: const Text(
              "Selamat Datang di Aplikasi SITUNTAS",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          // ---------- KONTEN (CARD BUTTONS) ----------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildCardButton(context, Icons.calculate, "Kalkulator", const CalculatorPage()),
                  _buildCardButton(context, Icons.book, "Edukasi", const EdukasiPage()),
                  _buildCardButton(context, Icons.assessment, "Prediksi Stunting (SRS)", const SrsPage()),
                  _buildCardButton(context, Icons.pregnant_woman, "Cek Perkembangan Kehamilan", const CekPerkembanganKehamilanPage()),
                  _buildCardButton(context, Icons.pageview, "Halaman 5", const Page5()),
                  _buildCardButton(context, Icons.library_books, "Halaman 6", const Page6()),
                ],
              ),
            ),
          ),

          // ---------- FOOTER ---------- 
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.green.shade100,
            child: const Text(
              "© 2025 SITUNTAS - Sistem Deteksi Stunting Tuntas",
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardButton(BuildContext context, IconData icon, String title, Widget page) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: Colors.green), // Tampilkan ikon sesuai dengan parameter
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- HALAMAN LAIN (placeholder) ----------------
class Page5 extends StatelessWidget {
  const Page5({super.key});
  @override
  Widget build(BuildContext context) =>
      _pageTemplate("Halaman 5 - SITUNTAS", Colors.blue.shade100);
}

class Page6 extends StatelessWidget {
  const Page6({super.key});
  @override
  Widget build(BuildContext context) =>
      _pageTemplate("Halaman 6 - SITUNTAS", Colors.purple.shade100);
}

// ---------------- TEMPLATE HALAMAN ----------------
Widget _pageTemplate(String title, Color color) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
    ),
    body: Container(
      color: color.withValues(alpha: 0.1 * 255),  // Mengganti withOpacity dengan withValues
      child: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
