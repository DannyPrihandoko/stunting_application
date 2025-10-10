// lib/pages/srs_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:stunting_application/models/risk_factor.dart';
import 'package:stunting_application/models/mother_profile_repository.dart';
import 'package:stunting_application/pages/profil_bunda_page.dart';
import 'srs_history_for_mother_page.dart'; // <-- IMPORT HALAMAN BARU

/// ==========================================================
/// DATA FALLBACK (LURING/OFFLINE)
/// ==========================================================
Map<String, RiskFactor> _mapToRiskFactors(
  Map<String, String> data,
  int weight,
) {
  final Map<String, RiskFactor> result = {};
  data.forEach((key, label) {
    result[key] = RiskFactor(key: key, label: label, weight: weight);
  });
  return result;
}

final Map<String, dynamic> _fallbackRiskFactors = {
  "weight_2": {
    "asi_non_eksklusif": "Tidak ASI eksklusif 0–6 bln",
    "bblr": "Berat Badan Lahir Rendah (BBLR)",
    "ibu_pendek": "Ibu bertubuh pendek",
    "mpasi_tidak_adekuat": "MP-ASI tidak adekuat",
    "panjang_lahir_pendek_iugr": "Panjang lahir pendek / IUGR",
    "prematur": "Prematur",
    "wash_buruk": "WASH buruk (jamban tidak layak/air tidak diolah)",
  },
  "weight_1": {
    "anak_laki": "Jenis kelamin anak laki-laki",
    "art_banyak": "Anggota rumah tangga banyak (≥5)",
    "ayah_pendek": "Ayah bertubuh pendek",
    "diare_berulang_infeksi": "Diare berulang / infeksi",
    "imunisasi_tidak_lengkap": "Imunisasi tidak lengkap",
    "lila_kurang": "LILA ibu kurang",
    "pajanan_pestisida": "Pajanan pestisida",
    "pendapatan_rendah": "Pendapatan keluarga rendah",
    "pendidikan_ibu_rendah": "Pendidikan ibu rendah",
    "pola_asuh_tidak_adekuat": "Pola asuh tidak adekuat",
    "usia_ibu_remaja": "Kehamilan usia remaja",
  },
};

/// Halaman Perhitungan "Skor Risiko Stunting (SRS)"
class SrsPage extends StatefulWidget {
  const SrsPage({super.key});

  @override
  State<SrsPage> createState() => _SrsPageState();
}

class _SrsPageState extends State<SrsPage> {
  final _motherNameCtrl = TextEditingController();
  final _motherRepo = MotherProfileRepository();

  Map<String, RiskFactor> _riskFactorsWeight2 = {};
  Map<String, RiskFactor> _riskFactorsWeight1 = {};

  int _score = 0;
  String _kategori = '-';
  String _saran = '—';
  bool _loadingRisk = true;
  bool _loadingMother = true;

  // State untuk ID dan Nama Ibu
  String? _currentMotherId;
  String? _currentMotherName;

