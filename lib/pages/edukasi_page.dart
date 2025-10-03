import 'package:flutter/material.dart';
import 'calculator_page.dart';

class EdukasiPage extends StatelessWidget {
  const EdukasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text("Edukasi Stunting"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.calculate_outlined),
        label: const Text('Buka Kalkulator'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalculatorPage()),
          );
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(primary: primary)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            sliver: SliverList.list(
              children: [
                _IntroCard(primary: primary),

                const SizedBox(height: 12),
                _SectionTitle(
                  icon: Icons.health_and_safety_outlined,
                  color: Colors.teal,
                  title: "Faktor Risiko Utama",
                  subtitle:
                      "Ringkasan tematik dari literatur 2021–2025 (maternal–bayi–infeksi–rumah tangga–layanan).",
                ),

                // Maternal/Pranatal
                const _RiskBlock(
                  color: Color(0xFF26A69A),
                  icon: Icons.pregnant_woman_outlined,
                  title: "Maternal & Pranatal",
                  bullets: [
                    "KEK pada remaja/wanita usia subur → risiko BBLR meningkat.",
                    "Anemia pada kehamilan menurunkan suplai oksigen ke janin.",
                    "Asupan energi & protein kurang (mis. <70% kebutuhan) → panjang lahir rendah.",
                    "Infeksi ibu (malaria/TB/kronis) mengganggu pertumbuhan janin.",
                    "Usia ibu remaja (<20 th) & jarak hamil <24 bln meningkatkan risiko.",
                    "Kunjungan ANC tidak adekuat (<4 kali) mengurangi peluang suplementasi & deteksi dini.",
                    "Pendidikan & status sosioekonomi ibu rendah → keterbatasan akses pangan bergizi.",
                    "Paparan asap rokok & beban kerja berat saat hamil memperburuk risiko.",
                  ],
                ),

                // Bayi & pemberian makan
                const _RiskBlock(
                  color: Color(0xFF7E57C2),
                  icon: Icons.child_care_outlined,
                  title: "Bayi & Pemberian Makan",
                  bullets: [
                    "IMD & kolostrum: terlambat/tidak mendapat → naik risiko infeksi & stunting.",
                    "ASI eksklusif 0–6 bln melindungi dari stunting; tanpa ASI eksklusif → risiko ~2x lipat.",
                    "MP-ASI tepat waktu (mulai 6 bln), aman, cukup kualitas & kuantitas.",
                    "Risiko naik bila MP-ASI terlambat (>8 bln) atau terlalu dini (<4 bln).",
                    "Diversitas pangan rendah & minim protein hewani → defisiensi mikronutrien.",
                    "Frekuensi makan kurang & kepadatan energi rendah (bubur terlalu encer).",
                    "Pemberian makan tidak responsif (dipaksa/diabaikan) menurunkan asupan efektif.",
                  ],
                ),

                // Penyakit infeksi
                const _RiskBlock(
                  color: Color(0xFFFF7043),
                  icon: Icons.sick_outlined,
                  title: "Penyakit & Infeksi Berulang",
                  bullets: [
                    "Diare berulang, ISPA, TB, malaria, & cacingan → ganggu penyerapan & naikkan kebutuhan energi.",
                    "Environmental Enteric Dysfunction (EED) & inflamasi kronis menghambat pertumbuhan linier.",
                    "Anoreksia saat sakit menurunkan asupan; siklus gizi buruk ↔ infeksi memperparah risiko.",
                  ],
                ),

                // Rumah tangga & WASH
                const _RiskBlock(
                  color: Color(0xFF42A5F5),
                  icon: Icons.house_outlined,
                  title: "Rumah Tangga & WASH",
                  bullets: [
                    "Akses air bersih & sanitasi layak menurunkan diare & risiko stunting.",
                    "Perilaku higiene (CTPS) & pengolahan air → protektif.",
                    "Kepadatan hunian (crowding) & kemiskinan memicu ketidakamanan pangan.",
                  ],
                ),

                // Layanan & faktor struktural
                const _RiskBlock(
                  color: Color(0xFF66BB6A),
                  icon: Icons.local_hospital_outlined,
                  title: "Akses Layanan & Faktor Struktural",
                  bullets: [
                    "Cakupan ANC, imunisasi, suplementasi mikro, manajemen penyakit anak → protektif.",
                    "Krisis ekonomi/konflik/iklim mengganggu ketahanan pangan & layanan kesehatan.",
                  ],
                ),

                const SizedBox(height: 16),
                _SectionTitle(
                  icon: Icons.lightbulb_outline,
                  color: Colors.amber.shade700,
                  title: "Langkah Pencegahan (1000 HPK)",
                  subtitle:
                      "Mulai sejak pra-kehamilan, masa hamil, menyusui, hingga anak usia 2 tahun.",
                ),
                const _ChipList(
                  chips: [
                    "Pra-konsepsi: tablet Fe-folat, gizi seimbang, stop rokok.",
                    "Hamil: ANC rutin, TTD, protein hewani harian, batasi kerja berat.",
                    "0–6 bln: ASI eksklusif & IMD/kolostrum.",
                    "≥6 bln: MP-ASI bergizi, variasi + frekuensi sesuai usia.",
                    "Imunisasi lengkap, obat cacing sesuai program.",
                    "WASH: air bersih, jamban sehat, CTPS.",
                    "Pemantauan TB/U & BB/U berkala di posyandu.",
                  ],
                ),

                const SizedBox(height: 12),
                _ColoredCard(
                  color: Colors.deepOrange,
                  title: "Panduan Singkat MP-ASI",
                  bullets: const [
                    "Waktu: mulai 6 bln. Frekuensi minimal: 6–8 bln (≥2×/hari), 9–23 bln (≥3×/hari) + selingan.",
                    "Tekstur: bertahap dari lumat → cincang halus → tekstur keluarga.",
                    "Kualitas: wajib protein hewani tiap hari (telur/ikan/ayam/hati), tambah kacang & sayur-buah.",
                    "Energi: hindari bubur terlalu encer; pakai santan/minyak/ghee secukupnya untuk kepadatan.",
                    "Keamanan: cuci tangan, alat makan bersih, masak matang.",
                    "Responsif: peka sinyal lapar/kenyang, sabar & tidak memaksa.",
                  ],
                ),

                const SizedBox(height: 12),
                _MitosFakta(),

                const SizedBox(height: 12),
                const _WarningSigns(),

                const SizedBox(height: 16),
                _Callout(primary: primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
 * HEADER
 * ========================= */
class _Header extends StatelessWidget {
  final Color primary;
  const _Header({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: 18,
            child: Icon(
              Icons.pregnant_woman_outlined,
              size: 120,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          Positioned(
            left: -10,
            bottom: -6,
            child: Icon(
              Icons.local_dining_outlined,
              size: 140,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Edukasi Stunting",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Materi ringkas: faktor risiko, pencegahan 1000 HPK, MP-ASI, WASH, & layanan kesehatan.",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
 * INTRO CARD
 * ========================= */
class _IntroCard extends StatelessWidget {
  final Color primary;
  const _IntroCard({required this.primary});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.info_outline,
      color: primary,
      title: "Apa itu Stunting?",
      children: const [
        "Stunting adalah gagal tumbuh kronis pada anak (terutama 1000 HPK) akibat asupan gizi tidak adekuat & infeksi berulang.",
        "Dampak: tinggi/umur rendah, gangguan perkembangan kognitif & imunitas, serta risiko intergenerasional (siklus antargenerasi).",
      ],
    );
  }
}

/* =========================
 * RISK BLOCK (colored)
 * ========================= */
class _RiskBlock extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final List<String> bullets;

  const _RiskBlock({
    required this.color,
    required this.icon,
    required this.title,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.08), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...bullets.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================
 * SECTION TITLE
 * ========================= */
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  const _SectionTitle({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
 * INFO CARD (bullet generic)
 * ========================= */
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> children;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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

/* =========================
 * CHIPS LIST
 * ========================= */
class _ChipList extends StatelessWidget {
  final List<String> chips;
  const _ChipList({required this.chips});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: -6,
      children: chips
          .map(
            (c) => Chip(
              label: Text(c),
              backgroundColor: Colors.orange.shade50,
              side: BorderSide(color: Colors.orange.shade200),
              avatar: const Icon(
                Icons.verified_outlined,
                size: 16,
                color: Colors.orange,
              ),
              labelStyle: const TextStyle(fontSize: 12.5),
            ),
          )
          .toList(),
    );
  }
}

/* =========================
 * COLORED CARD (MP-ASI)
 * ========================= */
class _ColoredCard extends StatelessWidget {
  final Color color;
  final String title;
  final List<String> bullets;
  const _ColoredCard({
    required this.color,
    required this.title,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.10), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant_menu_outlined, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...bullets.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================
 * MITOS vs FAKTA (Accordion)
 * ========================= */
class _MitosFakta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <Map<String, String>>[
      {
        "mitos": "Stunting hanya soal anak pendek.",
        "fakta":
            "Tidak. Stunting juga berdampak pada perkembangan kognitif, imunitas, dan produktivitas jangka panjang.",
      },
      {
        "mitos": "Tanpa intervensi pun nanti akan mengejar sendiri.",
        "fakta":
            "Tidak. Perlu intervensi sejak dini (1000 HPK): gizi seimbang, ASI/MP-ASI adekuat, imunisasi, & WASH.",
      },
      {
        "mitos": "MP-ASI cukup bubur encer saja.",
        "fakta":
            "Kurang tepat. Anak butuh kepadatan energi & protein hewani harian (telur/ikan/ayam/hati).",
      },
      {
        "mitos": "Cuci tangan tidak berpengaruh pada stunting.",
        "fakta":
            "Keliru. Praktik higiene & sanitasi (WASH) menurunkan diare & infeksi enterik yang berkontribusi pada stunting.",
      },
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: items
              .map(
                (e) => Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    leading: const Icon(Icons.help_outline),
                    title: Text(
                      e["mitos"]!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.fact_check_outlined,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e["fakta"]!)),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/* =========================
 * WARNING SIGNS
 * ========================= */
class _WarningSigns extends StatelessWidget {
  const _WarningSigns();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.report_gmailerrorred_outlined,
      color: Colors.redAccent,
      title: "Tanda Waspada / Perlu Rujukan",
      children: const [
        "Grafik TB/U atau BB/U mendatar/menurun signifikan.",
        "Tidak nafsu makan lama, diare/ISPA berulang, demam lama, berat badan tidak naik.",
        "Kecurigaan TB, cacingan berat, anemia sedang–berat, atau penyakit kronis lainnya.",
      ],
    );
  }
}

/* =========================
 * CALLOUT FOOTER
 * ========================= */
class _Callout extends StatelessWidget {
  final Color primary;
  const _Callout({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_outlined, color: primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Tips: pantau pertumbuhan dengan kurva WHO secara berkala; pastikan protein hewani harian, variasi sayur-buah, praktik WASH, dan segera konsultasi bila grafik melambat.",
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
