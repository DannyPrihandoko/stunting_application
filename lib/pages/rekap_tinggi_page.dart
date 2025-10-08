// lib/pages/rekap_tinggi_page.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'tinggi_badan_input_page.dart';

class ChildGrowthRecapPage extends StatefulWidget {
  const ChildGrowthRecapPage({
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
  State<ChildGrowthRecapPage> createState() => _ChildGrowthRecapPageState();
}

class _ChildGrowthRecapPageState extends State<ChildGrowthRecapPage> {
  final _db = FirebaseDatabase.instance;
  Map<int, double> _heights = {}; // ageMonth -> heightCm
  bool _loading = true;

  StreamSubscription<DatabaseEvent>? _growthSub;

  @override
  void initState() {
    super.initState();
    _listenGrowth();
  }

  @override
  void dispose() {
    _growthSub?.cancel();
    super.dispose();
  }

  void _listenGrowth() {
    final ref = _db.ref(
      'mothers/${widget.motherId}/children/${widget.childId}/growth',
    );
    ref.keepSynced(true);
    _growthSub?.cancel();

    _growthSub = ref.onValue.listen(
      (evt) {
        try {
          final map = <int, double>{};
          final v = evt.snapshot.value;

          if (v is Map) {
            final data = Map<dynamic, dynamic>.from(v);
            data.forEach((k, vv) {
              final age = int.tryParse('$k');
              if (age == null) return;

              double? h;
              if (vv is Map) {
                final m = Map<dynamic, dynamic>.from(vv);
                final raw = m['heightCm'];
                if (raw is num)
                  h = raw.toDouble();
                else
                  h = double.tryParse('$raw');
              } else if (vv is num) {
                h = vv.toDouble();
              } else {
                h = double.tryParse('$vv');
              }

              if (h != null && h.isFinite) map[age] = h;
            });
          }

          if (!mounted) return;
          setState(() {
            _heights = map;
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
    final ages = _heights.keys.toList()..sort();
    return ages;
  }

  /// Velocity rata-rata (cm/bln) dari ~3 bulan terakhir (atau yang tersedia).
  ({double? v, int spanMonths}) _recentVelocity() {
    final ages = _sortedAges();
    if (ages.length < 2) return (v: null, spanMonths: 0);

    final last = ages.last;
    final targetStart = last - 3;
    int ageStart = ages.first;
    for (final a in ages) {
      if (a >= targetStart) {
        ageStart = a;
        break;
      }
    }
    if (ageStart == last && ages.length >= 2) {
      ageStart = ages[ages.length - 2];
    }

    final span = last - ageStart;
    if (span <= 0) return (v: null, spanMonths: 0);

    final hLast = _heights[last]!;
    final hStart = _heights[ageStart]!;
    final v = (hLast - hStart) / span;
    return (v: v, spanMonths: span);
  }

  /// Kisaran laju "lazim" (cm/bln) per kelompok usia (heuristik non-klinis).
  ({double min, double max}) _expectedVelocityBandForAge(int ageMonth) {
    if (ageMonth < 6) return (min: 1.5, max: 2.5);
    if (ageMonth < 12) return (min: 1.0, max: 1.5);
    if (ageMonth < 24) return (min: 0.6, max: 1.0);
    if (ageMonth <= 60) return (min: 0.4, max: 0.7);
    return (min: 0.3, max: 0.5);
  }

  ({String label, Color color}) _riskHeuristic({
    required int ageNow,
    required int? lastRecordedAge,
    required double? recentVelocity,
    required int spanMonths,
    required double coverage,
  }) {
    if (_heights.isEmpty || lastRecordedAge == null) {
      return (label: 'Data terbatas', color: Colors.blueGrey);
    }

    final monthsSinceLast = ageNow - lastRecordedAge;
    final band = _expectedVelocityBandForAge(lastRecordedAge);
    int score = 0;

    if (recentVelocity == null || spanMonths == 0) {
      score += 1;
    } else {
      if (recentVelocity <= 0.0)
        score += 3;
      else if (recentVelocity < band.min * 0.6)
        score += 2;
      else if (recentVelocity < band.min * 0.9)
        score += 1;
    }

    if (monthsSinceLast >= 3)
      score += 2;
    else if (monthsSinceLast == 2)
      score += 1;

    if (coverage < 0.3)
      score += 2;
    else if (coverage < 0.6)
      score += 1;

    if (score >= 4) {
      return (label: 'Merah (butuh evaluasi)', color: Colors.red.shade600);
    } else if (score >= 2) {
      return (label: 'Kuning (pantau ketat)', color: Colors.orange.shade700);
    } else {
      return (label: 'Hijau (sesuai harapan)', color: Colors.green.shade700);
    }
  }

  Widget _buildSummaryCard({required DateTime? dob, required int ageNow}) {
    if (dob == null) {
      return Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Tanggal lahir anak belum diisi. Kesimpulan tidak dapat dihitung.',
          ),
        ),
      );
    }

    if (_heights.isEmpty) {
      return Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Belum ada data tinggi untuk dirangkum.'),
        ),
      );
    }

    final ages = _sortedAges();
    final lastAge = ages.isEmpty ? null : ages.last;
    final lastHeight = (lastAge == null) ? null : _heights[lastAge];
    final coverage = (ageNow <= 0)
        ? 0.0
        : (_heights.length / ageNow).clamp(0.0, 1.0);
    final rv = _recentVelocity();
    final band = _expectedVelocityBandForAge(lastAge ?? ageNow);

    final risk = _riskHeuristic(
      ageNow: ageNow,
      lastRecordedAge: lastAge,
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
                const Icon(Icons.insights_outlined, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Kesimpulan (konteks stunting)',
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
            Wrap(
              runSpacing: 6,
              children: [
                _kv(
                  'Tinggi terakhir',
                  (lastHeight == null || lastAge == null)
                      ? '—'
                      : '${NumberFormat('0.0').format(lastHeight)} cm (usia $lastAge bln)',
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
                  '${_heights.length} dari ${ageNow < 0 ? 0 : ageNow} bln (${NumberFormat.percentPattern('id').format(coverage)})',
                ),
                _kv(
                  'Rata-rata laju terakhir',
                  (rv.v == null)
                      ? '—'
                      : '${NumberFormat('0.00').format(rv.v)} cm/bln (${rv.spanMonths} bln terakhir)',
                ),
                _kv(
                  'Kisaran laju lazim (heuristik)',
                  '${NumberFormat('0.0').format(band.min)}–${NumberFormat('0.0').format(band.max)} cm/bln',
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 20),
            const Text(
              'Catatan penting',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Indikasi di atas bersifat orientatif. Untuk menilai stunting secara akurat diperlukan perhitungan z-score tinggi-menurut-umur (HAZ) '
              'berdasarkan standar WHO dan jenis kelamin anak, serta penilaian tenaga kesehatan.',
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
        Flexible(child: Text(v)),
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
        title: const Text('Rekap Tinggi Anak'),
        actions: [
          IconButton(
            tooltip: 'Input Tinggi',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChildHeightInputPage(presetChildId: widget.childId),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                  _buildSummaryCard(dob: dob, ageNow: ageNow),
                  const SizedBox(height: 12),
                  Expanded(child: _buildTable(ageNow)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ChildHeightInputPage(presetChildId: widget.childId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Input Tinggi'),
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
    for (int m = 1; m <= ageNow; m++) {
      final h = _heights[m];
      rows.add(
        DataRow(
          cells: [
            DataCell(Text('$m')),
            DataCell(Text(h == null ? '—' : NumberFormat('0.0').format(h))),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: MaterialStateProperty.resolveWith<Color?>(
            (states) => Colors.blueGrey.shade50,
          ),
          columns: const [
            DataColumn(label: Text('Usia (bln)')),
            DataColumn(label: Text('Tinggi (cm)')),
          ],
          rows: rows,
        ),
      ),
    );
  }
}
