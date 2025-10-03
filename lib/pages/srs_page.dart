import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// --- SESUAIKAN PATH MODEL DI PROYEKMU ---
import 'package:stunting_application/models/risk_factor.dart';

/// Halaman Perhitungan "Skor Risiko Stunting (SRS)"
/// Catatan:
/// - Heuristik programatik untuk penyaringan, bukan diagnosis.
/// - Kategori: 0–4 Rendah, 5–8 Sedang, ≥9 Tinggi
class SrsPage extends StatefulWidget {
  const SrsPage({super.key});

  @override
  State<SrsPage> createState() => _SrsPageState();
}

class _SrsPageState extends State<SrsPage> {
  // Controllers
  final _motherNameCtrl = TextEditingController();

  /// Kelompok variabel bobot 2 dan 1
  Map<String, RiskFactor> _riskFactorsWeight2 = {};
  Map<String, RiskFactor> _riskFactorsWeight1 = {};

  int _score = 0;
  String _kategori = '-';
  String _saran = '—';
  bool _isLoading = true;

  final DatabaseReference _dbRefSrsCalculations = FirebaseDatabase.instance.ref(
    "srs_calculations",
  );
  final DatabaseReference _dbRefRiskFactors = FirebaseDatabase.instance.ref(
    "risk_factors",
  );

  @override
  void initState() {
    super.initState();
    _loadRiskFactors();
  }

  @override
  void dispose() {
    _motherNameCtrl.dispose();
    super.dispose();
  }

  /// Muat definisi faktor risiko
  Future<void> _loadRiskFactors() async {
    try {
      final snapshot = await _dbRefRiskFactors.get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;

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

        setState(() {
          _riskFactorsWeight2 = tempRisk2;
          _riskFactorsWeight1 = tempRisk1;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tidak dapat memuat konfigurasi faktor risiko /risk_factors.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat faktor risiko: $e')),
        );
      }
    }
  }

  /// Hitung dan simpan SRS
  Future<void> _hitungSRS() async {
    final ibu = _motherNameCtrl.text.trim();
    if (ibu.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama ibu wajib diisi.')));
      return;
    }

    int sum2 = 0;
    _riskFactorsWeight2.forEach((key, rf) {
      if (rf.isSelected) sum2++;
    });

    int sum1 = 0;
    _riskFactorsWeight1.forEach((key, rf) {
      if (rf.isSelected) sum1++;
    });

    final int srs = 2 * sum2 + 1 * sum1;

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

    // siapkan payload untuk DB — backward compatible
    final Map<String, bool> selectedRisk2 = {};
    _riskFactorsWeight2.forEach((key, rf) {
      selectedRisk2[key] = rf.isSelected;
    });
    final Map<String, bool> selectedRisk1 = {};
    _riskFactorsWeight1.forEach((key, rf) {
      selectedRisk1[key] = rf.isSelected;
    });

    final Map<String, dynamic> srsData = {
      'timestamp': ServerValue.timestamp,
      'score': _score,
      'category': _kategori,
      'recommendation': _saran,
      'risk_factors_weight2': selectedRisk2,
      'risk_factors_weight1': selectedRisk1,

      // ====== Baru: info ibu (pengguna) ======
      'mother': {'name': ibu, 'name_lower': ibu.toLowerCase()},
      // Catatan: format di atas tidak mengubah struktur lama; field baru bersifat opsional
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
      _riskFactorsWeight2.forEach((key, rf) => rf.isSelected = false);
      _riskFactorsWeight1.forEach((key, rf) => rf.isSelected = false);
      _score = 0;
      _kategori = '-';
      _saran = '—';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prediksi Stunting - Skor Risiko (SRS)"),
      ),
      body: Column(
        children: [
          // Info bar
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

          // Body
          _isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ====== Field Nama Ibu (Wajib) ======
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                            child: TextFormField(
                              controller: _motherNameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: "Nama Ibu (Wajib)",
                                hintText: "Contoh: Siti Aminah",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Bobot 2
                        _buildGroupCard(
                          context,
                          title: "Faktor Bobot 2 (determinasi kuat)",
                          subtitle:
                              "Centang jika kondisi TERPENUHI/berisiko. Bobot ×2 per item.",
                          items: _riskFactorsWeight2,
                        ),
                        const SizedBox(height: 12),

                        // Bobot 1
                        _buildGroupCard(
                          context,
                          title: "Faktor Bobot 1 (pendukung penting)",
                          subtitle:
                              "Centang jika kondisi TERPENUHI/berisiko. Bobot ×1 per item.",
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
              onChanged: (v) {
                setState(() => riskFactor.isSelected = v ?? false);
              },
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
