import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/mother_profile_repository.dart';

/// ===============================
/// Data Model Lokal (mandiri) — SRS
/// ===============================
class SrsRow {
  final String id;
  final int score;
  final String category;
  final String recommendation;
  final int timestamp;
  final Map<String, bool> w2;
  final Map<String, bool> w1;
  final String motherName;

  SrsRow({
    required this.id,
    required this.score,
    required this.category,
    required this.recommendation,
    required this.timestamp,
    required this.w2,
    required this.w1,
    required this.motherName,
  });

  factory SrsRow.fromMap(String id, Map<dynamic, dynamic> m) {
    Map<String, bool> _mapBool(dynamic x) {
      if (x is Map) {
        return Map<String, bool>.from(
          x.map((k, v) => MapEntry("$k", v == true)),
        );
      }
      return {};
    }

    final mother = (m['mother'] ?? {}) as Map? ?? {};
    final motherName = (mother['name'] ?? m['motherName'] ?? '').toString();

    int parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse("$v") ?? 0;
    }

    return SrsRow(
      id: id,
      score: parseInt(m['score']),
      category: (m['category'] ?? '-').toString(),
      recommendation: (m['recommendation'] ?? '-').toString(),
      timestamp: parseInt(m['timestamp'] ?? m['createdAt']),
      w2: _mapBool(m['risk_factors_weight2']),
      w1: _mapBool(m['risk_factors_weight1']),
      motherName: motherName,
    );
  }

  String get formattedDate {
    if (timestamp == 0) return "-";
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}";
  }
}

class CalculatorRecord {
  final String id;
  final int score;
  final String riskLabel;
  final String advice;
  final int timestamp;
  final Map<String, bool> checked;
  final Map<String, dynamic> groups;
  final Map<String, dynamic> meta;

  CalculatorRecord({
    required this.id,
    required this.score,
    required this.riskLabel,
    required this.advice,
    required this.timestamp,
    required this.checked,
    required this.groups,
    required this.meta,
  });

  factory CalculatorRecord.fromMap(String id, Map<dynamic, dynamic> m) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse("$v") ?? 0;
    }

    return CalculatorRecord(
      id: id,
      score: parseInt(m['score']),
      riskLabel: (m['riskLabel'] ?? '-').toString(),
      advice: (m['advice'] ?? '-').toString(),
      timestamp: parseInt(m['timestamp'] ?? m['createdAt']),
      checked: (m['checked'] ?? {}) is Map
          ? Map<String, bool>.from(m['checked'])
          : {},
      groups: (m['groups'] ?? {}) is Map
          ? Map<String, dynamic>.from(m['groups'])
          : {},
      meta: (m['meta'] ?? {}) is Map
          ? Map<String, dynamic>.from(m['meta'])
          : {},
    );
  }

  String get formattedDate {
    if (timestamp == 0) return "-";
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}";
  }

  String get childLine {
    final child = (meta['child'] ?? {}) as Map? ?? {};
    final name = (child['name'] ?? '').toString();
    final sex = (child['sex'] ?? '').toString();
    final age = child['ageMonths'];
    final sexStr = sex == 'L' ? 'L' : (sex == 'P' ? 'P' : '-');
    final ageStr = (age == null) ? '-' : '$age bln';
    final nm = name.isEmpty ? '-' : name;
    return "$nm • $sexStr • $ageStr";
  }
}

/// ======= Riwayat Pemeriksaan Kehamilan =======
class PregCheckRow {
  final String id;
  final String motherId;
  final String motherName; // Nama ibu dari payload
  final int timestamp;
  final String conditionLabel;
  final double? bmi;
  final String bmiCategory;
  final int sri;
  final String category;
  final double? heightCm;
  final double? weightKg;
  final double? lilaCm;
  final String recommendation;

  PregCheckRow({
    required this.id,
    required this.motherId,
    required this.motherName,
    required this.timestamp,
    required this.conditionLabel,
    required this.bmi,
    required this.bmiCategory,
    required this.sri,
    required this.category,
    required this.heightCm,
    required this.weightKg,
    required this.lilaCm,
    required this.recommendation,
  });

