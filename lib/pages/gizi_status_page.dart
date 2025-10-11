// lib/pages/gizi_status_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/gizi_status_provider.dart';
import '../widgets/custom_text_field.dart'; // Menggunakan widget baru

class GiziStatusPage extends StatefulWidget {
  const GiziStatusPage({super.key});

  @override
  State<GiziStatusPage> createState() => _GiziStatusPageState();
}

class _GiziStatusPageState extends State<GiziStatusPage> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Status Gizi (BB/TB)'),
        backgroundColor: primary,
      ),
      body: Consumer<GiziStatusNotifier>(
        builder: (context, notifier, child) {
          if (notifier.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final child = notifier.selectedChild;
          final sexStr = child?.sex == 'L'
              ? 'Laki-laki'
              : (child?.sex == 'P' ? 'Perempuan' : '—');
          final dobStr = (child?.birthDate == null)
              ? '—'
              : DateFormat('dd/MM/yyyy').format(child!.birthDate!);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ... UI widgets ...
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
                        value: notifier.selectedChildId,
                        decoration: InputDecoration(
                          labelText: 'Pilih Anak',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                          suffixIcon: const Icon(Icons.person_pin_outlined),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        items: notifier.children
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name.isEmpty ? '(Tanpa nama)' : c.name),
                                ))
                            .toList(),
                        onChanged: (v) => notifier.setSelectedChildId(v),
                        validator: (v) => v == null ? 'Wajib pilih anak' : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tgl Lahir: $dobStr | Jenis Kelamin: $sexStr',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (child?.sex.isEmpty == true && child?.id != null)
                        Text(
                          'Jenis kelamin anak belum diisi di Data Anak.',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
              
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
                      CustomTextField(
                        controller: _heightCtrl,
                        labelText: 'Tinggi Badan (cm)',
                        hintText: 'Contoh: 75.5',
                        icon: Icons.height,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _weightCtrl,
                        labelText: 'Berat Badan (kg)',
                        hintText: 'Contoh: 9.2',
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => notifier.calculateGiziStatus(_heightCtrl.text, _weightCtrl.text),
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
                      onPressed: (notifier.giziCategory != '-' && !notifier.saving)
                          ? () async {
                              final success = await notifier.saveGiziResult();
                              if (success) {
                                _showSnackbar('Data Status Gizi berhasil disimpan.');
                              } else {
                                _showSnackbar('Gagal menyimpan data.');
                              }
                            }
                          : null,
                      icon: notifier.saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
              
              _ResultPanel(
                category: notifier.giziCategory,
                zScoreText: notifier.zScoreText,
                resultColor: notifier.resultColor,
                rawZScore: notifier.score,
              ),
            ],
          );
        },
      ),
    );
  }
}
// _ResultPanel widget remains the same as in your original gizi_status_page.dart
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

  String _getInterpretation(double z) {
    if (z > 3) return 'Di atas +3 SD: Kategori obesitas.';
    if (z > 2) return 'Antara +2 hingga +3 SD: Kategori gizi lebih.';
    if (z > 1) return 'Antara +1 hingga +2 SD: Kategori berisiko gizi lebih.';
    if (z > -2) return 'Antara -2 hingga +1 SD: Kategori gizi baik atau normal.';
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