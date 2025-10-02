import 'package:flutter/material.dart';

class CekPerkembanganKehamilanPage extends StatefulWidget {
  const CekPerkembanganKehamilanPage({super.key});

  @override
  State<CekPerkembanganKehamilanPage> createState() => _CekPerkembanganKehamilanPageState();
}

class _CekPerkembanganKehamilanPageState extends State<CekPerkembanganKehamilanPage> {
  final _formKey = GlobalKey<FormState>();
  final _tinggiCtrl = TextEditingController();
  final _beratCtrl = TextEditingController();
  final _lilaCtrl  = TextEditingController(); // opsional

  String _kondisi = 'Sebelum Hamil';

  double? _bmi;
  String _bmiKat = '-';
  bool _tbKurang150 = false;   // Tinggi badan < 150 cm
  bool _lilaRendah = false;

  int _sri = 0;          // Skor Risiko Ibu (heuristik)
  String _kategori = '-';
  String _saran = '—';

  @override
  void dispose() {
    _tinggiCtrl.dispose();
    _beratCtrl.dispose();
    _lilaCtrl.dispose();
    super.dispose();
  }

  void _hitung() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hCm = double.parse(_tinggiCtrl.text.replaceAll(',', '.'));
    final wKg = double.parse(_beratCtrl.text.replaceAll(',', '.'));
    final lilaText = _lilaCtrl.text.trim().isEmpty ? null : _lilaCtrl.text;
    final lila = lilaText == null ? null : double.parse(lilaText.replaceAll(',', '.'));

    final hM = hCm / 100.0;
    final bmi = wKg / (hM * hM);

    String bmiKat;
    if (bmi < 18.5) {
      bmiKat = 'Kurang (<18.5)';
    } else if (bmi < 25) {
      bmiKat = 'Normal (18.5–24.9)';
    } else if (bmi < 30) {
      bmiKat = 'Berlebih (25–29.9)';
    } else {
      bmiKat = 'Obesitas (≥30)';
    }

    final tbKurang150 = hCm < 150;              // determinan kuat (istilah netral)
    final lilaRendah = (lila != null) ? (lila < 23.5) : false;
    final bmiKurang = bmi < 18.5;

    // Heuristik programatik berbasis ringkasan jurnal
    final sri = (tbKurang150 ? 2 : 0) + (bmiKurang ? 2 : 0) + (lilaRendah ? 1 : 0);

    String kategori, saran;
    if (sri >= 4) {
      kategori = 'Tinggi';
      saran =
          'Pendampingan intensif: konseling gizi pra/awal kehamilan, protein hewani harian, '
          'tablet tambah darah, rujuk bila ada infeksi, dan perbaikan WASH di rumah.';
    } else if (sri >= 2) {
      kategori = 'Sedang';
      saran =
          'Kelas ibu & monitoring bulanan, perbaiki menu (hewani + sayur/buah), '
          'pantau berat berkala, cek kepatuhan TTD.';
    } else {
      kategori = 'Rendah';
      saran = 'Edukasi universal & pemantauan rutin (posyandu/ANC).';
    }

