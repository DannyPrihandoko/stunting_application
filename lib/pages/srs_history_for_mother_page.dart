// lib/pages/srs_history_for_mother_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'srs_history_page.dart'; // Impor untuk menggunakan model SrsRow

class SrsHistoryForMotherPage extends StatefulWidget {
  final String motherId;
  final String motherName;

  const SrsHistoryForMotherPage({
    super.key,
    required this.motherId,
    required this.motherName,
  });

  @override
  State<SrsHistoryForMotherPage> createState() =>
      _SrsHistoryForMotherPageState();
}

class _SrsHistoryForMotherPageState extends State<SrsHistoryForMotherPage> {
  late final Stream<DatabaseEvent> _srsStream;
  Map<String, String> _rfLabels = {};
  bool _isLoadingLabels = true;

  @override
  void initState() {
    super.initState();
    _loadRiskLabels(); // Muat label faktor risiko

    // Query data SRS dan filter berdasarkan 'mother/ownerId'
    final ref = FirebaseDatabase.instance
        .ref("srs_calculations")
        .orderByChild('mother/ownerId')
        .equalTo(widget.motherId);

    _srsStream = ref.onValue;
  }

  Future<void> _loadRiskLabels() async {
    try {
      final snap = await FirebaseDatabase.instance.ref("risk_factors").get();
      if (snap.exists && snap.value != null) {
        final data = snap.value as Map<dynamic, dynamic>;
        final Map<String, String> labels = {};

        void absorb(dynamic section) {
          if (section is Map) {
            section.forEach((k, v) {
              if (v is Map && v['label'] != null) {
                labels["$k"] = "${v['label']}";
              }
            });
          }
        }

        absorb(data['weight_2']);
        absorb(data['weight_1']);
        if (mounted) {
          setState(() {
            _rfLabels = labels;
            _isLoadingLabels = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingLabels = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLabels = false);
    }
  }

  Color _badgeBase(String s) {
    final x = s.toLowerCase();
    if (x.contains('tinggi')) return Colors.red;
    if (x.contains('sedang')) return Colors.orange;
    return Colors.green;
  }

  String _labelOf(String key) => _rfLabels[key] ?? key.replaceAll('_', ' ');

  void _showSrsDetailsDialog(SrsRow r) {
    final formattedDateTime = DateFormat(
      'EEEE, dd MMMM yyyy HH:mm',
      'id_ID',
    ).format(DateTime.fromMillisecondsSinceEpoch(r.timestamp).toLocal());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Detail Perhitungan SRS"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Waktu", "$formattedDateTime WIB"),
              _detailRow("Ibu", r.motherName.isEmpty ? "—" : r.motherName),
              const Divider(height: 16),
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
                "Faktor Risiko Bobot 2 (Terpilih)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...r.w2.entries
                  .where((e) => e.value)
                  .map((e) => Text("• ${_labelOf(e.key)}")),
              if (r.w2.entries.every((e) => !e.value)) const Text("Tidak ada."),
              const SizedBox(height: 10),
              const Text(
                "Faktor Risiko Bobot 1 (Terpilih)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...r.w1.entries
                  .where((e) => e.value)
                  .map((e) => Text("• ${_labelOf(e.key)}")),
              if (r.w1.entries.every((e) => !e.value)) const Text("Tidak ada."),
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
            width: 100,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Riwayat SRS: ${widget.motherName}')),
      body: _isLoadingLabels
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DatabaseEvent>(
              stream: _srsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null ||
                    snapshot.data!.snapshot.value is! Map) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Belum ada riwayat SRS untuk ibu ini.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final srsMap = Map<dynamic, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );
                final List<SrsRow> rows =
                    srsMap.entries
                        .where((e) => e.value is Map)
                        .map((e) => SrsRow.fromMap(e.key.toString(), e.value))
                        .toList()
                      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                if (rows.isEmpty) {
                  return const Center(
                    child: Text('Belum ada riwayat SRS untuk ibu ini.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final r = rows[index];
                    final base = _badgeBase(r.category);

                    // --- PERUBAHAN FORMAT TANGGAL DI SINI ---
                    final formattedDateTime =
                        DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            r.timestamp,
                          ).toLocal(),
                        );

                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: base.withOpacity(0.15),
                          child: Icon(Icons.assessment, color: base),
                        ),
                        title: Text('${formattedDateTime} WIB'),
                        subtitle: Text('Skor: ${r.score}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            r.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => _showSrsDetailsDialog(r),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
