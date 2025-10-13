// lib/pages/data_anak_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/mother_profile_repository.dart';
import '../models/child_repository.dart';
import 'profil_bunda_page.dart';
import 'rekap_tinggi_page.dart';
import 'rekap_berat_page.dart';
import 'tinggi_badan_input_page.dart';
import 'berat_badan_input_page.dart';

// COMPAT: jika repository belum punya ensureSignedIn(), jadikan no-op.
extension _CompatEnsureSignIn on MotherProfileRepository {}

class DataAnakPage extends StatefulWidget {
  const DataAnakPage({super.key});

  @override
  State<DataAnakPage> createState() => _DataAnakPageState();
}

class _DataAnakPageState extends State<DataAnakPage> {
  final _motherRepo = MotherProfileRepository();
  final _childRepo = ChildRepository();

  String? _motherId;
  Stream<List<ChildData>>? _stream;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _motherRepo.ensureSignedIn();
    } catch (_) {}
    final mid = await _motherRepo.getCurrentId();
    if (!mounted) return;
    setState(() {
      _motherId = mid;
      _loading = false;
      if (mid != null) {
        _stream = _childRepo.streamForMother(mid);
      }
    });
  }

  Future<void> _openAddChildSheet() async {
    if (_motherId == null) {
      _askCreateMother();
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AddChildSheet(
        motherId: _motherId!,
        onSaved: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data anak tersimpan.')),
          );
        },
      ),
    );
  }

  void _askCreateMother() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Profil Ibu Belum Ada'),
        content: const Text(
            'Buat/isi profil ibu terlebih dahulu agar data anak bisa ditautkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(c);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilBundaPage()),
              );
            },
            child: const Text('Isi Profil Ibu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      color: Colors.grey.shade900,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Anak'),
        actions: [
          IconButton(
            tooltip: 'Tambah Anak',
            onPressed: _openAddChildSheet,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddChildSheet,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Anak'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_motherId == null)
              ? _EmptyState(
                  title: 'Belum ada Profil Ibu',
                  message:
                      'Data anak membutuhkan 1 profil ibu aktif. Isi profil ibu dulu ya.',
                  actionText: 'Isi Profil Ibu',
                  onAction: _askCreateMother,
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daftar Anak', style: title),
                      const SizedBox(height: 8),
                      Expanded(child: _buildList()),
                    ],
                  ),
                ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<ChildData>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snap.error}'));
        }
        final items = snap.data ?? <ChildData>[];
        if (items.isEmpty) {
          return const _EmptyState(
            title: 'Belum ada Anak',
            message: 'Tekan tombol “Tambah Anak” untuk menambahkan.',
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final c = items[i];
            return ListTile(
              leading: CircleAvatar(
                child: Icon(c.sex == 'L' ? Icons.boy : Icons.girl),
              ),
              title: Text(
                c.name.isEmpty ? '—' : c.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_childSubtitle(c)),
              trailing: IconButton(
                tooltip: 'Hapus',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(c),
              ),
              onTap: () => _openChildOptions(c),
            );
          },
        );
      },
    );
  }

  void _openChildOptions(ChildData c) {
    if (_motherId == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.height),
              title: const Text('Rekap Tinggi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildGrowthRecapPage(
                      motherId: _motherId!,
                      childId: c.id!,
                      childName: c.name,
                      childBirthDateMs: c.birthDate?.millisecondsSinceEpoch,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.monitor_weight_outlined),
              title: const Text('Rekap Berat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildWeightRecapPage(
                      motherId: _motherId!,
                      childId: c.id!,
                      childName: c.name,
                      childBirthDateMs: c.birthDate?.millisecondsSinceEpoch,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Input Tinggi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildHeightInputPage(presetChildId: c.id!),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Input Berat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildWeightInputPage(presetChildId: c.id!),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _childSubtitle(ChildData c) {
    final dob = c.birthDate != null
        ? DateFormat('dd/MM/yyyy').format(c.birthDate!)
        : '-';
    final sex = c.sex == 'L' ? 'L' : (c.sex == 'P' ? 'P' : '-');
    return '$sex • $dob';
  }

  Future<void> _confirmDelete(ChildData c) async {
    final mid = _motherId!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (cx) => AlertDialog(
        title: const Text('Hapus Data Anak?'),
        content: Text('Hapus "${c.name}" dari daftar anak?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(cx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(cx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      await _childRepo.deleteForMother(mid, c.id!);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Data anak dihapus.')));
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: Colors.blueGrey.shade400, size: 40),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            if (actionText != null) ...[
              const SizedBox(height: 10),
              FilledButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ===== Sheet tambah anak =====
class _AddChildSheet extends StatefulWidget {
  const _AddChildSheet({required this.motherId, this.onSaved});
  final String motherId;
  final VoidCallback? onSaved;

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  DateTime? _dob;
  String _sex = 'L';
  bool _saving = false;

  final _repo = ChildRepository();

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 1, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  String? _required(String? v, {String label = 'Kolom'}) {
    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal lahir wajib dipilih')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final child = ChildData(
        name: _nameC.text.trim(),
        birthDate: _dob,
        sex: _sex,
      );
      await _repo.createForMother(widget.motherId, child);
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dobStr = _dob == null ? '' : DateFormat('dd/MM/yyyy').format(_dob!);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        top: 8,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tambah Anak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameC,
              textCapitalization: TextCapitalization.words,
              decoration: _dec('Nama Anak'),
              validator: (v) => _required(v, label: 'Nama anak'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: _dec(
                      'Tanggal Lahir',
                      hint: 'dd/MM/yyyy',
                      suffix: const Icon(Icons.date_range),
                    ),
                    controller: TextEditingController(text: dobStr),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: _dec('Jenis Kelamin'),
                    child: Center(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(value: 'L', icon: Icon(Icons.boy_outlined), label: Text('L')),
                          ButtonSegment<String>(value: 'P', icon: Icon(Icons.girl_outlined), label: Text('P')),
                        ],
                        selected: {_sex},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setState(() => _sex = selection.first);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Simpan'),
              ),
            ),
          ],
        ),
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