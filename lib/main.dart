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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        // fallback font agar simbol matematika tersedia
        fontFamilyFallback: const ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans'],
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          displayMedium: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          displaySmall: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          headlineLarge: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          headlineMedium: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          headlineSmall: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          titleLarge: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          titleMedium: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          titleSmall: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          bodyLarge: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          bodyMedium: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          bodySmall: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          labelLarge: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          labelMedium: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
          labelSmall: TextStyle(fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans']),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
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
      backgroundColor: Colors.orange,
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
            color: Colors.orange.shade200,
            child: const Text(
              "Selamat Datang di Aplikasi SITUNTAS",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          // ---------- KONTEN (BUTTON GRID) ----------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildSquareButton(context, "Kalkulator", const CalculatorPage()),
                  _buildSquareButton(context, "Edukasi", const EdukasiPage()),
                  _buildSquareButton(context, "Prediksi Stunting (SRS)", const SrsPage()),
                  _buildSquareButton(context, "Cek Perkembangan Kehamilan", const CekPerkembanganKehamilanPage()),
                  _buildSquareButton(context, "Halaman 5", const Page5()),
                  _buildSquareButton(context, "Halaman 6", const Page6()),
                ],
              ),
            ),
          ),

          // ---------- FOOTER ----------
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.orange.shade200,
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

  Widget _buildSquareButton(BuildContext context, String title, Widget page) {
    return AspectRatio(
      aspectRatio: 1,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
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
      _pageTemplate("Halaman 5 - SITUNTAS", Colors.purple);
}

class Page6 extends StatelessWidget {
  const Page6({super.key});
  @override
  Widget build(BuildContext context) =>
      _pageTemplate("Halaman 6 - SITUNTAS", Colors.teal);
}

// ---------------- TEMPLATE HALAMAN ----------------
Widget _pageTemplate(String title, Color color) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
    ),
    body: Container(
      color: color.withOpacity(0.1),
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
