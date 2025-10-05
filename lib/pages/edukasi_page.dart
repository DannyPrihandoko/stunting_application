import 'package:flutter/material.dart';

class EdukasiPage extends StatelessWidget {
  const EdukasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        appBar: AppBar(
          title: const Text('Edukasi Stunting'),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Risiko'),
              Tab(text: 'HPK'),
              Tab(text: 'Tips'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SesiRisiko(),
            _SesiHPK(),
            _SesiTips(),
          ],
        ),
      ),
    );
  }
}

/* =========================
 * SESI 1 — FAKTOR RISIKO
 * ========================= */
class _SesiRisiko extends StatelessWidget {
  const _SesiRisiko();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: const [
        _SectionHeader(
          color: Color(0xFF26A69A),
          icon: Icons.pregnant_woman,
          title: "Maternal & Pranatal",
          subtitle: "Pra-konsepsi & kehamilan memengaruhi pertumbuhan lahir.",
        ),
        _BulletCard(
          color: Color(0xFF26A69A),
          emojiIcon: Icons.favorite,
          bullets: [
            "KEK remaja/WUS → risiko BBLR naik; mikronutrien (Fe, folat, Zn, vit A) penting.",
            "Anemia & asupan energi/protein rendah → panjang lahir rendah.",
            "Infeksi ibu (malaria/TB/kronis) ganggu pertumbuhan janin.",
            "Usia <20 th & jarak hamil <24 bln menaikkan risiko.",
            "ANC <4x mengurangi suplementasi & deteksi dini.",
            "Pendidikan/SES rendah batasi akses gizi & layanan.",
            "Rokok/asap & kerja berat memperburuk risiko.",
          ],
        ),

        _SectionHeader(
          color: Color(0xFF7E57C2),
          icon: Icons.child_care,
          title: "Bayi & Pemberian Makan",
          subtitle: "IMD, ASI eksklusif, MP-ASI tepat waktu & berkualitas.",
        ),
        _BulletCard(
          color: Color(0xFF7E57C2),
          emojiIcon: Icons.local_fire_department,
          bullets: [
            "IMD & kolostrum protektif; tanpa IMD → risiko infeksi naik.",
            "ASI eksklusif 0–6 bln protektif; tanpa ASI → risiko stunting ~2×.",
            "MP-ASI mulai 6 bln: tepat waktu, aman, cukup kualitas/kuantitas.",
            "Risiko naik bila MP-ASI terlambat (>8 bln) / terlalu dini (<4 bln).",
            "Rendahnya diversitas & frekuensi makan → defisiensi mikro.",
            "Feeding responsif meningkatkan asupan efektif.",
          ],
        ),

        _SectionHeader(
          color: Color(0xFFFF7043),
          icon: Icons.sick,
          title: "Infeksi Berulang",
          subtitle: "Diare/ISPA/cacingan/TB/malaria → ganggu penyerapan & energi.",
        ),
        _BulletCard(
          color: Color(0xFFFF7043),
          emojiIcon: Icons.coronavirus,
          bullets: [
            "EED (gangguan usus) & inflamasi kronis hambat IGF-1 & pertumbuhan.",
            "Diare: kehilangan cairan & mikronutrien; cacingan → anemia & kurang protein.",
            "Anoreksia saat sakit menurunkan asupan energi.",
          ],
        ),

        _SectionHeader(
          color: Color(0xFF42A5F5),
          icon: Icons.clean_hands,
          title: "Rumah Tangga & WASH",
          subtitle: "Air bersih, jamban sehat, CTPS menurunkan diare.",
        ),
        _BulletCard(
          color: Color(0xFF42A5F5),
          emojiIcon: Icons.water_drop,
          bullets: [
            "Sanitasi layak & pengolahan air protektif.",
            "Crowding & kemiskinan → ketidakamanan pangan.",
          ],
        ),

        _SectionHeader(
          color: Color(0xFF66BB6A),
          icon: Icons.local_hospital,
          title: "Akses Layanan & Struktural",
          subtitle: "ANC, imunisasi, suplementasi; pengaruh krisis/iklim/konflik.",
        ),
        _BulletCard(
          color: Color(0xFF66BB6A),
          emojiIcon: Icons.public,
          bullets: [
            "Cakupan ANC & imunisasi protektif terhadap infeksi & stunting.",
            "Krisis ekonomi/iklim/konflik mengganggu layanan & ketahanan pangan.",
          ],
        ),
      ],
    );
  }
}

/* =========================
 * SESI 2 — 1000 HPK & MP-ASI
 * ========================= */