  factory PregCheckRow.fromMap(
    String id,
    String motherId,
    Map<dynamic, dynamic> m,
  ) {
    T? asNum<T extends num>(dynamic v) {
      if (v == null) return null;
      if (v is T) return v;
      final p = double.tryParse('$v');
      if (p == null) return null;
      return (T == int ? p.toInt() as T : p as T);
    }

    String label = (m['condition']?['label'] ?? '-').toString();
    final derived = m['derived'] ?? {};
    final input = m['input'] ?? {};
    // Extract motherName from the record itself
    final motherName = (m['motherName'] ?? '').toString(); 

    return PregCheckRow(
      id: id,
      motherId: motherId,
      motherName: motherName, // Assign extracted name
      timestamp: asNum<int>(m['timestamp']) ?? 0,
      conditionLabel: label,
      bmi: asNum<double>(derived['bmi']),
      bmiCategory: (derived['bmiCategory'] ?? '-').toString(),
      sri: asNum<int>(derived['sri']) ?? 0,
      category: (derived['category'] ?? '-').toString(),
      heightCm: asNum<double>(input['heightCm']),
      weightKg: asNum<double>(input['weightKg']),
      lilaCm: asNum<double>(input['lilaCm']),
      recommendation: (m['recommendation'] ?? '-').toString(),
    );
  }

  String get formattedDate {
    if (timestamp == 0) return "-";
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}";
  }
}

/// ===============================
/// Halaman: Riwayat Perhitungan
/// ===============================
class SrsHistoryPage extends StatefulWidget {
  const SrsHistoryPage({super.key});

  @override
  State<SrsHistoryPage> createState() => _SrsHistoryPageState();
}

class _SrsHistoryPageState extends State<SrsHistoryPage> {
  final DatabaseReference _dbRefSrs = FirebaseDatabase.instance.ref(
    "srs_calculations",
  );
  final DatabaseReference _dbRefRiskCfg = FirebaseDatabase.instance.ref(
    "risk_factors",
  );
  final DatabaseReference _dbRefCalc = FirebaseDatabase.instance.ref(
    "calculator_history",
  );
  final DatabaseReference _dbRefPreg = FirebaseDatabase.instance.ref(
    "pregnancy_checks",
  );

  final _motherRepo = MotherProfileRepository();
  String? _motherId;
  String? _motherName;
  bool _loadingMother = true;

  Map<String, String> _rfLabels = {};
  bool _isLoadingLabels = true;

  @override
  void initState() {
    super.initState();
    _loadRiskLabels();
    _loadMother();
  }

  Future<void> _loadMother() async {
    final mid = await _motherRepo.getCurrentId();
    String? name;
    if (mid != null) {
      final prof = await _motherRepo.read(mid);
      name = prof?.nama;
    }
    if (!mounted) return;
    setState(() {
      _motherId = mid;
      _motherName = name;
      _loadingMother = false;
    });
  }