    setState(() {
      _bmi = bmi;
      _bmiKat = bmiKat;
      _tbKurang150 = tbKurang150;
      _lilaRendah = lilaRendah;
      _sri = sri;
      _kategori = kategori;
      _saran = saran;
    });
  }

  void _reset() {
    _formKey.currentState?.reset();
    _tinggiCtrl.clear();
    _beratCtrl.clear();
    _lilaCtrl.clear();
    setState(() {
      _kondisi = 'Sebelum Hamil';
      _bmi = null;
      _bmiKat = '-';
      _tbKurang150 = false;
      _lilaRendah = false;
      _sri = 0;
      _kategori = '-';
      _saran = '—';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cek Perkembangan Kehamilan')),
      body: Column(
        children: [
          // Header ringkas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange.withOpacity(0.15),
            child: const Text(
              'Pantau indikator ibu untuk perkembangan kehamilan:\n'
              '• Tinggi badan <150 cm  • BMI <18.5  • LILA <23.5 cm\n'
              'Heuristik skrining risiko stunting (bukan diagnosis klinis).',
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Kondisi Pemeriksaan
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: DropdownButtonFormField<String>(
                          initialValue: _kondisi,
                          items: const [
                            DropdownMenuItem(value: 'Sebelum Hamil', child: Text('Sebelum Hamil')),
                            DropdownMenuItem(value: 'Trimester 1', child: Text('Trimester 1')),
                            DropdownMenuItem(value: 'Trimester 2', child: Text('Trimester 2')),
                            DropdownMenuItem(value: 'Trimester 3', child: Text('Trimester 3')),
                          ],
                          onChanged: (v) => setState(() => _kondisi = v ?? 'Sebelum Hamil'),
                          decoration: const InputDecoration(
                            labelText: 'Kondisi Pemeriksaan',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(top: 8),
                          ),
                        ),
                      ),
                    ),

                    // Tinggi & Berat
                    TextFormField(
                      controller: _tinggiCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Tinggi Badan (cm)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Isi tinggi badan';
                        final x = double.tryParse(v.replaceAll(',', '.'));
                        if (x == null || x < 120 || x > 200) return 'Masukkan 120–200 cm';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _beratCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Berat Badan (kg)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Isi berat badan';
                        final x = double.tryParse(v.replaceAll(',', '.'));
                        if (x == null || x < 30 || x > 200) return 'Masukkan 30–200 kg';
                        return null;
                      },
                    ),

                    // Opsional: LILA
                    const SizedBox(height: 12),
                    ExpansionTile(
                      title: const Text('Isian Tambahan (Opsional)'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: TextFormField(
                            controller: _lilaCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'LILA (cm) — opsional',
                              hintText: 'Diisi bila tersedia (batas < 23.5 cm)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final x = double.tryParse(v.replaceAll(',', '.'));
                              if (x == null || x < 15 || x > 50) return 'Masukkan 15–50 cm';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ),

          // Panel hasil + tombol
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.orange.shade200)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                _BarHasil(
                  bmi: _bmi,
                  bmiKat: _bmiKat,
                  tbKurang150: _tbKurang150,
                  lilaRendah: _lilaRendah,
                  sri: _sri,
                  kategori: _kategori,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Rekomendasi:', style: Theme.of(context).textTheme.titleMedium),
                ),
                Align(alignment: Alignment.centerLeft, child: Text(_saran)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _hitung,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Hitung'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // tempat integrasi penyimpanan (API/DB) bila diperlukan
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data disimpan (contoh)')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Simpan'),
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
}

class _BarHasil extends StatelessWidget {
  final double? bmi;
  final String bmiKat;
  final bool tbKurang150;
  final bool lilaRendah;
  final int sri;
  final String kategori;
  const _BarHasil({
    required this.bmi,
    required this.bmiKat,
    required this.tbKurang150,
    required this.lilaRendah,
    required this.sri,
    required this.kategori,
  });

  Color _warnaKategori(String label) {
    switch (label) {
      case 'Tinggi':
        return Colors.red;
      case 'Sedang':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bmiTxt = (bmi == null) ? '-' : bmi!.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.monitor_weight),
            const SizedBox(width: 8),
            Text('BMI: $bmiTxt  ($bmiKat)'),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.straighten),
            const SizedBox(width: 8),
            Text('Tinggi badan <150 cm: ${tbKurang150 ? "Ya" : "Tidak"}'),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.accessibility_new),
            const SizedBox(width: 8),
            Text('LILA rendah: ${lilaRendah ? "Ya (<23.5 cm)" : "Tidak/tdk diisi"}'),
          ]),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.assessment),
              const SizedBox(width: 8),
              Expanded(child: Text('Skor Risiko Ibu (SRI): $sri')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _warnaKategori(kategori),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  kategori,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