class _SesiHPK extends StatelessWidget {
  const _SesiHPK();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: const [
        _SectionHeader(
          color: Color(0xFFFFC107),
          icon: Icons.timeline,
          title: "Langkah 1000 HPK",
          subtitle: "Pra-kehamilan hingga anak usia 2 tahun.",
        ),
        _StepCard(
          color: Color(0xFFFFC107),
          icon: Icons.health_and_safety,
          title: "Pra-Konsepsi",
          points: [
            "Suplementasi Fe-folat, gizi seimbang, hentikan rokok.",
            "Cegah KEK; persiapkan kehamilan dengan asupan protein memadai.",
          ],
        ),
        _StepCard(
          color: Color(0xFFFFC107),
          icon: Icons.pregnant_woman,
          title: "Saat Hamil",
          points: [
            "ANC rutin; TTD; protein hewani harian; batasi kerja berat.",
            "Kendalikan anemia & infeksi (malaria/TB, dsb).",
          ],
        ),
        _StepCard(
          color: Color(0xFFFFC107),
          icon: Icons.baby_changing_station,
          title: "0–6 bulan",
          points: [
            "IMD/kolostrum; ASI eksklusif 0–6 bulan.",
            "Cegah infeksi: kebersihan & imunisasi dasar.",
          ],
        ),
        _StepCard(
          color: Color(0xFFFFC107),
          icon: Icons.restaurant_menu,
          title: "≥6 bulan (MP-ASI)",
          points: [
            "Mulai MP-ASI umur 6 bln, aman, cukup kualitas+kuantitas.",
            "Variasi (diversitas) & frekuensi sesuai usia; protein hewani harian.",
          ],
        ),

        _SectionHeader(
          color: Color(0xFFEF6C00),
          icon: Icons.restaurant,
          title: "Panduan MP-ASI",
          subtitle: "Waktu, tekstur, kualitas, energi & feeding responsif.",
        ),
        _BulletCard(
          color: Color(0xFFEF6C00),
          emojiIcon: Icons.egg,
          bullets: [
            "Waktu: mulai 6 bln. Terlambat (>8 bln) → defisit gizi; terlalu dini (<4 bln) → risiko infeksi.",
            "Tekstur: lumat → cincang halus → tekstur keluarga.",
            "Diversitas: wajib protein hewani harian + sayur/buah.",
            "Frekuensi: 6–8 bln (≥2×/hari), 9–23 bln (≥3×/hari).",
            "Energi: hindari bubur encer; tingkatkan kepadatan energi.",
            "Responsif: peka sinyal lapar/kenyang; sabar, tidak memaksa.",
          ],
        ),
      ],
    );
  }
}

/* =========================
 * SESI 3 — MITOS, WASPADA, PENCEGAHAN
 * ========================= */
class _SesiTips extends StatelessWidget {
  const _SesiTips();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: const [
        _SectionHeader(
          color: Color(0xFF3F51B5),
          icon: Icons.fact_check,
          title: "Mitos vs Fakta",
          subtitle: "Klarifikasi cepat agar keputusan tepat.",
        ),
        _MitosFaktaList(items: [
          {
            "mitos": "Stunting hanya soal anak pendek.",
            "fakta":
                "Tidak. Juga berdampak pada kognitif, imunitas, dan produktivitas jangka panjang."
          },
          {
            "mitos": "Nanti mengejar sendiri tanpa intervensi.",
            "fakta":
                "Perlu intervensi sejak 1000 HPK: gizi, ASI/MP-ASI adekuat, imunisasi, & WASH."
          },
          {
            "mitos": "MP-ASI cukup bubur encer saja.",
            "fakta":
                "Kepadatan energi & protein hewani harian penting untuk tumbuh kembang."
          },
          {
            "mitos": "Cuci tangan tidak berpengaruh.",
            "fakta":
                "WASH (air bersih, jamban sehat, CTPS) menurunkan diare & infeksi enterik."
          },
        ]),

        _SectionHeader(
          color: Color(0xFFE53935),
          icon: Icons.report_gmailerrorred,
          title: "Tanda Waspada / Perlu Rujukan",
          subtitle: "Segera konsultasi bila muncul tanda berikut.",
        ),
        _BulletCard(
          color: Color(0xFFE53935),
          emojiIcon: Icons.warning_amber_rounded,
          bullets: [
            "Grafik TB/U atau BB/U mendatar/menurun tajam.",
            "Nafsu makan sangat kurang lama; diare/ISPA berulang; demam lama; BB tidak naik.",
            "Curiga TB, cacingan berat, anemia sedang–berat, atau penyakit kronis lainnya.",
          ],
        ),

        _SectionHeader(
          color: Color(0xFF2E7D32),
          icon: Icons.emoji_objects,
          title: "Pencegahan Singkat",
          subtitle: "Langkah praktis di rumah & layanan.",
        ),
        _BulletCard(
          color: Color(0xFF2E7D32),
          emojiIcon: Icons.verified_outlined,
          bullets: [
            "Imunisasi lengkap & obat cacing sesuai program.",
            "ASI eksklusif 0–6 bln; MP-ASI berkualitas ≥6 bln; protein hewani harian.",
            "PHBS & WASH: CTPS, air bersih, jamban sehat, pengolahan air.",
            "Pantau tumbuh kembang rutin (posyandu/MTBS).",
          ],
        ),
      ],
    );
  }
}

/* =========================
 * UI REUSABLE
 * ========================= */
class _SectionHeader extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;
  const _SectionHeader({
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(.25)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      )),
                  if (subtitle != null)
                    Text(subtitle!,
                        style:
                            TextStyle(color: Colors.grey.shade700, fontSize: 12.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  final Color color;
  final List<String> bullets;
  final IconData emojiIcon;
  const _BulletCard({
    required this.color,
    required this.bullets,
    required this.emojiIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [color.withOpacity(.07), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: bullets
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(emojiIcon, color: color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(t)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final List<String> points;
  const _StepCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [color.withOpacity(.10), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
              ]),
              const SizedBox(height: 8),
              ...points.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p)),
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

class _MitosFaktaList extends StatelessWidget {
  final List<Map<String, String>> items;
  const _MitosFaktaList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: items
              .map(
                (e) => Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    leading: const Icon(Icons.help_outline),
                    title: Text(e["mitos"]!,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.fact_check_outlined,
                              color: Colors.green),
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
