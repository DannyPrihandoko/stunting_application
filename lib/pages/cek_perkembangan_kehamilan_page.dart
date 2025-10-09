// lib/pages/cek_perkembangan_kehamilan_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/mother_profile_repository.dart';
import 'profil_bunda_page.dart'; // Diperlukan untuk navigasi ke halaman profil

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
  // Header disembunyikan secara default
  bool _headerCollapsed = true;
  bool _resultCollapsed = false;
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

  /// Memuat profil ibu dari repo lokal/Firebase.
  /// Dipanggil tanpa await untuk menghindari UI stuck saat offline.
  /// Jika gagal (offline), _motherId tetap null, tapi app jalan.
  Future<void> _initMotherId() async {
    try {
      final mid = await _motherRepo.getCurrentId();
      String? name;
      if (mid != null) {
        // Karena persistence sudah aktif, ini akan mencoba read dari cache dulu.
        final prof = await _motherRepo.read(mid);
        name = prof?.nama;
      }
      if (!mounted) return;
      setState(() {
        _motherId = mid;
        _motherName = name;
      });
    } catch (e) {
      // Log error, tapi biarkan _motherId dan _motherName menjadi null
      // agar aplikasi tetap dapat diakses offline untuk perhitungan.
      // print('Gagal memuat profil ibu: $e');
    } finally {
      if (mounted) setState(() => _loadingMother = false);
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
    final lilaText = _lilaCtrl.text.trim().replaceAll(',', '.');
    final lila = double.parse(lilaText); // LILA sudah wajib & tervalidasi

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
    final lilaRendah = lila < 23.5;
    final bmiKurang = bmi < 18.5;

    // SRI (Skor Risiko Ibu)
    final sri =
        (tbKurang150 ? 2 : 0) + (bmiKurang ? 2 : 0) + (lilaRendah ? 1 : 0);

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
      // Set hasil collapse ke false agar hasil langsung terlihat
      _resultCollapsed = false;
    });
  }

  Future<void> _hitungDanSimpan() async {
    // 1. Lakukan perhitungan dulu, sekaligus validasi form
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi data terlebih dahulu.')),
        );
      }
      return;
    }
    _hitungOnly(); // Lakukan perhitungan lokal

    // 2. Jika profil ibu tidak ada, informasikan, tapi jangan hentikan perhitungan.
    if (_motherId == null) {
      final go = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Profil Ibu Belum Ada'),
          content: const Text(
            'Untuk menyimpan riwayat, Anda perlu mengisi Profil Bunda.\n\nIsi/ pilih profil ibu sekarang?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Hitung Saja (Tidak Simpan)'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Isi Profil Ibu'),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilBundaPage()),
        );
        await _initMotherId(); // Coba muat ulang profil setelah kembali
      }
      if (_motherId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hanya menghitung lokal. Data tidak disimpan.'),
            ),
          );
        }
        return;
      }
    }

    // Lanjutkan penyimpanan (jika _motherId tidak null)
    final hCm = double.parse(_tinggiCtrl.text.replaceAll(',', '.'));
    final wKg = double.parse(_beratCtrl.text.replaceAll(',', '.'));
    final lila = double.parse(
      _lilaCtrl.text.trim().replaceAll(',', '.'),
    ); // LILA sudah wajib

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
        'lilaCm': lila, // LILA selalu ada
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
      // Penyimpanan ini otomatis diantri secara lokal (offline caching)
      await _db.ref('pregnancy_checks/$_motherId').push().set(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Berhasil dihitung & disimpan. (Akan sinkron saat online).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan ke DB: $e')));
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Cek Perkembangan Kehamilan')),
      body: Column(
        children: [
          // ====== BANNER: Header (Collapsed Default) ======
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

          // ====== Info Ibu Aktif (Aman Luring) ======
          Container(
            width: double.infinity,
            color: Colors.orange.withOpacity(0.06),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: _loadingMother
                      ? const Text(
                          'Memuat profil ibu...',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        )
                      : Text(
                          'Ibu: ${_motherName?.trim().isNotEmpty == true ? _motherName! : "— (Profil belum di-set)"}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),

          // ====== FORM + RIWAYAT ======
          Expanded(
            // Abaikan status _loadingMother untuk SingleChildScrollView agar form tetap bisa diakses offline
            child: SingleChildScrollView(
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
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tinggi Badan (cm)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Isi tinggi badan';
                        }
                        final x = double.tryParse(v.replaceAll(',', '.'));
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Berat Badan (kg)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Isi berat badan';
                        }
                        final x = double.tryParse(v.replaceAll(',', '.'));
                        if (x == null || x < 30 || x > 200) {
                          return 'Masukkan 30–200 kg';
                        }
                        return null;
                      },
                    ),

                    // LILA (Wajib Diisi, tidak pakai ExpansionTile)
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lilaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'LILA (cm)',
                        hintText: 'Wajib diisi (batas < 23.5 cm)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'LILA wajib diisi';
                        }
                        final x = double.tryParse(v.replaceAll(',', '.'));
                        if (x == null || x < 15 || x > 50) {
                          return 'Masukkan 15–50 cm';
                        }
                        return null;
                      },
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
                        onPressed: () => setState(
                          () => _resultCollapsed = !_resultCollapsed,
                        ),
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
                          child: Text(
                            'Rekomendasi:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
    // Jika ID Ibu belum terdeteksi, tampilkan pesan informatif.
    // Ini penting agar aplikasi tidak crash saat offline.
    if (_motherId == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blueGrey),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Riwayat Luring:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Data riwayat kehamilan tidak dapat dimuat atau disimpan karena Profil Ibu belum terdeteksi/koneksi terputus. Silakan set profil ibu dulu.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      );
    }

    final ref = _db
        .ref('pregnancy_checks/$_motherId')
        .orderByChild('timestamp');
    ref.keepSynced(true); // Memastikan data ini dicache

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.10),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              'Riwayat Pemeriksaan Kehamilan - Ibu: ${_motherName?.isNotEmpty == true ? _motherName! : "—"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<DatabaseEvent>(
            stream: ref.onValue,
            builder: (context, snapshot) {
              // Menampilkan loading hanya jika belum ada data sama sekali (initial load)
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              // Jika ada error atau data null
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.snapshot.value == null) {
                // Jika error, cek apakah ada data di cache (snap.data masih ada)
                final errorText = snapshot.hasError
                    ? 'Terjadi kesalahan DB: ${snapshot.error}'
                    : 'Belum ada data riwayat.';
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(errorText),
                );
              }

              final map = Map<dynamic, dynamic>.from(
                snapshot.data!.snapshot.value as Map,
              );
              final items =
                  map.entries.where((e) => e.value is Map).map((e) {
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
                  }).toList()..sort(
                    (a, b) => (b['ts'] as int).compareTo(a['ts'] as int),
                  );

              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Belum ada data riwayat.'),
                );
              }

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
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.withOpacity(0.35)),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(color: c, fontWeight: FontWeight.w700),
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
              '• Tinggi <150 cm  • BMI <18.5  • LILA <23.5 cm\n'
              'Heuristik skrining risiko stunting (bukan diagnosis klinis).',
              textAlign: TextAlign.left,
            ),
          ),
          IconButton(
            tooltip: 'Kecilkan',
            onPressed: onCollapse,
            icon: const Icon(Icons.keyboard_arrow_up, color: Colors.orange),
          ),
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
              'Info skrining ibu (klik untuk buka)',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(onPressed: onExpand, child: const Text('Buka')),
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
          Row(
            children: [
              const Icon(Icons.monitor_weight),
              const SizedBox(width: 8),
              Text('BMI: $bmiTxt  ($bmiKat)'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.straighten),
              const SizedBox(width: 8),
              Text('Tinggi badan <150 cm: ${tbKurang150 ? "Ya" : "Tidak"}'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.accessibility_new),
              const SizedBox(width: 8),
              Text(
                'LILA rendah: ${lilaRendah ? "Ya (<23.5 cm)" : "Tidak"}',
              ), // Diperbaiki, karena LILA wajib diisi
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.assessment),
              const SizedBox(width: 8),
              Expanded(child: Text('Skor Risiko Ibu (SRI): $sri')),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _warnaKategori(kategori),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  kategori,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
