import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/mother_profile_repository.dart';

class CekPerkembanganKehamilanPage extends StatefulWidget {
  const CekPerkembanganKehamilanPage({super.key});

  @override
  State<CekPerkembanganKehamilanPage> createState() =>
      _CekPerkembanganKehamilanPageState();
}

class _CekPerkembanganKehamilanPageState
    extends State<CekPerkembanganKehamilanPage> {
  final _formKey = GlobalKey<FormState>();
  final _tinggiCtrl = TextEditingController();
  final _beratCtrl = TextEditingController();
  final _lilaCtrl = TextEditingController();

  // Kondisi: pre, preg_1..preg_9, post
  static final List<String> _condOptions = [
    'pre',
    ...List.generate(9, (i) => 'preg_${i + 1}'),
    'post',
  ];
  String _condValue = 'pre';

  // Hasil
  double? _bmi;
  String _bmiKat = '-';
  bool _tbKurang150 = false;
  bool _lilaRendah = false;

  int _sri = 0;
  String _kategori = '-';
  String _saran = '—';

  // UI / State
  bool _headerCollapsed = false;
  bool _resultCollapsed = false; // <-- baru: panel hasil bisa dikecilkan
  bool _loadingMother = true;
  String? _motherId;
  String? _motherName;

  final _db = FirebaseDatabase.instance;
  final _motherRepo = MotherProfileRepository();

  @override
  void initState() {
    super.initState();
    _initMotherId();
  }

  Future<void> _initMotherId() async {
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
    if (mid == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil Ibu belum dibuat/dipilih di perangkat ini.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tinggiCtrl.dispose();
    _beratCtrl.dispose();
    _lilaCtrl.dispose();
    super.dispose();
  }

  String _condLabel(String v) {
    if (v == 'pre') return 'Sebelum Hamil';
    if (v == 'post') return 'Sesudah Hamil';
    if (v.startsWith('preg_')) {
      final m = int.tryParse(v.split('_').last) ?? 0;
      return 'Hamil Bulan $m';
    }
    return v;
  }

  Map<String, dynamic> _condToPayload(String v) {
    if (v == 'pre') return {'stage': 'pre', 'pregMonth': null};
    if (v == 'post') return {'stage': 'post', 'pregMonth': null};
    if (v.startsWith('preg_')) {
      final m = int.tryParse(v.split('_').last);
      return {'stage': 'preg', 'pregMonth': m};
    }
    return {'stage': 'unknown', 'pregMonth': null};
  }

  void _hitungOnly() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hCm = double.parse(_tinggiCtrl.text.replaceAll(',', '.'));
    final wKg = double.parse(_beratCtrl.text.replaceAll(',', '.'));
    final lilaText = _lilaCtrl.text.trim().isEmpty ? null : _lilaCtrl.text;
    final lila =
        lilaText == null ? null : double.parse(lilaText.replaceAll(',', '.'));

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

    final tbKurang150 = hCm < 150;
    final lilaRendah = (lila != null) ? (lila < 23.5) : false;
    final bmiKurang = bmi < 18.5;

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

  Future<void> _hitungDanSimpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data terlebih dahulu.')),
      );
      return;
    }
    _hitungOnly();

    if (_motherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat menyimpan: Profil Ibu belum dipilih.'),
        ),
      );
      return;
    }

    final hCm = double.parse(_tinggiCtrl.text.replaceAll(',', '.'));
    final wKg = double.parse(_beratCtrl.text.replaceAll(',', '.'));
    final lilaText = _lilaCtrl.text.trim().isEmpty ? null : _lilaCtrl.text;
    final lila =
        lilaText == null ? null : double.parse(lilaText.replaceAll(',', '.'));

    final cond = _condToPayload(_condValue);

    final payload = {
      'timestamp': ServerValue.timestamp,
      'motherId': _motherId,
      'motherName': _motherName ?? '',
      'condition': {
        'raw': _condValue,
        'label': _condLabel(_condValue),
        'stage': cond['stage'],
        'pregMonth': cond['pregMonth'],
      },
      'input': {
        'heightCm': hCm,
        'weightKg': wKg,
        if (lila != null) 'lilaCm': lila,
      },
      'derived': {
        'bmi': _bmi,
        'bmiCategory': _bmiKat,
        'heightUnder150': _tbKurang150,
        'lilaLow': _lilaRendah,
        'sri': _sri,
        'category': _kategori,
      },
      'recommendation': _saran,
    };

    try {
      await _db.ref('pregnancy_checks/$_motherId').push().set(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil dihitung & disimpan.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  void _reset() {
    setState(() {
      _tinggiCtrl.clear();
      _beratCtrl.clear();
      _lilaCtrl.clear();
      _condValue = 'pre';
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
      // Panel hasil tetap di bawah; tak ikut naik saat keyboard tampil
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Cek Perkembangan Kehamilan')),
      body: Column(
        children: [
          // ====== BANNER: collapsible (pakai panah) ======
          AnimatedCrossFade(
            crossFadeState: _headerCollapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            firstChild: _HeaderExpanded(
              onCollapse: () => setState(() => _headerCollapsed = true),
            ),
            secondChild: _HeaderCollapsed(
              onExpand: () => setState(() => _headerCollapsed = false),
            ),
          ),

          // ====== Info Ibu Aktif ======
          if (_loadingMother)
            const LinearProgressIndicator(minHeight: 2)
          else
            Container(
              width: double.infinity,
              color: Colors.orange.withOpacity(0.06),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ibu: ${_motherName?.trim().isNotEmpty == true ? _motherName! : "—"}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // ====== FORM + RIWAYAT ======
          Expanded(
            child: _loadingMother
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Kondisi (per-bulan dan pre/post)
                          Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: DropdownButtonFormField<String>(
                                value: _condValue,
                                items: _condOptions
                                    .map(
                                      (v) => DropdownMenuItem<String>(
                                        value: v,
                                        child: Text(_condLabel(v)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  _condValue = v ?? 'pre';
                                }),
                                decoration: const InputDecoration(
                                  labelText: 'Kondisi Pemeriksaan',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.only(top: 8),
                                ),
                              ),
                            ),
                          ),

                          // Tinggi
                          TextFormField(
                            controller: _tinggiCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Tinggi Badan (cm)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Isi tinggi badan';
                              }
                              final x =
                                  double.tryParse(v.replaceAll(',', '.'));
                              if (x == null || x < 120 || x > 200) {
                                return 'Masukkan 120–200 cm';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Berat
                          TextFormField(
                            controller: _beratCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Berat Badan (kg)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Isi berat badan';
                              }
                              final x =
                                  double.tryParse(v.replaceAll(',', '.'));
                              if (x == null || x < 30 || x > 200) {
                                return 'Masukkan 30–200 kg';
                              }
                              return null;
                            },
                          ),

                          // LILA opsional
                          const SizedBox(height: 12),
                          ExpansionTile(
                            title: const Text('Isian Tambahan (Opsional)'),
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: TextFormField(
                                  controller: _lilaCtrl,
                                  keyboardType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'LILA (cm) — opsional',
                                    hintText:
                                        'Isi bila tersedia (batas < 23.5 cm)',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return null;
                                    }
                                    final x = double.tryParse(
                                        v.replaceAll(',', '.'));
                                    if (x == null || x < 15 || x > 50) {
                                      return 'Masukkan 15–50 cm';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ====== RIWAYAT untuk ibu ini saja ======
                          _buildHistorySection(),
                          const SizedBox(height: 90), // spasi footer
                        ],
                      ),
                    ),
                  ),
          ),

          // ====== PANEL HASIL (fixed & collapsible) ======
          SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Colors.orange.shade200)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  // Header panel hasil + toggle collapse
                  Row(
                    children: [
                      const Icon(Icons.assessment_outlined),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Hasil & Rekomendasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _resultCollapsed = !_resultCollapsed),
                        tooltip: _resultCollapsed ? 'Buka' : 'Kecilkan',
                        icon: Icon(
                          _resultCollapsed
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                        ),
                      ),
                    ],
                  ),

                  // Konten hasil (ringkas saat collapsed)
                  AnimatedCrossFade(
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          child: Text('Rekomendasi:',
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(_saran),
                        ),
                      ],
                    ),
                    secondChild: _CollapsedSummary(
                      kategori: _kategori,
                      sri: _sri,
                      bmi: _bmi,
                    ),
                    crossFadeState: _resultCollapsed
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 180),
                  ),

                  const SizedBox(height: 10),

                  // Tombol aksi
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _hitungDanSimpan,
                          icon: const Icon(Icons.calculate_outlined),
                          label: const Text('Hitung & Simpan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====== HISTORY LIST (untuk motherId ini saja) ======
  Widget _buildHistorySection() {
    if (_motherId == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Riwayat kehamilan akan tampil di sini setelah Profil Ibu di-set pada perangkat ini.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ref = _db.ref('pregnancy_checks/$_motherId').orderByChild('timestamp');

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.10),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              'Riwayat Pemeriksaan Kehamilan — Ibu: ${_motherName?.isNotEmpty == true ? _motherName! : "—"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<DatabaseEvent>(
            stream: ref.onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('Gagal memuat riwayat: ${snapshot.error}'),
                  ),
                );
              }
              if (!snapshot.hasData ||
                  snapshot.data!.snapshot.value == null) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Belum ada data.'),
                );
              }

              final map = Map<dynamic, dynamic>.from(
                  snapshot.data!.snapshot.value as Map);
              final items = map.entries
                  .where((e) => e.value is Map)
                  .map((e) {
                final m = Map<dynamic, dynamic>.from(e.value);
                final ts = (m['timestamp'] is int)
                    ? m['timestamp'] as int
                    : int.tryParse('${m['timestamp']}') ?? 0;
                return {
                  'id': e.key.toString(),
                  'label': (m['condition']?['label'] ?? '-').toString(),
                  'bmi': m['derived']?['bmi'],
                  'sri': m['derived']?['sri'],
                  'cat': (m['derived']?['category'] ?? '-').toString(),
                  'ts': ts,
                };
              }).toList()
                ..sort((a, b) => (b['ts'] as int).compareTo(a['ts'] as int));

              Color badge(String c) {
                final x = c.toString().toLowerCase();
                if (x.contains('tinggi')) return Colors.redAccent;
                if (x.contains('sedang')) return Colors.orange;
                return Colors.green;
              }

              String fmtTs(int ts) {
                if (ts == 0) return '-';
                final d = DateTime.fromMillisecondsSinceEpoch(ts);
                String two(int n) => n.toString().padLeft(2, '0');
                return "${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}";
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final it = items[i];
                  final cat = it['cat'] as String;
                  final c = badge(cat);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.withOpacity(0.15),
                      child: Icon(Icons.monitor_heart, color: c),
                    ),
                    title: Text(it['label'] as String),
                    subtitle: Text(
                      "Waktu: ${fmtTs(it['ts'] as int)}"
                      "\nBMI: ${it['bmi'] == null ? '-' : (it['bmi'] as num).toStringAsFixed(1)} • "
                      "SRI: ${it['sri'] ?? '-'}",
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.withOpacity(0.35)),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ====== Header (expand/collapse) dengan ikon panah ======
class _HeaderExpanded extends StatelessWidget {
  const _HeaderExpanded({required this.onCollapse});
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange.withOpacity(0.12),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Pantau indikator ibu untuk perkembangan kehamilan:\n'
              '• Tinggi <150 cm  • BMI <18.5  • LILA <23.5 cm\n'
              'Heuristik skrining risiko stunting (bukan diagnosis klinis).',
              textAlign: TextAlign.left,
            ),
          ),
          IconButton(
            tooltip: 'Kecilkan',
            onPressed: onCollapse,
            icon: const Icon(Icons.keyboard_arrow_up, color: Colors.orange),
          )
        ],
      ),
    );
  }
}

class _HeaderCollapsed extends StatelessWidget {
  const _HeaderCollapsed({required this.onExpand});
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      width: double.infinity,
      child: Row(
        children: [
          const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Info skrining ibu (dikecilkan)',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onExpand,
            child: const Text('Buka'),
          ),
        ],
      ),
    );
  }
}

class _CollapsedSummary extends StatelessWidget {
  final String kategori;
  final int sri;
  final double? bmi;
  const _CollapsedSummary({
    required this.kategori,
    required this.sri,
    required this.bmi,
  });

  Color _badgeColor(String label) {
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
    final c = _badgeColor(kategori);
    final bmiTxt = (bmi == null) ? '-' : bmi!.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: c.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              kategori,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "SRI: $sri • BMI: $bmiTxt",
              style: const TextStyle(fontWeight: FontWeight.w600),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _warnaKategori(kategori),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  kategori,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
