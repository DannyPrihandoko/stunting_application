// ignore_for_file: deprecated_member_use

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

/// ======================
/// Model faktor risiko (top-level)
/// ======================
class _RiskItem {
  final String keyId; // key unik (dipakai simpan ke DB)
  final String label; // label tampil di UI
  final int weight; // bobot poin
  bool checked; // status ceklis

  _RiskItem({required this.keyId, required this.label, required this.weight})
    : checked = false; // default
}

/// ======================
/// Halaman Kalkulator
/// ======================
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  // ======================
  // Ambang skor (bisa dibuat dinamis dari /risk_thresholds)
  // ======================
  static const int lowMax = 3; // <= 3  -> Rendah
  static const int mediumMax = 7; // 4–7  -> Sedang ; >=8 -> Tinggi

  // ======================
  // Definisi faktor (kunci kanonik)
  // ======================

  // Penyebab langsung — Riwayat lahir
  final List<_RiskItem> _directBirth = [
    _RiskItem(
      keyId: 'bblr_prematur',
      label: 'BBLR (<2.5 kg) / Prematur',
      weight: 3,
    ),
    _RiskItem(
      keyId: 'iugr',
      label: 'Riwayat IUGR / panjang lahir pendek',
      weight: 2,
    ),
  ];

  // Penyebab langsung — Pemberian makan
  final List<_RiskItem> _directFeeding = [
    _RiskItem(
      keyId: 'non_asi_eksklusif',
      label: 'Tidak ASI eksklusif 0–6 bln / IMD/kolostrum tidak optimal',
      weight: 2,
    ),
    _RiskItem(
      keyId: 'mpasi_tidak_adeq',
      label:
          'MP-ASI tidak adekuat (variasi/frekuensi kurang, protein hewani rendah)',
      weight: 2,
    ),
    _RiskItem(
      keyId: 'prelakteal_sufor',
      label: 'Pemberian prelakteal (susu formula) awal kehidupan',
      weight: 1,
    ),
  ];

  // Penyebab langsung — Infeksi & imunisasi
  final List<_RiskItem> _directInfection = [
    _RiskItem(
      keyId: 'diare_berulang',
      label: 'Diare berulang (≥2 episode/3 bln)',
      weight: 2,
    ),
    _RiskItem(
      keyId: 'imunisasi_tidak_lengkap',
      label: 'Imunisasi dasar tidak lengkap',
      weight: 1,
    ),
    _RiskItem(
      keyId: 'penyakit_neonatal',
      label: 'Riwayat penyakit neonatal/infeksi menular',
      weight: 1,
    ),
  ];

  // Tidak langsung — Ibu
  final List<_RiskItem> _maternal = [
    _RiskItem(
      keyId: 'tinggi_ibu_pendek',
      label: 'Tinggi ibu <150 cm / status gizi ibu kurang',
      weight: 2,
    ),
    _RiskItem(
      keyId: 'hamil_remaja',
      label: 'Kehamilan remaja (<20 th) pada anak ini',
      weight: 1,
    ),
  ];

  // Tidak langsung — Rumah tangga & WASH
  final List<_RiskItem> _householdWASH = [
    _RiskItem(
      keyId: 'sanitasi_buruk',
      label: 'Sanitasi tidak layak / BAB sembarangan',
      weight: 2,
    ),
    _RiskItem(
      keyId: 'air_tidak_diolah',
      label: 'Air minum tidak diolah/terkontaminasi',
      weight: 1,
    ),
    _RiskItem(
      keyId: 'pendidikan_ibu_rendah',
      label: 'Pendidikan ibu rendah',
      weight: 1,
    ),
    _RiskItem(
      keyId: 'pendapatan_rendah',
      label: 'Pendapatan/wealth index rendah',
      weight: 1,
    ),
    _RiskItem(
      keyId: 'crowding',
      label: 'Jumlah anggota rumah tangga banyak (crowding)',
      weight: 1,
    ),
  ];

  // Faktor anak tambahan
  final List<_RiskItem> _childOther = [
    _RiskItem(keyId: 'laki_laki', label: 'Jenis kelamin laki-laki', weight: 1),
  ];

  // ======================
  // STATE HASIL + form opsional
  // ======================
  int _score = 0;
  String _riskLabel = '-';
  String _advice = '—';
  bool _saving = false;

  final TextEditingController _childNameCtrl = TextEditingController();
  final TextEditingController _ageMonthsCtrl = TextEditingController();
  String? _sex; // "L" / "P" / null

  List<_RiskItem> _allItems() => <_RiskItem>[
    ..._directBirth,
    ..._directFeeding,
    ..._directInfection,
    ..._maternal,
    ..._householdWASH,
    ..._childOther,
  ];

  // ======================
  // Hitung hasil
  // ======================
  void _hitungHasil() {
    int total = 0;
    for (final it in _allItems()) {
      if (it.checked) total += it.weight;
    }

    String label;
    String advice;

    if (total <= lowMax) {
      label = 'Risiko Rendah';
      advice =
          'Teruskan praktik baik: ASI/MP-ASI seimbang, higienitas, imunisasi lengkap, dan pemantauan rutin posyandu.';
    } else if (total <= mediumMax) {
      label = 'Risiko Sedang';
      advice =
          'Perkuat praktik menyusui & MP-ASI (diversitas + frekuensi), lengkapi imunisasi, edukasi WASH, dan pantau pertumbuhan tiap 1–2 bulan.';
    } else {
      label = 'Risiko Tinggi';
      advice =
          'Perlu intervensi intensif: konseling menyusui/MP-ASI, peningkatan protein hewani, tatalaksana diare & pencegahan infeksi, perbaikan sanitasi/air, dan rujukan bila ada tanda bahaya.';
    }

    setState(() {
      _score = total;
      _riskLabel = label;
      _advice = advice;
    });
  }

  // ======================
  // Reset
  // ======================
  void _reset() {
    for (final it in _allItems()) {
      it.checked = false;
    }
    _childNameCtrl.clear();
    _ageMonthsCtrl.clear();
    _sex = null;

    setState(() {
      _score = 0;
      _riskLabel = '-';
      _advice = '—';
    });
  }

  // ======================
  // Simpan ke Realtime Database (hanya ke /calculator_history)
  // ======================
  Future<void> _saveCalculatorResult() async {
    if (_riskLabel == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hitung dulu sebelum menyimpan.')),
      );
      return;
    }

    try {
      setState(() => _saving = true);

      // faktor yang dicentang
      final Map<String, bool> checked = {
        for (final it in _allItems().where((e) => e.checked)) it.keyId: true,
      };

      List<String> _ids(List<_RiskItem> list) =>
          list.where((e) => e.checked).map((e) => e.keyId).toList();

      final groups = {
        "directBirth": _ids(_directBirth),
        "directFeeding": _ids(_directFeeding),
        "directInfection": _ids(_directInfection),
        "maternal": _ids(_maternal),
        "householdWASH": _ids(_householdWASH),
        "childOther": _ids(_childOther),
      };

      // Parse usia (bulan) bila ada
      int? ageMonths;
      if (_ageMonthsCtrl.text.trim().isNotEmpty) {
        final parsed = int.tryParse(_ageMonthsCtrl.text.trim());
        if (parsed != null && parsed >= 0) {
          ageMonths = parsed;
        }
      }

      final payload = {
        "score": _score,
        "riskLabel": _riskLabel, // "Risiko Rendah/Sedang/Tinggi"
        "advice": _advice,
        "checked": checked,
        "groups": groups,
        "meta": {
          "scoringVersion": "v1",
          "appVersion": "1.0.0",
          "ownerId": "anonymous", // ganti ke UID jika pakai FirebaseAuth
          "child": {
            "name": _childNameCtrl.text.trim().isEmpty
                ? null
                : _childNameCtrl.text.trim(),
            "sex": _sex,
            "ageMonths": ageMonths,
          },
        },
        // tulis dua-duanya untuk kompatibilitas
        "createdAt": ServerValue.timestamp,
        "timestamp": ServerValue.timestamp,
      };

      final ref = FirebaseDatabase.instance.ref("calculator_history").push();
      await ref.set(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasil kalkulator tersimpan.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _childNameCtrl.dispose();
    _ageMonthsCtrl.dispose();
    super.dispose();
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Kalkulator Gizi (Risiko Stunting)'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const _PageBackground(), // === Background baru pakai gambar + blur
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _infoCard(
                icon: Icons.info_outline,
                color: primary,
                title: 'Cara pakai',
                text:
                    'Centang faktor yang sesuai kondisi anak/keluarga. Tekan tombol "Hasil" untuk melihat skor & kategori risiko.\n'
                    'Ini alat triase edukatif, bukan diagnosis medis.',
              ),
              const SizedBox(height: 12),

              // Data anak (opsional) — responsif agar tidak overflow
              _childInfoCard(primary),

              // Kelompok faktor
              _groupBox(
                title: 'Penyebab Langsung — Riwayat Lahir',
                icon: Icons.child_care_outlined,
                color: Colors.deepOrange,
                items: _directBirth,
              ),
              _groupBox(
                title: 'Penyebab Langsung — Pemberian Makan',
                icon: Icons.local_dining_outlined,
                color: Colors.teal,
                items: _directFeeding,
              ),
              _groupBox(
                title: 'Penyebab Langsung — Infeksi & Imunisasi',
                icon: Icons.medical_services_outlined,
                color: Colors.redAccent,
                items: _directInfection,
              ),
              _groupBox(
                title: 'Tidak Langsung — Ibu',
                icon: Icons.pregnant_woman_outlined,
                color: Colors.pink,
                items: _maternal,
              ),
              _groupBox(
                title: 'Tidak Langsung — Rumah Tangga & WASH',
                icon: Icons.house_outlined,
                color: Colors.indigo,
                items: _householdWASH,
              ),
              _groupBox(
                title: 'Faktor Anak Tambahan',
                icon: Icons.male_outlined,
                color: Colors.blueGrey,
                items: _childOther,
              ),

              const SizedBox(height: 16),

              // Tombol proses
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _hitungHasil,
                      icon: const Icon(Icons.assessment_outlined),
                      label: const Text(
                        'Hasil',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: primary.withOpacity(0.4)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Panel hasil
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hasil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _chip('Skor $_score'),
                        const SizedBox(width: 8),
                        _chip(_riskLabel),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_advice, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    // Simpan ke Database
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveCalculatorResult,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _saving ? 'Menyimpan...' : 'Simpan ke Database',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'Catatan: Bobot poin disusun dari kekuatan bukti ringkas (mis. BBLR/prematur → bobot tinggi; ASI/MP-ASI, diare, WASH → sedang; pendidikan/pendapatan/jenis kelamin → ringan). Gunakan bersama pemantauan TB/U & BB/U.',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======================
  // Widgets pembantu
  // ======================

  /// Card "Data Anak" — RESPONSIF
  /// - Layar sempit: otomatis jadi kolom (tiap field satu baris)
  /// - Layar lebar: 3 kolom: Nama (flex:2) | JK | Usia (bln)
  Widget _childInfoCard(Color primary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 380; // breakpoint
            final nameField = TextField(
              controller: _childNameCtrl,
              decoration: InputDecoration(
                labelText: 'Nama',
                hintText: 'Misal: Aisyah',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            final sexField = DropdownButtonFormField<String>(
              value: _sex,
              items: const [
                DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                DropdownMenuItem(value: 'P', child: Text('Perempuan')),
              ],
              onChanged: (v) => setState(() => _sex = v),
              isDense: true,
              decoration: InputDecoration(
                labelText: 'JK',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            final ageField = TextField(
              controller: _ageMonthsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Usia (bln)',
                hintText: 'cth: 12',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );

            if (isNarrow) {
              // === SUSUN VERTIKAL (anti overflow) ===
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, color: primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Data Anak (opsional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  nameField,
                  const SizedBox(height: 8),
                  sexField,
                  const SizedBox(height: 8),
                  ageField,
                ],
              );
            }

            // === SUSUN HORIZONTAL (3 kolom) ===
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge_outlined, color: primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Data Anak (opsional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(flex: 2, child: nameField),
                    const SizedBox(width: 10),
                    Expanded(child: sexField),
                    const SizedBox(width: 10),
                    Expanded(child: ageField),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _groupBox({
    required String title,
    required IconData icon,
    required Color color,
    required List<_RiskItem> items,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...items.map((it) {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(it.label),
                value: it.checked,
                onChanged: (v) => setState(() => it.checked = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/// =======================
/// Background: image + blur + tint + gradient + icon pattern
/// =======================
class _PageBackground extends StatelessWidget {
  const _PageBackground();

  // Cek asset exist secara aman
  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Pilih asset pertama yang tersedia dari daftar kandidat
  Future<String?> _pickAsset() async {
    const candidates = <String>[
      'assets/images/bg_pregnant.png',
      'assets/images/bg_nutrition.png',
      'assets/images/bg_health.png',
      'assets/bg.jpg',
    ];
    for (final p in candidates) {
      if (await _assetExists(p)) return p;
    }
    return null; // fallback ke gradient saja kalau tidak ada
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    const peachLight = Color(0xFFFFF3E0);
    const peachLighter = Color(0xFFFFF7F3);

    return FutureBuilder<String?>(
      future: _pickAsset(),
      builder: (context, snap) {
        final path = snap.data;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Base gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [peachLight, peachLighter],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Gambar (jika ada) dengan blur + tint agar konten tetap terbaca
            if (path != null)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.18), // tint lembut
                      BlendMode.srcOver,
                    ),
                    child: Image.asset(
                      path,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),

            // Radial glow coral lembut
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.75, -0.85),
                      radius: 1.0,
                      colors: [
                        primary.withOpacity(0.22),
                        primary.withOpacity(0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Pola ikon halus
            const _IconPatternOverlay(),

            // Watermark ikon besar samar
            Positioned(
              left: -10,
              bottom: -6,
              child: Icon(
                Icons.local_dining_outlined,
                size: 140,
                color: Colors.black.withOpacity(0.05),
              ),
            ),
            Positioned(
              right: -8,
              bottom: 60,
              child: Icon(
                Icons.pregnant_woman_outlined,
                size: 110,
                color: Colors.black.withOpacity(0.05),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IconPatternOverlay extends StatelessWidget {
  const _IconPatternOverlay();

  @override
  Widget build(BuildContext context) {
    final icons = <IconData>[
      Icons.pregnant_woman_outlined,
      Icons.local_dining_outlined,
      Icons.child_care_outlined,
      Icons.health_and_safety_outlined,
    ];

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double cell = 120;
          final cols = (constraints.maxWidth / cell).ceil();
          final rows = (constraints.maxHeight / cell).ceil();
          final total = rows * cols;

          return Opacity(
            opacity: 0.055,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
              ),
              itemCount: total,
              itemBuilder: (context, i) {
                final icon = icons[i % icons.length];
                return Center(child: Icon(icon, size: 26, color: Colors.black));
              },
            ),
          );
        },
      ),
    );
  }
}
