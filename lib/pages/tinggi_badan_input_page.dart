// lib/pages/tinggi_badan_input_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import '../models/mother_profile_repository.dart';

class ChildHeightInputPage extends StatefulWidget {
  const ChildHeightInputPage({super.key, this.presetChildId});

  /// opsional: jika dipanggil dari rekap, kita bisa kirim childId agar terpilih otomatis
  final String? presetChildId;

  @override
  State<ChildHeightInputPage> createState() => _ChildHeightInputPageState();
}

class _ChildHeightInputPageState extends State<ChildHeightInputPage> {
  final _db = FirebaseDatabase.instance;
  final _motherRepo = MotherProfileRepository();

  String? _motherId;
  bool _loading = true;

  final _heightCtrl = TextEditingController();

  DateTime? _measureDate; // tanggal ukur (untuk ambil bulan/year)
  String? _selectedChildId;

  // cache anak untuk dropdown
  final List<_ChildOpt> _children = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final mid = await _motherRepo.getCurrentId();
      if (mid == null) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil Ibu belum dipilih/ dibuat.')),
          );
        }
        return;
      }
      _motherId = mid;

      final snap = await _db.ref('mothers/$mid/children').get();
      if (snap.exists && snap.value is Map) {
        final map = Map<dynamic, dynamic>.from(snap.value as Map);
        map.forEach((id, v) {
          if (v is Map) {
            final m = Map<dynamic, dynamic>.from(v);
            _children.add(_ChildOpt(
              id: id.toString(),
              name: (m['name'] ?? '').toString(),
              birthDateMs: _toIntOrNull(m['birthDate']),
            ));
          }
        });
        // preset child jika disediakan
        if (widget.presetChildId != null &&
            _children.any((c) => c.id == widget.presetChildId)) {
          _selectedChildId = widget.presetChildId;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memuat anak: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }

  _ChildOpt? get _selectedChild =>
      _children.firstWhere((c) => c.id == _selectedChildId, orElse: () => const _ChildOpt.empty());

  int? get _ageMonths {
    final child = _selectedChild;
    if (child == null || child.birthDateMs == null || _measureDate == null) return null;
    final bd = DateTime.fromMillisecondsSinceEpoch(child.birthDateMs!);
    return _monthsBetween(bd, _measureDate!).clamp(0, 600);
  }

  int _monthsBetween(DateTime start, DateTime end) {
    int m = (end.year - start.year) * 12 + (end.month - start.month);
    if (end.day < start.day) m -= 1;
    return m;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final init = _measureDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      setState(() => _measureDate = picked);
    }
  }

  Future<void> _save() async {
    if (_motherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil Ibu belum tersedia.')),
      );
      return;
    }
    if (_selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih anak terlebih dahulu.')),
      );
      return;
    }
    if (_measureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih bulan (tanggal ukur) terlebih dahulu.')),
      );
      return;
    }
    final age = _ageMonths;
    if (age == null || age < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usia (bulan) tidak valid. Pastikan tanggal lahir anak terisi.')),
      );
      return;
    }
    final h = double.tryParse(_heightCtrl.text.replaceAll(',', '.'));
    if (h == null || h <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan tinggi (cm) yang valid.')),
      );
      return;
    }

    final ref = _db
        .ref('mothers/$_motherId/children/$_selectedChildId/growth/$age');

    final data = {
      'heightCm': h,
      'measuredAt': _measureDate!.millisecondsSinceEpoch,
      'monthKey': DateFormat('yyyy-MM').format(_measureDate!),
      'updatedAt': ServerValue.timestamp,
    };

    try {
      await ref.set(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data tinggi tersimpan.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _selectedChild;
    final dobStr = (child?.birthDateMs == null)
        ? '-'
        : DateFormat('dd/MM/yyyy')
            .format(DateTime.fromMillisecondsSinceEpoch(child!.birthDateMs!));
    final measureStr = _measureDate == null
        ? ''
        : DateFormat('dd/MM/yyyy').format(_measureDate!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Tinggi Badan Anak'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Anak
                InputDecorator(
                  decoration: _dec('Anak'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedChildId,
                      hint: const Text('Pilih anak'),
                      items: _children
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name.isEmpty ? '(Tanpa nama)' : c.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedChildId = v;
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bulan (tanggal ukur)
                TextFormField(
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: _dec(
                    'Bulan (tanggal ukur)',
                    hint: 'dd/MM/yyyy',
                    suffix: const Icon(Icons.date_range),
                  ),
                  controller: TextEditingController(text: measureStr),
                ),
                const SizedBox(height: 12),

                // Usia (bulan) otomatis
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: _dec('Usia (bulan)'),
                        controller: TextEditingController(
                          text: (_ageMonths == null) ? '' : '${_ageMonths!}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: _dec('Tgl lahir'),
                        controller: TextEditingController(text: dobStr),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tinggi
                TextFormField(
                  controller: _heightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _dec('Tinggi (cm)', hint: 'mis. 73.5'),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan'),
                  ),
                ),
              ],
            ),
    );
  }

  InputDecoration _dec(String label, {String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
      suffixIcon: suffix,
      filled: true,
    );
  }
}

class _ChildOpt {
  final String id;
  final String name;
  final int? birthDateMs;
  const _ChildOpt({required this.id, required this.name, required this.birthDateMs});
  const _ChildOpt.empty() : id = '', name = '', birthDateMs = null;
}
