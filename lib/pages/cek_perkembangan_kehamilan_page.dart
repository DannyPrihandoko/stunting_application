// lib/pages/cek_perkembangan_kehamilan_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import '../models/mother_profile_repository.dart';
import 'profil_bunda_page.dart';

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
  final _kehamilanKeCtrl = TextEditingController();

  static final List<String> _condOptions = [
    'pre',
    ...List.generate(9, (i) => 'preg_${i + 1}'),
    'post',
  ];
  String _condValue = 'pre';

  double? _bmi;
  String _bmiKat = '-';
  bool _tbKurang150 = false;
  bool _lilaRendah = false;
  bool _isParityRisk = false;

  int _sri = 0;
  String _kategori = '-';
  String _saran = '—';

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

  Future<void> _initMotherId() async {
    try {
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
      });
    } catch (e) {
      // Biarkan null
    } finally {
      if (mounted) setState(() => _loadingMother = false);
    }
  }

  @override
  void dispose() {
    _tinggiCtrl.dispose();
    _beratCtrl.dispose();
    _lilaCtrl.dispose();
    _kehamilanKeCtrl.dispose();
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
    final lila = double.parse(_lilaCtrl.text.trim().replaceAll(',', '.'));
    final pregnancyCount = int.parse(_kehamilanKeCtrl.text);

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
    final isParityRisk = pregnancyCount == 1 || pregnancyCount >= 4;

    final sri = (tbKurang150 ? 2 : 0) +
        (bmiKurang ? 2 : 0) +
        (lilaRendah ? 1 : 0) +
        (isParityRisk ? 1 : 0);

    String kategori, saran;
    if (sri >= 4) {
      kategori = 'Tinggi';
      saran =
          'Pendampingan intensif: konseling gizi pra/awal kehamilan, protein hewani harian, tablet tambah darah, rujuk bila ada infeksi, dan perbaikan WASH di rumah.';
    } else if (sri >= 2) {
      kategori = 'Sedang';
      saran =
          'Kelas ibu & monitoring bulanan, perbaiki menu (hewani + sayur/buah), pantau berat berkala, cek kepatuhan TTD.';
    } else {
      kategori = 'Rendah';
      saran = 'Edukasi universal & pemantauan rutin (posyandu/ANC).';
    }

    setState(() {
      _bmi = bmi;
      _bmiKat = bmiKat;
      _tbKurang150 = tbKurang150;
      _lilaRendah = lilaRendah;
      _isParityRisk = isParityRisk;
      _sri = sri;
      _kategori = kategori;
      _saran = saran;
      _resultCollapsed = false;
    });
  }

  Future<void> _hitungDanSimpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi data terlebih dahulu.')),
        );
      }
      return;
    }
    _hitungOnly();

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
        await _initMotherId();
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

    final hCm = double.parse(_tinggiCtrl.text.replaceAll(',', '.'));
    final wKg = double.parse(_beratCtrl.text.replaceAll(',', '.'));
    final lila = double.parse(_lilaCtrl.text.trim().replaceAll(',', '.'));
    final pregnancyCount = int.parse(_kehamilanKeCtrl.text);

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
        'lilaCm': lila,
        'pregnancyCount': pregnancyCount,
      },
      'derived': {
        'bmi': _bmi,
        'bmiCategory': _bmiKat,
        'heightUnder150': _tbKurang150,
        'lilaLow': _lilaRendah,
        'isParityRisk': _isParityRisk,
        'sri': _sri,
        'category': _kategori,
      },
      'recommendation': _saran,
    };

    try {
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
      _kehamilanKeCtrl.clear();
      _condValue = 'pre';
      _bmi = null;
      _bmiKat = '-';
      _tbKurang150 = false;
      _lilaRendah = false;
      _isParityRisk = false;
      _sri = 0;
      _kategori = '-';
      _saran = '—';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Cek Risiko Kehamilan')),
      body: Column(
        children: [
          _HeaderExpanded(
            isCollapsed: _headerCollapsed,
            onToggle: () => setState(() => _headerCollapsed = !_headerCollapsed),
          ),
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
                      ? const Text('Memuat profil ibu...', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange))
                      : Text(
                          'Ibu: ${_motherName?.trim().isNotEmpty == true ? _motherName! : "— (Profil belum di-set)"}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: DropdownButtonFormField<String>(
                            value: _condValue,
                            items: _condOptions.map((v) => DropdownMenuItem<String>(value: v, child: Text(_condLabel(v)))).toList(),
                            onChanged: (v) => setState(() => _condValue = v ?? 'pre'),
                            decoration: const InputDecoration(labelText: 'Kondisi Pemeriksaan', border: InputBorder.none, contentPadding: EdgeInsets.only(top: 8)),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _tinggiCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Tinggi Badan (cm)', border: OutlineInputBorder()),
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
                        decoration: const InputDecoration(labelText: 'Berat Badan (kg)', border: OutlineInputBorder()),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Isi berat badan';
                          final x = double.tryParse(v.replaceAll(',', '.'));
                          if (x == null || x < 30 || x > 200) return 'Masukkan 30–200 kg';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lilaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'LILA (cm)', hintText: 'Lingkar Lengan Atas', border: OutlineInputBorder()),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'LILA wajib diisi';
                          final x = double.tryParse(v.replaceAll(',', '.'));
                          if (x == null || x < 15 || x > 50) return 'Masukkan 15–50 cm';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _kehamilanKeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Ini adalah kehamilan ke-', border: OutlineInputBorder()),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                          final x = int.tryParse(v);
                          if (x == null || x <= 0) return 'Masukkan angka valid (> 0)';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildHistorySection(),
                const SizedBox(height: 90), // Spacer for floating result panel
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -4)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _resultCollapsed = !_resultCollapsed),
                child: Row(
                  children: [
                    const Icon(Icons.assessment_outlined),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Hasil & Rekomendasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    Icon(_resultCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _resultCollapsed
                    ? _CollapsedSummary(kategori: _kategori, sri: _sri, bmi: _bmi)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          _BarHasil(
                            bmi: _bmi,
                            bmiKat: _bmiKat,
                            tbKurang150: _tbKurang150,
                            lilaRendah: _lilaRendah,
                            isParityRisk: _isParityRisk,
                            sri: _sri,
                            kategori: _kategori,
                          ),
                          const SizedBox(height: 8),
                          if (_saran != '—') ...[
                            Text('Rekomendasi:', style: Theme.of(context).textTheme.titleMedium),
                            Text(_saran, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 10),
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
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_motherId == null) {
      // Return empty container if no mother is selected
      return const SizedBox.shrink();
    }

    final ref = _db.ref('pregnancy_checks/$_motherId').orderByChild('timestamp');
    ref.keepSynced(true);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const ListTile(title: Text('Belum ada riwayat pemeriksaan.'), dense: true);
          }

          final map = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final items = map.entries.where((e) => e.value is Map).map((e) {
            final m = Map<dynamic, dynamic>.from(e.value);
            final ts = (m['timestamp'] is int) ? m['timestamp'] as int : int.tryParse('${m['timestamp']}') ?? 0;
            return {
              'id': e.key.toString(),
              'label': (m['condition']?['label'] ?? '-').toString(),
              'bmi': m['derived']?['bmi'],
              'sri': m['derived']?['sri'],
              'cat': (m['derived']?['category'] ?? '-').toString(),
              'ts': ts,
              'preg_count': m['input']?['pregnancyCount'] ?? 0,
            };
          }).toList()
            ..sort((a, b) => (b['ts'] as int).compareTo(a['ts'] as int));

          if (items.isEmpty) {
            return const ListTile(title: Text('Belum ada riwayat pemeriksaan.'), dense: true);
          }

          // Group by pregnancy count
          final Map<int, List<Map<String, dynamic>>> grouped = {};
          for (final item in items) {
            final count = item['preg_count'] as int;
            if (count > 0) {
              grouped.putIfAbsent(count, () => []).add(item);
            }
          }
          final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return Column(
            children: sortedKeys.map((pregCount) {
              final groupItems = grouped[pregCount]!;
              return ExpansionTile(
                title: Text('Riwayat Kehamilan Ke-$pregCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                children: groupItems.map((it) {
                  final cat = it['cat'] as String;
                  final c = _badgeColor(cat);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.withOpacity(0.15),
                      child: Icon(Icons.monitor_heart, color: c),
                    ),
                    title: Text(it['label'] as String),
                    subtitle: Text(
                        "Waktu: ${_formatTimestamp(it['ts'] as int)}\nBMI: ${it['bmi'] == null ? '-' : (it['bmi'] as num).toStringAsFixed(1)} • SRI: ${it['sri'] ?? '-'}"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.withOpacity(0.35)),
                      ),
                      child: Text(cat, style: TextStyle(color: c, fontWeight: FontWeight.w700)),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
  
  Color _badgeColor(String c) {
    final x = c.toString().toLowerCase();
    if (x.contains('tinggi')) return Colors.redAccent;
    if (x.contains('sedang')) return Colors.orange;
    return Colors.green;
  }
  
  String _formatTimestamp(int ts) {
    if (ts == 0) return '-';
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateFormat('dd/MM/yy HH:mm').format(d);
  }
}

// ========================= WIDGET-WIDGET UI =========================

class _HeaderExpanded extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;
  const _HeaderExpanded({required this.isCollapsed, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState: isCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: Container(
        color: Colors.orange.withOpacity(0.12),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Faktor risiko ibu:\n'
                '• Tinggi <150 cm  • BMI <18.5  • LILA <23.5 cm\n'
                '• Kehamilan pertama atau ≥4 (paritas)',
                style: TextStyle(fontSize: 12),
              ),
            ),
            IconButton(
              tooltip: 'Kecilkan',
              onPressed: onToggle,
              icon: const Icon(Icons.keyboard_arrow_up, color: Colors.orange),
            ),
          ],
        ),
      ),
      secondChild: InkWell(
        onTap: onToggle,
        child: Container(
          color: Colors.orange.withOpacity(0.12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: const Row(
            children: [
              Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('Info skrining risiko ibu', overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsedSummary extends StatelessWidget {
  final String kategori;
  final int sri;
  final double? bmi;
  const _CollapsedSummary({required this.kategori, required this.sri, required this.bmi});

  Color _badgeColor(String label) {
    switch (label) {
      case 'Tinggi': return Colors.red;
      case 'Sedang': return Colors.orange;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _badgeColor(kategori);
    final bmiTxt = (bmi == null) ? '-' : bmi!.toStringAsFixed(1);
    if (kategori == '-') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
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
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20)),
              child: Text(kategori, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Skor Risiko (SRI): $sri • BMI: $bmiTxt",
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarHasil extends StatelessWidget {
  final double? bmi;
  final String bmiKat;
  final bool tbKurang150;
  final bool lilaRendah;
  final bool isParityRisk;
  final int sri;
  final String kategori;

  const _BarHasil({
    required this.bmi,
    required this.bmiKat,
    required this.tbKurang150,
    required this.lilaRendah,
    required this.isParityRisk,
    required this.sri,
    required this.kategori,
  });

  Color _warnaKategori(String label) {
    switch (label) {
      case 'Tinggi': return Colors.red;
      case 'Sedang': return Colors.orange;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kategori == '-') return const SizedBox.shrink();
    final bmiTxt = (bmi == null) ? '-' : bmi!.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.monitor_weight, 'BMI: $bmiTxt ($bmiKat)'),
          _buildInfoRow(Icons.straighten, 'Tinggi badan <150 cm: ${tbKurang150 ? "Ya" : "Tidak"}'),
          _buildInfoRow(Icons.accessibility_new, 'LILA rendah (<23.5 cm): ${lilaRendah ? "Ya" : "Tidak"}'),
          _buildInfoRow(Icons.looks_one_outlined, 'Risiko Paritas (Kehamilan ke-1 atau ≥4): ${isParityRisk ? "Ya" : "Tidak"}'),
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.assessment),
              const SizedBox(width: 8),
              Expanded(child: Text('Skor Risiko Ibu (SRI): $sri', style: const TextStyle(fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _warnaKategori(kategori),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(kategori, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}