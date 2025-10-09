import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// Model faktor risiko (punyamu)
import 'package:stunting_application/models/risk_factor.dart';

// Ambil ID profil ibu yang tersimpan di device
import 'package:stunting_application/models/mother_profile_repository.dart';
import 'package:stunting_application/pages/profil_bunda_page.dart';

// (Opsional) fallback kalau repo belum punya getCurrentId(); tidak akan bentrok jika sudah ada.
extension _CompatGetCurrentId on MotherProfileRepository {}

/// --- DATA FAKTOR RISIKO STATIS (FALLBACK LURING) ---
/// Digunakan jika Firebase GAGAL dimuat (misal: OFFLINE total).
/// Struktur ini meniru output yang diharapkan dari Realtime DB.
const Map<String, dynamic> _fallbackRiskFactors = {
  'weight_2': {
    'riwayat_stunting': {
      'label': 'Riwayat anak stunting/berat lahir rendah',
      'weight': 2,
    },
    'komplikasi_kehamilan': {
      'label': 'Kehamilan dengan komplikasi perdarahan',
      'weight': 2,
    },
    'penyakit_kronis_ibu': {
      'label': 'Ibu menderita penyakit kronis (Diabetes, HIV, dll)',
      'weight': 2,
    },
  },
  'weight_1': {
    'tb_ibu_kurang': {'label': 'Tinggi badan ibu < 150 cm', 'weight': 1},
    'usia_ibu_risiko': {
      'label': 'Ibu usia < 20 tahun atau > 35 tahun',
      'weight': 1,
    },
    'jarak_kehamilan_dekat': {
      'label': 'Jarak kehamilan terlalu dekat (< 2 tahun)',
      'weight': 1,
    },
  },
};

/// Halaman Perhitungan "Skor Risiko Stunting (SRS)"
/// Kategori: 0–4 Rendah, 5–8 Sedang, ≥9 Tinggi
class SrsPage extends StatefulWidget {
  const SrsPage({super.key});

  @override
  State<SrsPage> createState() => _SrsPageState();
}

class _SrsPageState extends State<SrsPage> {
  // Controllers
  final _motherNameCtrl = TextEditingController();

  // Repo
  final _motherRepo = MotherProfileRepository();

  /// Risk factor bobot 2 dan 1
  Map<String, RiskFactor> _riskFactorsWeight2 = {};
  Map<String, RiskFactor> _riskFactorsWeight1 = {};

  int _score = 0;
  String _kategori = '-';
  String _saran = '—';
  bool _loadingRisk = true;
  bool _loadingMother = true;

  // DB refs
  final DatabaseReference _dbRefSrsCalculations = FirebaseDatabase.instance.ref(
    "srs_calculations",
  );
  final DatabaseReference _dbRefRiskFactors = FirebaseDatabase.instance.ref(
    "risk_factors",
  );
  final DatabaseReference _dbRefMothers = FirebaseDatabase.instance.ref(
    "mothers",
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

  /// Ambil nama ibu dari profil yang dipilih/tersimpan di device:
  /// mothers/{currentId}.nama
  Future<void> _prefillMotherFromProfile() async {
    try {
      final currentId = await _motherRepo.getCurrentId();
      if (currentId == null) {
        if (mounted) setState(() => _loadingMother = false);
        return;
      }
      final snap = await _dbRefMothers.child(currentId).get();
      if (snap.exists && snap.value is Map) {
        final map = Map<dynamic, dynamic>.from(snap.value as Map);
        final nama = (map['nama'] ?? '').toString().trim();
        if (mounted) _motherNameCtrl.text = nama;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat profil ibu: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingMother = false);
    }
  }

  /// Muat definisi faktor risiko (dengan fallback luring)
  Future<void> _loadRiskFactors() async {
    Map<dynamic, dynamic> dataToUse = _fallbackRiskFactors;
    bool usingFallback = true;
    String statusMessage = 'Menggunakan kriteria SRS luring (default statis).';

    // 1. Coba ambil dari Firebase (akan menggunakan persistence/cache jika ada)
    try {
      final snapshot = await _dbRefRiskFactors.get();
      if (snapshot.exists && snapshot.value != null) {
        dataToUse = snapshot.value as Map<dynamic, dynamic>;
        usingFallback = false;
        statusMessage = 'Kriteria SRS berhasil dimuat dari server/cache.';
      }
    } catch (e) {
      // Jika terjadi error koneksi/timeout (offline total), gunakan fallback.
      statusMessage = 'Koneksi gagal: Menggunakan kriteria SRS LURING.';
    }

    // 2. Proses data yang sudah dipilih (Firebase/Cache atau Fallback)
    final Map<String, RiskFactor> tempRisk2 = {};
    final Map<String, RiskFactor> tempRisk1 = {};

    // Helper function untuk memproses map data
    void processRiskMap(
      Map<String, RiskFactor> map,
      Map<dynamic, dynamic>? source,
    ) {
      if (source != null) {
        source.forEach((key, value) {
          // Asumsi RiskFactor.fromMap ada dan berfungsi
          map[key.toString()] = RiskFactor.fromMap(key.toString(), value);
        });
      }
    }

    if (mounted) {
      processRiskMap(
        tempRisk2,
        dataToUse['weight_2'] as Map<dynamic, dynamic>?,
      );
      processRiskMap(
        tempRisk1,
        dataToUse['weight_1'] as Map<dynamic, dynamic>?,
      );

      setState(() {
        _riskFactorsWeight2 = tempRisk2;
        _riskFactorsWeight1 = tempRisk1;
        _loadingRisk = false;
      });

      // Tampilkan status hanya jika menggunakan data luring (fallback)
      if (usingFallback) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(statusMessage)));
          }
        });
      }
    }
  }

  /// Hitung dan simpan SRS
  Future<void> _hitungSRS() async {
    final ibu = _motherNameCtrl.text.trim();
    if (ibu.isEmpty) {
      // Ajak user mengisi profil ibu dulu
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
      return;
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
          'Kunjungan rumah mingguan, konseling menyusui & MP-ASI, paket PMT protein hewani, '
          'perbaikan WASH prioritas, rujuk bila ada infeksi.';
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
      // Info ibu (dari profil device)
      'mother': {'name': ibu, 'name_lower': ibu.toLowerCase()},
    };

    try {
      // Simpan data (akan di-queue oleh Realtime DB persistence jika offline)
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

  @override
  Widget build(BuildContext context) {
    final loading = _loadingRisk || _loadingMother;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prediksi Stunting - Skor Risiko (SRS)"),
        actions: [
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
                        // Nama Ibu (read-only dari profil)
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
          // Footer hasil + tombol
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

  /// Card checklist faktor risiko
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
