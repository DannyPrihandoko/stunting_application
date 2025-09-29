import 'package:flutter/material.dart';

class EdukasiPage extends StatelessWidget {
  const EdukasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edukasi Stunting"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionCard(
            title: "Apa itu Stunting?",
            children: [
              "Stunting adalah kondisi gagal tumbuh pada anak akibat kekurangan gizi kronis dan infeksi berulang.",
              "Dampaknya: tinggi badan tidak sesuai usia, perkembangan kognitif & imunitas bisa terganggu.",
            ],
          ),
          _SectionCard(
            title: "Gejala Umum",
            children: [
              "Pertumbuhan tinggi badan lambat.",
              "Nafsu makan kurang, lebih sering sakit.",
              "Perkembangan motorik & bicara terlambat.",
            ],
          ),
          _SectionCard(
            title: "Pencegahan (1000 HPK)",
            children: [
              "Ibu hamil: pemeriksaan rutin, tablet tambah darah, makanan bergizi seimbang.",
              "ASI eksklusif 0–6 bulan, MP-ASI bergizi mulai 6 bulan.",
              "Imunisasi, kebersihan (CTPS), sanitasi & air bersih.",
            ],
          ),
          _SectionCard(
            title: "Contoh Menu MP-ASI Sederhana",
            children: [
              "Bubur beras + telur + sayur hijau.",
              "Nasi tim + ayam/ikan + wortel/labuh siam.",
              "Buah potong (pisang, pepaya) sebagai selingan.",
            ],
          ),
          _SectionCard(
            title: "Mitos vs Fakta Singkat",
            children: [
              "Mitos: Stunting cuma soal pendek. Fakta: juga memengaruhi perkembangan otak & imunitas.",
              "Mitos: Nanti akan mengejar sendiri. Fakta: perlu intervensi gizi & kesehatan sedini mungkin.",
            ],
          ),
          SizedBox(height: 8),
          _Callout(),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<String> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...children.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• "),
                    Expanded(child: Text(t)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: const Text(
        "Tips cepat: Pantau tinggi & berat badan anak secara berkala dengan kurva WHO, "
        "pastikan asupan protein hewani setiap hari, perbanyak sayur-buah, dan konsultasi "
        "ke nakes bila grafik pertumbuhan melambat.",
        textAlign: TextAlign.center,
      ),
    );
  }
}
