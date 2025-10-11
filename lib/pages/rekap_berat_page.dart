// lib/pages/rekap_berat_page.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'berat_badan_input_page.dart';

class ChildWeightRecapPage extends StatefulWidget {
  const ChildWeightRecapPage({
    super.key,
    required this.motherId,
    required this.childId,
    required this.childName,
    required this.childBirthDateMs,
  });

  final String motherId;
  final String childId;
  final String childName;
  final int? childBirthDateMs;

  @override
  State<ChildWeightRecapPage> createState() => _ChildWeightRecapPageState();
}

class _ChildWeightRecapPageState extends State<ChildWeightRecapPage> {
  final _db = FirebaseDatabase.instance;
  Map<int, double> _weights = {}; // ageMonth -> weightKg
  bool _loading = true;

  StreamSubscription<DatabaseEvent>? _weightSub;

  @override
  void initState() {
    super.initState();
    _listenWeight();
  }

  @override
  void dispose() {
    _weightSub?.cancel();
    super.dispose();
  }

  void _listenWeight() {
    final ref = _db.ref(
      'mothers/${widget.motherId}/children/${widget.childId}/weight',
    );
    // Aktifkan sinkronisasi agar data tersedia offline
    ref.keepSynced(true); 
    _weightSub?.cancel();

    _weightSub = ref.onValue.listen(
      (evt) {
        try {
          final map = <int, double>{};
          final v = evt.snapshot.value;

          if (v is Map) {
            final data = Map<dynamic, dynamic>.from(v);
            data.forEach((k, vv) {
              final age = int.tryParse('$k');
              if (age == null) return;

              double? w;
              if (vv is Map) {
                final m = Map<dynamic, dynamic>.from(vv);
                final raw = m['weightKg'];
                if (raw is num)
                  w = raw.toDouble();
                else
                  w = double.tryParse('$raw');
              } else if (vv is num) {
                w = vv.toDouble();
              } else {
                w = double.tryParse('$vv');
              }

              if (w != null && w.isFinite) map[age] = w;
            });
          }

          if (!mounted) return;
          setState(() {
            _weights = map;
            _loading = false;
          });
        } catch (_) {
          if (mounted) setState(() => _loading = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  int _monthsBetween(DateTime start, DateTime end) {
    int m = (end.year - start.year) * 12 + (end.month - start.month);
    if (end.day < start.day) m -= 1;
    return m;
  }

  List<int> _sortedAges() {
    final ages = _weights.keys.toList()..sort();
    return ages;
  }

  /// Velocity rata-rata (kg/bln) dari ~3 bulan terakhir (atau yang tersedia).
  ({double? v, int spanMonths}) _recentVelocity() {
    final ages = _sortedAges();
    if (ages.length < 2) return (v: null, spanMonths: 0);

    final last = ages.last;
    final targetStart = last - 3;
    int ageStart = ages.first;
    
    // Cari titik data yang terdekat (termasuk) atau sebelum targetStart
    for (int i = ages.length - 1; i >= 0; i--) {
      if (ages[i] <= targetStart) {
        ageStart = ages[i];
        break;
      }
    }
    
    // Jika tidak ada data 3 bulan lalu, ambil data kedua terakhir
    if (ageStart == last && ages.length >= 2) {
      ageStart = ages[ages.length - 2];
    }
    
    // Pastikan titik awal berbeda dari titik akhir
    if (ageStart == last) return (v: null, spanMonths: 0);


    final span = last - ageStart;
    if (span <= 0) return (v: null, spanMonths: 0);

    final wLast = _weights[last]!;
    final wStart = _weights[ageStart]!;
    final v = (wLast - wStart) / span;
    return (v: v, spanMonths: span);
  }

  /// Kisaran laju kenaikan berat "lazim" (kg/bln) (heuristik non-klinis).
  ({double min, double max}) _expectedVelocityBandForAge(int ageMonth) {
    // Pastikan usia tidak di bawah 0
    if (ageMonth < 0) ageMonth = 0;

    // Menyesuaikan rentang usia untuk band kecepatan
    if (ageMonth < 3) return (min: 0.6, max: 1.1); // 0–2 bln
    if (ageMonth < 6) return (min: 0.5, max: 0.8); // 3–5 bln
    if (ageMonth < 12) return (min: 0.3, max: 0.6); // 6–11 bln
    if (ageMonth < 24) return (min: 0.20, max: 0.35); // 12–23 bln
    if (ageMonth < 60) return (min: 0.10, max: 0.25); // 24–59 bln
    return (min: 0.08, max: 0.20); // >= 60 bln
  }

  /// Menghitung risiko gizi berdasarkan laju pertumbuhan dan kelengkapan data.
  /// Output: label, color, summaryText (untuk ditampilkan)
  ({String label, Color color, String summaryText}) _riskHeuristic({
    required int ageNow,
    required int? lastRecordedAge,
    required double? lastWeight, 
    required double? recentVelocity,
    required int spanMonths,
    required double coverage,
  }) {
    // ----------------------------------------------------
    // Cek Data Awal
    // ----------------------------------------------------
    if (_weights.isEmpty || lastRecordedAge == null || lastWeight == null) {
      return (
        label: 'Data terbatas',
        color: Colors.blueGrey,
        summaryText:
            'Data berat badan masih sangat terbatas. Segera input berat badan anak secara rutin setiap bulan untuk memantau risiko.',
      );
    }

    final monthsSinceLast = ageNow - lastRecordedAge;
    final band = _expectedVelocityBandForAge(lastRecordedAge);
    int score = 0; // Skor risiko: 0=Hijau, 1-3=Kuning, >=4=Merah
    String velocityNote = '';
    String recencyNote = '';
    
    // ----------------------------------------------------
    // Penilaian Kecepatan Pertumbuhan (Velocity)
    // ----------------------------------------------------
    if (recentVelocity == null || spanMonths < 2) {
      score += 1; // Data velocity tidak memadai
      velocityNote =
          'Laju pertumbuhan belum dapat dihitung (data <2 titik).';
    } else {
      final vFmt = NumberFormat('0.00').format(recentVelocity);
      final vMinFmt = NumberFormat('0.00').format(band.min);

      if (recentVelocity <= 0.0) {
        // Berat stagnan atau turun: Bahaya!
        score += 3;
        velocityNote =
            '⚠️ **Gagal Tumbuh:** Rata-rata berat stagnan atau turun ($vFmt kg/bln). Ini adalah indikasi risiko gizi buruk dan stunting. Evaluasi dan intervensi gizi segera dibutuhkan.';
      } else if (recentVelocity < band.min * 0.6) {
        // Laju sangat lambat (<60% dari minimum lazim)
        score += 2;
        velocityNote =
            '⚠️ Laju sangat lambat ($vFmt kg/bln). Jauh di bawah minimum lazim ($vMinFmt kg/bln). Perlambatan pertumbuhan signifikan.';
      } else if (recentVelocity < band.min * 0.9) {
        // Laju lambat (60% - 90% dari minimum lazim)
        score += 1;
        velocityNote =
            'Laju melambat ($vFmt kg/bln), mendekati batas bawah lazim ($vMinFmt kg/bln). Perlu pemantauan ketat dan perbaikan asupan gizi.';
      } else {
        velocityNote =
            'Laju kenaikan ($vFmt kg/bln) dalam batas yang diharapkan.';
      }
    }

    // ----------------------------------------------------
    // Penilaian Keterbaruan & Cakupan Data
    // ----------------------------------------------------
    if (monthsSinceLast >= 3) {
      score += 2;
      recencyNote =
          'Terakhir diukur **${monthsSinceLast} bulan lalu**. Periode pertumbuhan yang lama tidak terpantau. Ini sangat meningkatkan risiko deteksi terlambat.';
    } else if (monthsSinceLast == 2) {
      score += 1;
      recencyNote =
          'Terakhir diukur 2 bulan lalu. Pemantauan bulanan disarankan.';
    } else {
      recencyNote = 'Pemantauan baik.';
    }

    // Penyesuaian score berdasarkan coverage (dari total usia anak, dibatasi 5 tahun)
    if (coverage < 0.3)
      score += 1; // Cakupan <30%
    // else if (coverage < 0.6)
    //   score += 1; // Tidak diperlukan, fokus pada risiko tinggi

    // ----------------------------------------------------
    // Finalisasi Kesimpulan (Dipersingkat)
    // ----------------------------------------------------
    String finalSummary =
        '$velocityNote\n**Keterbaruan Data:** $recencyNote\n\n';

    if (score >= 4) {
      return (
        label: 'Merah (Risiko Tinggi)',
        color: Colors.red.shade600,
        summaryText:
            '${finalSummary}Kesimpulan: Pertumbuhan berat badan anak berisiko **tinggi** terhadap masalah gizi, berpotensi mengarah ke stunting/gizi buruk. **Wajib konsultasi dan evaluasi medis/gizi.**',
      );
    } else if (score >= 2) {
      return (
        label: 'Kuning (Pantau Ketat)',
        color: Colors.orange.shade700,
        summaryText:
            '${finalSummary}Kesimpulan: Pertumbuhan berat badan anak perlu **dipantau ketat**. Ada indikasi perlambatan laju. **Tingkatkan frekuensi pemantauan dan asupan gizi optimal.**',
      );
    } else {
      return (
        label: 'Hijau (Sesuai Harapan)',
        color: Colors.green.shade700,
        summaryText:
            '${finalSummary}Kesimpulan: Perkembangan berat badan anak saat ini terpantau **sesuai harapan**. Pertahankan pola makan, stimulasi, dan pemantauan kesehatan rutin.',
      );
    }
  }

  Widget _buildSummaryCard({required DateTime? dob, required int ageNow}) {
    if (dob == null) {
      return const _InfoCard(
        text: 'Tanggal lahir anak belum diisi. Kesimpulan tidak dapat dihitung.',
      );
    }

    if (_weights.isEmpty) {
      return const _InfoCard(
        text: 'Belum ada data berat badan untuk dirangkum.',
      );
    }

    final ages = _sortedAges();
    final lastAge = ages.isEmpty ? null : ages.last;
    final lastWeight = (lastAge == null) ? null : _weights[lastAge];
    
    // Batasi maks usia 5 tahun (60 bulan) untuk coverage
    final maxAgeForCoverage = math.min(ageNow, 60); 
    final coverage = (maxAgeForCoverage <= 0)
        ? 0.0
        : (_weights.length / maxAgeForCoverage).clamp(0.0, 1.0);
    
    final rv = _recentVelocity();
    final band = _expectedVelocityBandForAge(lastAge ?? ageNow);

    final risk = _riskHeuristic(
      ageNow: ageNow,
      lastRecordedAge: lastAge,
      lastWeight: lastWeight,
      recentVelocity: rv.v,
      spanMonths: rv.spanMonths,
      coverage: coverage,
    );

    final monthsSinceLast = (lastAge == null)
        ? null
        : math.max(0, ageNow - lastAge);

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_weight_outlined, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Kesimpulan (Risiko Gizi & Stunting)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: risk.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: risk.color.withOpacity(0.6)),
                  ),
                  child: Text(
                    risk.label,
                    style: TextStyle(
                      color: risk.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Ringkasan Teks Risiko
            Text(
              risk.summaryText,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 20),
            const Text(
              'Detail Pemantauan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _kv(
                  'Berat terakhir',
                  (lastWeight == null || lastAge == null)
                      ? '—'
                      : '${NumberFormat('0.0').format(lastWeight)} kg (usia $lastAge bln)',
                ),
                _kv(
                  'Keterbaruan data',
                  (monthsSinceLast == null)
                      ? '—'
                      : (monthsSinceLast == 0
                            ? 'bulan ini'
                            : '${monthsSinceLast} bln lalu'),
                ),
                _kv(
                  'Cakupan data',
                  '${_weights.length} dari ${maxAgeForCoverage} bln (${NumberFormat.percentPattern('id').format(coverage)})',
                ),
                _kv(
                  'Rata-rata laju terakhir',
                  (rv.v == null)
                      ? '—'
                      : '${NumberFormat('0.00').format(rv.v)} kg/bln (${rv.spanMonths} bln terakhir)',
                ),
                _kv(
                  'Kisaran laju lazim',
                  '${NumberFormat('0.00').format(band.min)}–${NumberFormat('0.00').format(band.max)} kg/bln (usia $lastAge bln)',
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 20),
            const Text(
              'Catatan Penting',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Penilaian di atas bersifat orientatif dan berfokus pada **Gagal Tumbuh**. Untuk klasifikasi gizi yang akurat dan penentuan status stunting, dibutuhkan z-score WHO (WAZ, WHZ/WLZ) dan asesmen tenaga kesehatan.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Flexible(child: Text(v, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dob = (widget.childBirthDateMs == null)
        ? null
        : DateTime.fromMillisecondsSinceEpoch(widget.childBirthDateMs!);

    final now = DateTime.now();
    final ageNow = (dob == null) ? 0 : _monthsBetween(dob, now);
    final title = widget.childName.isEmpty ? '(Tanpa nama)' : widget.childName;
    final dobStr = (dob == null) ? '-' : DateFormat('dd/MM/yyyy').format(dob);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Berat Anak'),
        actions: [
          IconButton(
            tooltip: 'Input Berat',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChildWeightInputPage(presetChildId: widget.childId),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          // Menggunakan SingleChildScrollView untuk seluruh body
          : SingleChildScrollView( 
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tgl lahir: $dobStr • Usia sekarang: ${ageNow < 0 ? 0 : ageNow} bln',
                  ),

                  const SizedBox(height: 12),
                  // Summary Card sekarang ada di dalam SingleChildScrollView
                  _buildSummaryCard(dob: dob, ageNow: ageNow), 
                  const SizedBox(height: 12),
                  // Tabel juga ada di dalam SingleChildScrollView
                  _buildTable(ageNow), 
                  const SizedBox(height: 80), // Padding ekstra untuk FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ChildWeightInputPage(presetChildId: widget.childId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Input Berat'),
      ),
    );
  }

  Widget _buildTable(int ageNow) {
    if (widget.childBirthDateMs == null) {
      return const Center(child: Text('Tanggal lahir anak belum diisi.'));
    }
    if (ageNow <= 0) {
      return const Center(
        child: Text('Belum ada rentang usia (bulan) untuk ditampilkan.'),
      );
    }

    final rows = <DataRow>[];
    // Tampilkan data dari usia sekarang hingga 1 bulan (terbaru di atas)
    for (int m = ageNow; m >= 1; m--) { 
      final w = _weights[m];
      final bool dataExists = w != null;
      final Color? rowColor = dataExists
          ? (m.isEven ? Colors.indigo.shade50 : Colors.white)
          : Colors.red.shade50.withOpacity(0.5); // Baris tanpa data
      rows.add(
        DataRow(
          color: MaterialStateProperty.resolveWith<Color?>((states) => rowColor),
          cells: [
            DataCell(
              Text(
                '$m',
                style: TextStyle(
                  fontWeight: dataExists ? FontWeight.bold : FontWeight.normal,
                  color: dataExists ? Colors.black87 : Colors.red.shade700,
                ),
              ),
            ),
            DataCell(
              Text(
                w == null ? '— (Belum diukur)' : NumberFormat('0.0').format(w),
                style: TextStyle(
                  fontWeight: dataExists ? FontWeight.w600 : FontWeight.w500,
                  color: dataExists ? Colors.black87 : Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Wrap DataTable di dalam Card
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Scroll horizontal untuk DataTable
        child: DataTable(
          columnSpacing: 30,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 40,
          headingRowHeight: 48,
          headingRowColor: MaterialStateProperty.resolveWith<Color?>(
            (states) => Colors.indigo.shade100,
          ),
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.indigo.shade900,
          ),
          columns: const [
            DataColumn(label: Text('Usia (bln)')),
            DataColumn(label: Text('Berat (kg)')),
          ],
          rows: rows,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text),
      ),
    );
  }
}