  final DatabaseReference _dbRefSrsCalculations = FirebaseDatabase.instance.ref(
    "srs_calculations",
  );
  final DatabaseReference _dbRefRiskFactors = FirebaseDatabase.instance.ref(
    "risk_factors",
  );

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _motherNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait<void>([_loadRiskFactors(), _prefillMotherFromProfile()]);
  }

  Future<void> _prefillMotherFromProfile() async {
    try {
      final currentId = await _motherRepo.getCurrentId();
      if (currentId == null) {
        if (mounted) {
          setState(() {
            _loadingMother = false;
            _currentMotherId = null;
            _currentMotherName = null;
            _motherNameCtrl.clear();
          });
        }
        return;
      }

      final prof = await _motherRepo.read(currentId);
      final name = prof?.nama ?? '';

      if (mounted) {
        setState(() {
          _currentMotherId = currentId;
          _currentMotherName = name;
          _motherNameCtrl.text = name;
          _loadingMother = false;
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Gagal memuat profil ibu (mungkin offline): $e');
    } finally {
      if (mounted) setState(() => _loadingMother = false);
    }
  }

  Future<void> _loadRiskFactors() async {
    try {
      final snapshot = await _dbRefRiskFactors.get();
      final data = snapshot.value as Map<dynamic, dynamic>?;
      bool loadedFromFirebase = false;

      if (snapshot.exists && data != null) {
        final Map<String, RiskFactor> tempRisk2 = {};
        final Map<String, RiskFactor> tempRisk1 = {};

        if (data['weight_2'] != null) {
          (data['weight_2'] as Map<dynamic, dynamic>).forEach((key, value) {
            tempRisk2[key.toString()] = RiskFactor.fromMap(
              key.toString(),
              value,
            );
          });
        }
        if (data['weight_1'] != null) {
          (data['weight_1'] as Map<dynamic, dynamic>).forEach((key, value) {
            tempRisk1[key.toString()] = RiskFactor.fromMap(
              key.toString(),
              value,
            );
          });
        }

        if (tempRisk2.isNotEmpty || tempRisk1.isNotEmpty) {
          if (mounted) {
            setState(() {
              _riskFactorsWeight2 = tempRisk2;
              _riskFactorsWeight1 = tempRisk1;
            });
          }
          loadedFromFirebase = true;
        }
      }

      if (!loadedFromFirebase) {
        _loadFallbackRiskFactors(isError: false);
      }
    } catch (e) {
      _loadFallbackRiskFactors(isError: true);
      debugPrint('DEBUG: Gagal memuat faktor risiko dari Firebase: $e');
    } finally {
      if (mounted) setState(() => _loadingRisk = false);
    }
  }

  void _loadFallbackRiskFactors({required bool isError}) {
    if (mounted) {
      setState(() {
        _riskFactorsWeight2 = _mapToRiskFactors(
          _fallbackRiskFactors["weight_2"] as Map<String, String>,
          2,
        );
        _riskFactorsWeight1 = _mapToRiskFactors(
          _fallbackRiskFactors["weight_1"] as Map<String, String>,
          1,
        );
      });
      if (isError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal memuat faktor risiko. Menggunakan data luring (offline) cadangan.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _hitungSRS() async {
    final ibu = _motherNameCtrl.text.trim();
    if (ibu.isEmpty || _currentMotherId == null) {
      final go = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Profil Ibu Belum Ada'),
          content: const Text(
            'Nama ibu diambil dari Profil Bunda milik perangkat ini.\n\nIsi/ pilih profil ibu sekarang?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Isi Profil Ibu'),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilBundaPage()),
        );
        await _prefillMotherFromProfile();
      }
      if (_motherNameCtrl.text.trim().isEmpty) return;
    }

    int sum2 = 0;
    _riskFactorsWeight2.forEach((_, rf) {
      if (rf.isSelected) sum2++;
    });

    int sum1 = 0;
    _riskFactorsWeight1.forEach((_, rf) {
      if (rf.isSelected) sum1++;
    });

    final int srs = 2 * sum2 + sum1;

    String kategori;
    String saran;
    if (srs >= 9) {
      kategori = 'Tinggi';
      saran =
          'Kunjungan rumah mingguan, konseling menyusui & MP-ASI, paket PMT protein hewani, perbaikan WASH prioritas, rujuk bila ada infeksi.';
    } else if (srs >= 5) {
      kategori = 'Sedang';
      saran =
          'Kelas ibu & caregiver, monitoring bulanan, paket edukasi MP-ASI, cek & lengkapi imunisasi.';
    } else {
      kategori = 'Rendah';
      saran = 'Intervensi universal & pemantauan rutin (posyandu/MT).';
    }

    setState(() {
      _score = srs;
      _kategori = kategori;
      _saran = saran;
    });

    final Map<String, bool> selectedRisk2 = {
      for (final e in _riskFactorsWeight2.entries) e.key: e.value.isSelected,
    };
    final Map<String, bool> selectedRisk1 = {
      for (final e in _riskFactorsWeight1.entries) e.key: e.value.isSelected,
    };

    final Map<String, dynamic> srsData = {
      'timestamp': ServerValue.timestamp,
      'score': _score,
      'category': _kategori,
      'recommendation': _saran,
      'risk_factors_weight2': selectedRisk2,
      'risk_factors_weight1': selectedRisk1,
      'mother': {
        'name': ibu,
        'name_lower': ibu.toLowerCase(),
        'ownerId': _currentMotherId, // <-- PERUBAHAN: Simpan ID Ibu
      },
    };

    try {
      await _dbRefSrsCalculations.push().set(srsData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data SRS berhasil disimpan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data SRS: $e')));
      }
    }
  }

  void _reset() {
    setState(() {
      for (final rf in _riskFactorsWeight2.values) {
        rf.isSelected = false;
      }
      for (final rf in _riskFactorsWeight1.values) {
        rf.isSelected = false;
      }
      _score = 0;
      _kategori = '-';
      _saran = '—';
    });
  }

  // --- FUNGSI BARU: Navigasi ke Riwayat Khusus ---
  void _goToHistory() {
    if (_currentMotherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil Ibu belum diatur untuk melihat riwayat.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SrsHistoryForMotherPage(
          motherId: _currentMotherId!,
          motherName: _currentMotherName ?? 'Tanpa Nama',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loadingRisk || _loadingMother;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prediksi Stunting - Skor Risiko (SRS)"),
        actions: [
          // --- TOMBOL BARU: Riwayat ---
          IconButton(
            tooltip: 'Riwayat SRS Ibu Ini',
            onPressed: _goToHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Segarkan Nama Ibu',
            onPressed: _prefillMotherFromProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange.withOpacity(0.15),
            child: const Text(
              "Checklist faktor risiko berdasarkan ringkasan jurnal. "
              "SRS dipakai untuk penyaringan/triase program, bukan diagnosis.",
              textAlign: TextAlign.center,
            ),
          ),
          loading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            child: TextFormField(
                              controller: _motherNameCtrl,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "Nama Ibu (otomatis dari Profil)",
                                hintText: "Isi di halaman Profil Bunda",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                                suffixIcon: IconButton(
                                  tooltip: 'Ubah di Profil Bunda',
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ProfilBundaPage(),
                                      ),
                                    );
                                    await _prefillMotherFromProfile();
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildGroupCard(
                          context,
                          title: "Faktor Bobot 2 (determinasi kuat)",
                          subtitle:
                              "Centang jika terpenuhi/berisiko. Bobot ×2 per item.",
                          items: _riskFactorsWeight2,
                        ),
                        const SizedBox(height: 12),
                        _buildGroupCard(
                          context,
                          title: "Faktor Bobot 1 (pendukung penting)",
                          subtitle:
                              "Centang jika terpenuhi/berisiko. Bobot ×1 per item.",
                          items: _riskFactorsWeight1,
                        ),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.orange.shade200)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                _ResultBar(score: _score, kategori: _kategori),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Tindak lanjut:",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Align(alignment: Alignment.centerLeft, child: Text(_saran)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _hitungSRS,
                        icon: const Icon(Icons.calculate),
                        label: const Text("Hitung & Simpan SRS"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
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
                        label: const Text("Reset"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Map<String, RiskFactor> items,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          initiallyExpanded: true,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          children: items.values.map((riskFactor) {
            return CheckboxListTile(
              value: riskFactor.isSelected,
              onChanged: (v) =>
                  setState(() => riskFactor.isSelected = v ?? false),
              title: Text(riskFactor.label),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  final int score;
  final String kategori;
  const _ResultBar({required this.score, required this.kategori});

  Color _badgeColor() {
    if (kategori == 'Tinggi') return Colors.red;
    if (kategori == 'Sedang') return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _badgeColor().withOpacity(0.08),
        border: Border.all(color: _badgeColor()),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.assessment),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Skor Risiko Stunting (SRS): $score",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _badgeColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              kategori,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
