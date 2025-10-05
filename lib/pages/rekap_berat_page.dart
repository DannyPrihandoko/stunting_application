// lib/pages/rekap_berat_page.dart
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

  @override
  void initState() {
    super.initState();
    _listenWeight();
  }

  void _listenWeight() {
    final ref =
        _db.ref('mothers/${widget.motherId}/children/${widget.childId}/weight');
    ref.onValue.listen((evt) {
      final map = <int, double>{};
      if (evt.snapshot.exists && evt.snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(evt.snapshot.value as Map);
        data.forEach((k, v) {
          final age = int.tryParse('$k');
          if (age == null) return;
          if (v is Map) {
            final m = Map<dynamic, dynamic>.from(v);
            final w = (m['weightKg'] == null)
                ? null
                : double.tryParse('${m['weightKg']}');
            if (w != null) map[age] = w;
          }
        });
      }
      if (mounted) {
        setState(() {
          _weights = map;
          _loading = false;
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  int _monthsBetween(DateTime start, DateTime end) {
    int m = (end.year - start.year) * 12 + (end.month - start.month);
    if (end.day < start.day) m -= 1;
    return m;
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
                  builder: (_) => ChildWeightInputPage(
                    presetChildId: widget.childId,
                  ),
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
                  // Judul anak
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text('Tgl lahir: $dobStr • Usia sekarang: ${ageNow < 0 ? 0 : ageNow} bln'),

                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildTable(ageNow),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChildWeightInputPage(
                presetChildId: widget.childId,
              ),
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
      return const Center(
        child: Text('Tanggal lahir anak belum diisi.'),
      );
    }
    if (ageNow <= 0) {
      return const Center(
        child: Text('Belum ada rentang usia (bulan) untuk ditampilkan.'),
      );
    }

    final rows = <DataRow>[];
    for (int m = 1; m <= ageNow; m++) {
      final w = _weights[m];
      rows.add(
        DataRow(
          cells: [
            DataCell(Text('$m')),
            DataCell(Text(w == null ? '—' : NumberFormat('0.0').format(w))),
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
            DataColumn(label: Text('Berat (kg)')),
          ],
          rows: rows,
        ),
      ),
    );
  }
}