  Future<void> _loadRiskLabels() async {
    try {
      final snap = await _dbRefRiskCfg.get();
      if (snap.exists && snap.value != null) {
        final data = snap.value as Map<dynamic, dynamic>;

        final Map<String, String> labels = {};
        void absorb(dynamic section) {
          if (section is Map) {
            section.forEach((k, v) {
              if (v is Map && v['label'] != null) {
                labels["$k"] = "${v['label']}";
              } else {
                labels["$k"] = "$k";
              }
            });
          }
        }

        absorb(data['weight_2']);
        absorb(data['weight_1']);

        setState(() {
          _rfLabels = labels;
          _isLoadingLabels = false;
        });
      } else {
        setState(() => _isLoadingLabels = false);
      }
    } catch (e) {
      setState(() => _isLoadingLabels = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat label faktor risiko: $e")),
        );
      }
    }
  }

  String _labelOf(String key) => _rfLabels[key] ?? key.replaceAll('_', ' ');

  // Menggunakan warna Material untuk kepastian shade
  Color _badgeBase(String s) {
    final x = s.toLowerCase();
    if (x.contains('tinggi')) return Colors.red;
    if (x.contains('sedang')) return Colors.amber;
    return Colors.green;
  }

  void _showSrsDetails(SrsRow r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Detail Perhitungan SRS"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Waktu", r.formattedDate),
              _detailRow("Ibu", r.motherName.isEmpty ? "—" : r.motherName),
              _detailRow("Skor", r.score.toString()),
              _detailRow("Kategori", r.category),
              const SizedBox(height: 8),
              const Text(
                "Rekomendasi:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(r.recommendation),
              const Divider(height: 20),
              const Text(
                "Faktor Risiko Bobot 2",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...r.w2.entries
                  .where((e) => e.value)
                  .map((e) => Text("• ${_labelOf(e.key)}")),
              if (r.w2.entries.every((e) => !e.value))
                const Text("Tidak ada faktor bobot 2 yang terpilih."),
              const SizedBox(height: 10),
              const Text(
                "Faktor Risiko Bobot 1",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...r.w1.entries
                  .where((e) => e.value)
                  .map((e) => Text("• ${_labelOf(e.key)}")),
              if (r.w1.entries.every((e) => !e.value))
                const Text("Tidak ada faktor bobot 1 yang terpilih."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showCalcDetails(CalculatorRecord rec) {
    String _groupTitle(String k) {
      switch (k) {
        case 'directBirth':
          return 'Penyebab Langsung — Riwayat Lahir';
        case 'directFeeding':
          return 'Penyebab Langsung — Pemberian Makan';
        case 'directInfection':
          return 'Penyebab Langsung — Infeksi & Imunisasi';
        case 'maternal':
          return 'Tidak Langsung — Ibu';
        case 'householdWASH':
          return 'Tidak Langsung — Rumah Tangga & WASH';
        case 'childOther':
          return 'Faktor Anak Tambahan';
        default:
          return k;
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Detail Perhitungan Kalkulator"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Waktu", rec.formattedDate),
              _detailRow("Skor", rec.score.toString()),
              _detailRow("Kategori", rec.riskLabel),
              const SizedBox(height: 8),
              const Text(
                "Saran:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(rec.advice),
              const Divider(height: 20),
              ...rec.groups.entries.map((g) {
                final list = (g.value is List) ? (g.value as List) : const [];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _groupTitle(g.key),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (list.isEmpty)
                        const Text("— (tidak ada)")
                      else
                        ...list.map(
                          (e) => Text("• ${e.toString().replaceAll('_', ' ')}"),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showPregDetails(PregCheckRow r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Detail Pemeriksaan Kehamilan"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Waktu", r.formattedDate),
              _detailRow("Ibu", r.motherName.isNotEmpty ? r.motherName : r.motherId), // Display name or ID
              _detailRow("Kondisi", r.conditionLabel),
              _detailRow("Tinggi (cm)", r.heightCm?.toStringAsFixed(1) ?? "-"),
              _detailRow("Berat (kg)", r.weightKg?.toStringAsFixed(1) ?? "-"),
              _detailRow("LILA (cm)", r.lilaCm?.toStringAsFixed(1) ?? "-"),
              _detailRow("BMI", r.bmi?.toStringAsFixed(1) ?? "-"),
              _detailRow("Kategori BMI", r.bmiCategory),
              _detailRow("SRI", r.sri.toString()),
              _detailRow("Kategori", r.category),
              const SizedBox(height: 8),
              const Text(
                "Rekomendasi:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(r.recommendation),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _scrollableDataTable({
    required List<DataColumn> columns,
    required List<DataRow> rows,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          dataRowMinHeight: 45,
          dataRowMaxHeight: 60,
          headingRowColor: MaterialStateProperty.resolveWith<Color?>(
            (states) => Colors.indigo.shade50,
          ),
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade900,
            fontSize: 14,
          ),
          dataTextStyle: const TextStyle(fontSize: 13, color: Colors.black87),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      color: Colors.grey.shade900,
    );
    final subtitleStyle = TextStyle(color: Colors.grey.shade700);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Perhitungan"),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoadingLabels
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12.0),
              children: [
                // ===== Banner Ibu Aktif =====
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, color: Colors.indigo),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ibu aktif perangkat: ${_loadingMother ? "…" : (_motherName?.trim().isNotEmpty == true ? _motherName! : "—")}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ====== SECTION 1: SRS ======
                Text(
                  "Tabel Riwayat Perhitungan SRS (Skor Risiko Stunting)",
                  style: titleStyle,
                ),
                const SizedBox(height: 4),
                Text("Sumber data: /srs_calculations", style: subtitleStyle),
                const SizedBox(height: 8),
                _buildSrsTableCard(),

                const SizedBox(height: 18),

                // ====== SECTION 2: Kalkulator ======
                Text(
                  "Tabel Riwayat Kalkulator Gizi/Risiko Stunting",
                  style: titleStyle,
                ),
                const SizedBox(height: 4),
                Text("Sumber data: /calculator_history", style: subtitleStyle),
                const SizedBox(height: 8),
                _buildCalculatorTableCard(),

                const SizedBox(height: 18),

                // ====== SECTION 3: Pemeriksaan Kehamilan ======
                Text("Tabel Riwayat Pemeriksaan Kehamilan", style: titleStyle),
                const SizedBox(height: 4),
                // Keterangan bahwa ID ibu yang tampil adalah kunci Firebase jika nama tidak tersedia
                Text(
                    "Sumber data: /pregnancy_checks/* (Menampilkan ID ibu jika nama ibu tidak tersimpan di record)",
                    style: subtitleStyle),
                const SizedBox(height: 8),
                _buildPregnancyTableCard(),
              ],
            ),
    );
  }

  Widget _buildSrsTableCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: StreamBuilder<DatabaseEvent>(
        stream: _dbRefSrs.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 140,
              child: Center(
                child: Text('Terjadi kesalahan: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const SizedBox(
              height: 100,
              child: Center(child: Text('Belum ada data perhitungan SRS.')),
            );
          }

          final Map<dynamic, dynamic> srsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<SrsRow> rows = srsMap.entries
              .where((e) => e.value is Map)
              .map((e) => SrsRow.fromMap(e.key.toString(), e.value))
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return _scrollableDataTable(
            columns: const [
              DataColumn(label: Text('Waktu')),
              DataColumn(label: Text('Ibu')),
              DataColumn(label: Text('Skor')),
              DataColumn(label: Text('Kategori')),
              DataColumn(label: Text('Detail')),
            ],
            rows: List<DataRow>.generate(rows.length, (index) {
              final r = rows[index];
              final isEven = index % 2 == 0;
              final base = _badgeBase(r.category);
              final textColor = base;

              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>(
                  (states) => isEven ? Colors.grey.shade50 : null,
                ),
                cells: [
                  DataCell(Text(r.formattedDate)),
                  DataCell(Text(r.motherName.isEmpty ? '—' : r.motherName)),
                  DataCell(Text(r.score.toString())),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: base.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: base.withOpacity(0.35)),
                      ),
                      child: Text(
                        r.category,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () => _showSrsDetails(r),
                      tooltip: 'Lihat Detail',
                    ),
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildCalculatorTableCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: StreamBuilder<DatabaseEvent>(
        stream: _dbRefCalc.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 140,
              child: Center(
                child: Text('Terjadi kesalahan: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const SizedBox(
              height: 100,
              child: Center(
                child: Text('Belum ada data perhitungan dari Kalkulator.'),
              ),
            );
          }

          final Map<dynamic, dynamic> calcMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<CalculatorRecord> recs = calcMap.entries
              .where((e) => e.value is Map)
              .map(
                (e) => CalculatorRecord.fromMap(e.key.toString(), e.value),
              )
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return _scrollableDataTable(
            columns: const [
              DataColumn(label: Text('Waktu')),
              DataColumn(label: Text('Skor')),
              DataColumn(label: Text('Kategori')),
              DataColumn(label: Text('Anak (Nama • JK • Usia)')),
              DataColumn(label: Text('Detail')),
            ],
            rows: List<DataRow>.generate(recs.length, (index) {
              final r = recs[index];
              final isEven = index % 2 == 0;
              final base = _badgeBase(r.riskLabel);
              final textColor = base;

              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>(
                  (states) => isEven ? Colors.grey.shade50 : null,
                ),
                cells: [
                  DataCell(Text(r.formattedDate)),
                  DataCell(Text(r.score.toString())),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: base.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: base.withOpacity(0.35)),
                      ),
                      child: Text(
                        r.riskLabel,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(r.childLine)),
                  DataCell(
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () => _showCalcDetails(r),
                      tooltip: 'Lihat Detail',
                    ),
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildPregnancyTableCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: StreamBuilder<DatabaseEvent>(
        stream: _dbRefPreg.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 140,
              child: Center(
                child: Text('Terjadi kesalahan: ${snapshot.error}'),
              ),
            );
          }

          final raw = snapshot.data?.snapshot.value;
          // Pastikan raw adalah Map<dynamic, dynamic> yang valid
          if (raw == null || raw is! Map) {
            return const SizedBox(
              height: 100,
              child: Center(child: Text('Belum ada data pemeriksaan kehamilan.')),
            );
          }

          final Map<dynamic, dynamic> checksByMother = raw;
          final List<PregCheckRow> items = [];
          
          // Iterasi semua node motherId di bawah /pregnancy_checks
          checksByMother.forEach((motherId, motherNode) {
            final String mId = motherId.toString();
            // Pastikan node anak adalah Map (berisi recordId: recordData)
            if (motherNode is Map) {
              final Map<dynamic, dynamic> records = motherNode;
              
              // Iterasi semua record di bawah motherId
              records.forEach((recordId, recordData) {
                if (recordData is Map) {
                  try {
                     items.add(
                      PregCheckRow.fromMap(
                        recordId.toString(),
                        mId,
                        Map<dynamic, dynamic>.from(recordData),
                      ),
                    );
                  } catch (e) {
                    // Cetak error parsing, tapi jangan crash
                    print("Error parsing PregCheckRow for ID $mId/$recordId: $e");
                  }
                }
              });
            }
          });

          if (items.isEmpty) {
            return const SizedBox(
              height: 100,
              child: Center(child: Text('Belum ada data pemeriksaan kehamilan.')),
            );
          }

          items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return _scrollableDataTable(
            columns: const [
              DataColumn(label: Text('Waktu')),
              DataColumn(label: Text('Ibu')), // Menampilkan nama atau ID
              DataColumn(label: Text('Kondisi')),
              DataColumn(label: Text('BMI')),
              DataColumn(label: Text('SRI')),
              DataColumn(label: Text('Kategori')),
              DataColumn(label: Text('Detail')),
            ],
            rows: List<DataRow>.generate(items.length, (index) {
              final r = items[index];
              final isEven = index % 2 == 0;
              final base = _badgeBase(r.category);
              final textColor = base; 

              // Penentuan nama ibu untuk ditampilkan: Nama di record > Nama Ibu Aktif (jika ID cocok) > ID terpotong
              final displayMother = r.motherName.isNotEmpty
                  ? r.motherName
                  : (r.motherId == _motherId && _motherName != null && _motherName!.isNotEmpty) 
                    ? _motherName!
                    : r.motherId.length > 8 ? '${r.motherId.substring(0, 8)}...' : r.motherId;

              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>(
                  (states) => isEven ? Colors.grey.shade50 : null,
                ),
                cells: [
                  DataCell(Text(r.formattedDate)),
                  DataCell(
                    Text(
                      displayMother,
                      // Highlight jika motherId cocok dengan ibu aktif
                      style: (r.motherId == _motherId) ? const TextStyle(fontWeight: FontWeight.bold) : null,
                    ),
                  ), 
                  DataCell(Text(r.conditionLabel)),
                  DataCell(
                    Text(r.bmi == null ? '-' : r.bmi!.toStringAsFixed(1)),
                  ),
                  DataCell(Text(r.sri.toString())),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: base.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: base.withOpacity(0.35)),
                      ),
                      child: Text(
                        r.category,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () => _showPregDetails(r),
                      tooltip: 'Lihat Detail',
                    ),
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}