// lib/pages/gizi_status_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import '../models/mother_profile_repository.dart';
import '../models/child_repository.dart';
import '../models/who_anthro_mock.dart'; // Import data SD mock

class GiziStatusPage extends StatefulWidget {
  const GiziStatusPage({super.key});

  @override
  State<GiziStatusPage> createState() => _GiziStatusPageState();
}

class _GiziStatusPageState extends State<GiziStatusPage> {
  // Hanya simpan reference yang digunakan
  final _db = FirebaseDatabase.instance;
  final _motherRepo = MotherProfileRepository();
  final DatabaseReference _dbRefGiziHistory = FirebaseDatabase.instance.ref(
    "gizi_wfh_history",
  ); // NEW DB REF

  String? _motherId; // Digunakan untuk fetch data anak
  bool _loading = true;
  bool _saving = false; // NEW saving indicator

  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  String? _selectedChildId;
  final List<ChildData> _children = [];

  // Hasil Perhitungan Gizi
  String _giziCategory = '-';
  String _zScoreText = '-';
  Color _resultColor = Colors.grey;
  double _score = 0.0;

  // Data input yang akan disimpan
  double? _inputHeight;
  double? _inputWeight;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final mid = await _motherRepo.getCurrentId();
      if (mid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      _motherId = mid;

      // Gunakan _motherId yang sekarang sudah digunakan untuk memuat data anak
      final snap = await _db.ref('mothers/$_motherId/children').get();
      if (snap.exists && snap.value is Map) {
        final map = Map<dynamic, dynamic>.from(snap.value as Map);
        map.forEach((id, v) {
          if (v is Map) {
            _children.add(
              ChildData.fromMap(id.toString(), Map<dynamic, dynamic>.from(v)),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat anak: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  ChildData? get _selectedChild => _children.firstWhere(
    (c) => c.id == _selectedChildId,
    orElse: () => const ChildData(id: null, name: '', birthDate: null, sex: ''),
  );

  // Fungsi utilitas untuk interpolasi linear (disederhanakan)
  double _interpolate(double x, double x1, double y1, double x2, double y2) {
    if (x1 == x2) return y1;
    // Z = Y1 + (X - X1) * (Y2 - Y1) / (X2 - X1)
    // Di mana X = Berat (kg), Y = Z-Score
    return y1 + (x - x1) * (y2 - y1) / (x2 - x1);
  }

  /// Fungsi utama: Menghitung Z-Score (SD) berdasarkan Berat dan Tinggi Anak.
  void _calculateGiziStatus() {
    if (_selectedChildId == null || _selectedChild?.sex.isEmpty == true) {
      _showSnackbar('Pilih anak dan pastikan jenis kelamin terisi.');
      return;
    }
    final h = double.tryParse(_heightCtrl.text.replaceAll(',', '.'));
    final w = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));

    if (h == null || w == null || h <= 0 || w <= 0) {
      _showSnackbar('Masukkan nilai Tinggi (cm) dan Berat (kg) yang valid.');
      return;
    }

    _inputHeight = h;
    _inputWeight = w;

    // 1. Ambil data SD WHO yang relevan berdasarkan Tinggi (h) dan Jenis Kelamin (sex)
    final sex = _selectedChild!.sex; // 'L' atau 'P'
    final dataMap = WhoAnthroData.getWfhData(h, sex);

    if (dataMap == null) {
      // Jika data SD tidak tersedia untuk tinggi tersebut (di luar range mock)
      _showSnackbar(
        'Tidak ada data SD standar untuk tinggi ${h.toStringAsFixed(1)} cm (menggunakan data mock).',
      );
      setState(() {
        _giziCategory = 'Data SD Tidak Tersedia';
        _zScoreText = '-';
        _resultColor = Colors.blueGrey;
        _score = 0.0;
      });
      return;
    }

    // 2. Tentukan SD Z-Score (Mock Z-Score calculation based on proximity to SD lines)

    // Nilai SD dari dataMap
    final M = dataMap["M"]!;
    final SD_3 = dataMap["-3"]!;
    final SD_2 = dataMap["-2"]!;
    // SD +1 digunakan untuk batas normal/berisiko gizi lebih
    final SD1 = dataMap["+1"]!;
    final SD2 = dataMap["+2"]!;
    final SD3 = dataMap["+3"]!;

    double estimatedZ = 0.0;

    if (w > SD3) {
      // Di atas +3 SD (Obesitas)
      estimatedZ = 3.0 + (w - SD3) / (SD3 - SD2);
    } else if (w > SD2) {
      // Antara +2 SD dan +3 SD (Gizi Lebih)
      estimatedZ = _interpolate(w, SD2, 2.0, SD3, 3.0);
    } else if (w > SD1) {
      // Antara +1 SD dan +2 SD (Berisiko Gizi Lebih)
      estimatedZ = _interpolate(w, SD1, 1.0, SD2, 2.0);
    } else if (w >= M) {
      // Antara Median dan +1 SD (Gizi Baik / Normal)
      // Interpolasi antara Median (0) dan +1 SD (1)
      estimatedZ = _interpolate(w, M, 0.0, SD1, 1.0);
    } else if (w >= SD_2) {
      // Antara -2 SD dan Median (Gizi Baik / Normal)
      // Interpolasi antara -2 SD (-2) dan Median (0)
      estimatedZ = _interpolate(w, SD_2, -2.0, M, 0.0);
    } else if (w >= SD_3) {
      // Antara -3 SD dan -2 SD (Gizi Kurang)
      estimatedZ = _interpolate(w, SD_3, -3.0, SD_2, -2.0);
    } else {
      // Di bawah -3 SD (Gizi Buruk)
      estimatedZ = -3.0 - (SD_3 - w) / (SD_2 - SD_3);
    }

    // 3. Tentukan Kategori Gizi berdasarkan Z-Score yang diestimasi
    final result = _getGiziCategory(estimatedZ);

    setState(() {
      _score = estimatedZ;
      _giziCategory = result.category;
      _zScoreText = 'Z-Score Est: ${estimatedZ.toStringAsFixed(2)} SD';
      _resultColor = result.color;
    });
  }

  /// NEW: Menyimpan hasil perhitungan ke Firebase Realtime Database
  Future<void> _saveGiziResult() async {
    if (_giziCategory == '-') {
      _showSnackbar('Hitung status gizi terlebih dahulu sebelum menyimpan.');
      return;
    }
    if (_motherId == null || _selectedChildId == null) {
      _showSnackbar('Mohon pilih Profil Ibu dan Anak terlebih dahulu.');
      return;
    }

    setState(() => _saving = true);

    final payload = {
      'timestamp': ServerValue.timestamp,
      'motherId': _motherId,
      'childId': _selectedChildId,
      'childName': _selectedChild!.name.isEmpty ? null : _selectedChild!.name,
      'childSex': _selectedChild!.sex,
      'input': {'heightCm': _inputHeight, 'weightKg': _inputWeight},
      'result': {
        'zScore': double.parse(_score.toStringAsFixed(2)),
        'category': _giziCategory,
        'scoreText': _zScoreText,
      },
      'scoringMethod': 'WFH_Mock_V1',
    };

    try {
      // Path: /gizi_wfh_history/{childId}/{pushId}
      await _dbRefGiziHistory.child(_selectedChildId!).push().set(payload);

      if (!mounted) return;
      _showSnackbar(
        'Data Status Gizi berhasil disimpan. (Akan sinkron saat online)',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Gagal menyimpan data Status Gizi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ({String category, Color color}) _getGiziCategory(double z) {
    // Definisi Kategori Gizi (berdasarkan gambar input)
    if (z >= 3) {
      return (category: 'Kategori Obesitas', color: Colors.purple.shade700);
    } else if (z >= 2) {
      return (category: 'Kategori Gizi Lebih', color: Colors.red.shade700);
    } else if (z >= 1) {
      return (category: 'Berisiko Gizi Lebih', color: Colors.orange.shade700);
    } else if (z >= -2) {
      return (category: 'Gizi Baik / Normal', color: Colors.green.shade700);
    } else if (z >= -3) {
      // Antara -3 hingga < -2 SD
      return (category: 'Gizi Kurang', color: Colors.amber.shade700);
    } else {
      // Di bawah -3 SD
      return (category: 'Gizi Buruk', color: Colors.red.shade900);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _dec(String label, {String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
      suffixIcon: suffix,
      fillColor: Colors.white,
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final child = _selectedChild;
    final sexStr = child?.sex == 'L'
        ? 'Laki-laki'
        : (child?.sex == 'P' ? 'Perempuan' : '—');
    final dobStr = (child?.birthDate == null)
        ? '—'
        : DateFormat('dd/MM/yyyy').format(child!.birthDate!);

    // Cek apakah tombol "Simpan" harus aktif
    final isResultReady = _giziCategory != '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Status Gizi (BB/TB)'),
        backgroundColor: primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // === Pemilih Anak ===
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Anak',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedChildId,
                          decoration: _dec(
                            'Pilih Anak',
                            suffix: const Icon(Icons.person_pin_outlined),
                          ),
                          items: _children
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    c.name.isEmpty ? '(Tanpa nama)' : c.name,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedChildId = v;
                          }),
                          validator: (v) =>
                              v == null ? 'Wajib pilih anak' : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tgl Lahir: $dobStr | Jenis Kelamin: $sexStr',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (child?.sex.isEmpty == true && child?.id != null)
                          Text(
                            'Jenis kelamin anak belum diisi di Data Anak.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // === Input Data Pengukuran Terbaru ===
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Pengukuran Terbaru',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _heightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _dec(
                            'Tinggi Badan (cm)',
                            hint: 'Contoh: 75.5',
                            suffix: const Icon(Icons.height),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _dec(
                            'Berat Badan (kg)',
                            hint: 'Contoh: 9.2',
                            suffix: const Icon(Icons.monitor_weight_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // === Tombol Hitung & Simpan ===
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _calculateGiziStatus,
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Hitung WFH'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (isResultReady && !_saving)
                            ? _saveGiziResult
                            : null,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Simpan Hasil'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade700),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // === Panel Hasil ===
                _ResultPanel(
                  category: _giziCategory,
                  zScoreText: _zScoreText,
                  resultColor: _resultColor,
                  rawZScore: _score,
                ),
              ],
            ),
    );
  }
}

// Widget untuk menampilkan hasil perhitungan
class _ResultPanel extends StatelessWidget {
  final String category;
  final String zScoreText;
  final Color resultColor;
  final double rawZScore;

  const _ResultPanel({
    required this.category,
    required this.zScoreText,
    required this.resultColor,
    required this.rawZScore,
  });

  // Menampilkan interpretasi SD berdasarkan gambar
  String _getInterpretation(double z) {
    if (z > 3) return 'Di atas +3 SD: Kategori obesitas.';
    if (z > 2) return 'Antara +2 hingga +3 SD: Kategori gizi lebih.';
    if (z > 1) return 'Antara +1 hingga +2 SD: Kategori berisiko gizi lebih.';
    if (z > -2)
      return 'Antara -2 hingga +1 SD: Kategori gizi baik atau normal.';
    if (z > -3) return 'Antara -3 hingga < -2 SD: Kategori gizi kurang.';
    return 'Di bawah -3 SD: Kategori gizi buruk.';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: resultColor.withOpacity(0.08),
          border: Border.all(color: resultColor.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_heart, color: resultColor, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'Hasil Status Gizi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Kategori Utama
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: resultColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Z-Score Detail
              Text(
                zScoreText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Interpretasi Berdasarkan SD:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _getInterpretation(rawZScore),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Catatan: Metode ini menggunakan WFH (Berat Badan menurut Panjang/Tinggi Badan) yang merupakan indikator gizi akut (Wasting/Gizi Buruk) atau kelebihan (Gizi Lebih/Obesitas). Perlu konfirmasi Z-Score HAZ (Tinggi menurut Usia) untuk Stunting.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
