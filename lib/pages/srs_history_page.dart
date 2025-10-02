// lib/pages/srs_history_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:stunting_application/models/srs_record.dart'; // Sesuaikan path ini
import 'package:stunting_application/models/risk_factor.dart'; // Import model RiskFactor

/// Halaman untuk menampilkan riwayat perhitungan Skor Risiko Stunting (SRS) dalam tabel.
class SrsHistoryPage extends StatefulWidget {
  const SrsHistoryPage({super.key});

  @override
  State<SrsHistoryPage> createState() => _SrsHistoryPageState();
}

class _SrsHistoryPageState extends State<SrsHistoryPage> {
  final DatabaseReference _dbRefSrsCalculations =
      FirebaseDatabase.instance.ref("srs_calculations");
  final DatabaseReference _dbRefRiskFactorsConfig =
      FirebaseDatabase.instance.ref("risk_factors");

  // Untuk menyimpan konfigurasi faktor risiko agar bisa menampilkan label
  Map<String, RiskFactor> _allRiskFactors = {};
  bool _isLoadingConfig = true; // State untuk loading konfigurasi

  @override
  void initState() {
    super.initState();
    _loadRiskFactorsConfig(); // Muat konfigurasi faktor risiko saat halaman diinisialisasi
  }

  /// Fungsi untuk memuat definisi faktor risiko dari Firebase Realtime Database
  /// Ini akan digunakan untuk mencari label berdasarkan key faktor risiko yang disimpan.
  Future<void> _loadRiskFactorsConfig() async {
    try {
      final snapshot = await _dbRefRiskFactorsConfig.get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        Map<String, RiskFactor> loadedFactors = {};

        if (data['weight_2'] != null) {
          (data['weight_2'] as Map<dynamic, dynamic>).forEach((key, value) {
            loadedFactors[key.toString()] = RiskFactor.fromMap(key.toString(), value);
          });
        }
        if (data['weight_1'] != null) {
          (data['weight_1'] as Map<dynamic, dynamic>).forEach((key, value) {
            loadedFactors[key.toString()] = RiskFactor.fromMap(key.toString(), value);
          });
        }

        setState(() {
          _allRiskFactors = loadedFactors;
          _isLoadingConfig = false;
        });
      } else {
        print('Tidak ada data konfigurasi risk_factors di Firebase.');
        setState(() {
          _isLoadingConfig = false;
        });
      }
    } catch (e) {
      print('Error memuat konfigurasi risk_factors: $e');
      setState(() {
        _isLoadingConfig = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat konfigurasi faktor risiko: $e')),
      );
    }
  }

  // Fungsi helper untuk mendapatkan label dari key faktor risiko
  String _getRiskFactorLabel(String key) {
    return _allRiskFactors[key]?.label ?? key.replaceAll('_', ' '); // Fallback ke key jika tidak ditemukan
  }

  // Fungsi untuk menampilkan dialog detail catatan SRS
  void _showDetailsDialog(SrsRecord record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Detail Perhitungan SRS"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow("Waktu:", record.formattedDate),
                _buildDetailRow("Skor:", record.score.toString()),
                _buildDetailRow("Kategori:", record.category),
                _buildDetailRow("Rekomendasi:", record.recommendation),
                const Divider(),
                const Text(
                  "Faktor Risiko Bobot 2:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...record.riskFactorsWeight2.entries
                    .where((entry) => entry.value)
                    .map((entry) => Text("• ${_getRiskFactorLabel(entry.key)}"))
                    .toList(),
                if (record.riskFactorsWeight2.entries.every((element) => !element.value))
                  const Text("Tidak ada faktor bobot 2 yang terpilih."),
                const SizedBox(height: 10),
                const Text(
                  "Faktor Risiko Bobot 1:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...record.riskFactorsWeight1.entries
                    .where((entry) => entry.value)
                    .map((entry) => Text("• ${_getRiskFactorLabel(entry.key)}"))
                    .toList(),
                 if (record.riskFactorsWeight1.entries.every((element) => !element.value))
                  const Text("Tidak ada faktor bobot 1 yang terpilih."),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }

  // Helper untuk membangun baris detail di dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Perhitungan SRS"),
        backgroundColor: Colors.indigo.shade700, // Warna tema untuk halaman ini
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoadingConfig
          ? const Center(child: CircularProgressIndicator()) // Tampilkan loading saat memuat konfigurasi
          : StreamBuilder(
              stream: _dbRefSrsCalculations.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("Error mengambil riwayat SRS: ${snapshot.error}");
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('Belum ada data perhitungan SRS.'));
                }

                final Map<dynamic, dynamic> srsMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<SrsRecord> srsRecords = [];

                srsMap.forEach((key, value) {
                  srsRecords.add(SrsRecord.fromMap(key.toString(), value));
                });

                srsRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                // Tema DataTable yang lebih menarik
                return Container(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias, // Penting untuk border radius pada DataTable
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          columnSpacing: 20, // Jarak antar kolom
                          dataRowMinHeight: 45,
                          dataRowMaxHeight: 60,
                          headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) => Colors.indigo.shade50), // Warna header
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                            fontSize: 14,
                          ),
                          dataTextStyle: const TextStyle(fontSize: 13, color: Colors.black87),
                          // Warna latar belakang baris bergantian
                          dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              // Ini adalah cara yang benar dan lebih sederhana untuk warna bergantian
                              if (states.contains(MaterialState.selected)) {
                                return Colors.indigo.shade100;
                              }
                              // Dapatkan indeks baris dari data asli, bukan dari MaterialState.selected
                              // Kita tidak bisa langsung mendapatkan index dari `states`,
                              // jadi kita akan mengimplementasikan logika warna bergantian di DataRow.
                              return null; // Akan dihandle di DataRow
                            },
                          ),
                          columns: const [
                            DataColumn(label: Text('Waktu')),
                            DataColumn(label: Text('Skor')),
                            DataColumn(label: Text('Kategori')),
                            DataColumn(label: Text('Detail')), // Kolom baru untuk tombol detail
                          ],
                          rows: List<DataRow>.generate(srsRecords.length, (index) {
                            final record = srsRecords[index];
                            final isEvenRow = index % 2 == 0; // Tentukan apakah baris genap

                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.indigo.shade100; // Warna saat dipilih
                                  }
                                  return isEvenRow ? Colors.grey.shade50 : null; // Warna bergantian
                                },
                              ),
                              cells: [
                                DataCell(Text(record.formattedDate)),
                                DataCell(Text(record.score.toString())),
                                DataCell(Text(record.category)),
                                DataCell(
                                  IconButton(
                                    icon: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                                    onPressed: () => _showDetailsDialog(record),
                                    tooltip: 'Lihat Detail',
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
