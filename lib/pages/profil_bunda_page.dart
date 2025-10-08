// lib/pages/profil_bunda_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/mother_profile_repository.dart';

class ProfilBundaPage extends StatefulWidget {
  const ProfilBundaPage({super.key});

  @override
  State<ProfilBundaPage> createState() => _ProfilBundaPageState();
}

class _ProfilBundaPageState extends State<ProfilBundaPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaC = TextEditingController();
  final _tempatLahirC = TextEditingController();
  final _tanggalLahirC = TextEditingController();
  final _noHpC = TextEditingController();
  final _alamatC = TextEditingController();
  final _desaKelurahanC = TextEditingController();
  final _kecamatanC = TextEditingController();
  final _posyanduC = TextEditingController();

  final _repo = MotherProfileRepository();
  DateTime? _tgl;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // login anon bila tersedia; kalau disabled di server, akan graceful fallback
    await _repo.ensureSignedIn();
    await _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final data = await _repo.readCurrent();
    if (data != null && mounted) {
      setState(() {
        _namaC.text = data.nama;
        _tempatLahirC.text = data.tempatLahir;
        _tgl = data.tanggalLahir;
        _tanggalLahirC.text = _tgl != null
            ? DateFormat('dd/MM/yyyy').format(_tgl!)
            : '';
        _noHpC.text = data.noHp;
        _alamatC.text = data.alamat;
        _desaKelurahanC.text = data.desaKelurahan;
        _kecamatanC.text = data.kecamatan;
        _posyanduC.text = data.posyandu;
      });
    }
  }

  @override
  void dispose() {
    _namaC.dispose();
    _tempatLahirC.dispose();
    _tanggalLahirC.dispose();
    _noHpC.dispose();
    _alamatC.dispose();
    _desaKelurahanC.dispose();
    _kecamatanC.dispose();
    _posyanduC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _tgl ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        _tgl = picked;
        _tanggalLahirC.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String? _required(String? v, {String label = 'Kolom'}) {
    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  String? _validPhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nomor HP wajib diisi';
    final digits = v.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!RegExp(r'^(?:\+?62|0)\d{8,15}$').hasMatch(digits)) {
      return 'Format nomor HP tidak valid';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = MotherProfile(
      nama: _namaC.text.trim(),
      tempatLahir: _tempatLahirC.text.trim(),
      tanggalLahir: _tgl,
      noHp: _noHpC.text.trim(),
      alamat: _alamatC.text.trim(),
      desaKelurahan: _desaKelurahanC.text.trim(),
      kecamatan: _kecamatanC.text.trim(),
      posyandu: _posyanduC.text.trim(),
    );

    final curId = await _repo.getCurrentId();
    if (curId == null) {
      await _repo.create(profile);
    } else {
      // gunakan toMap() agar turunannya (nama_lower, noHp_norm, updatedAt, ownerId) terjaga
      await _repo.update(curId, profile.toMap());
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        // Pesan berlaku untuk online maupun offline, karena SDK akan auto-queue
        const SnackBar(
          content: Text(
            'Profil ibu tersimpan. Akan tersinkron otomatis saat online.',
          ),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final curId = await _repo.getCurrentId();
    if (curId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Profil?'),
        content: const Text('Data profil ibu akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteCurrent();
      if (mounted) {
        _formKey.currentState!.reset();
        _namaC.clear();
        _tempatLahirC.clear();
        _tanggalLahirC.clear();
        _tgl = null;
        _noHpC.clear();
        _alamatC.clear();
        _desaKelurahanC.clear();
        _kecamatanC.clear();
        _posyanduC.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profil ibu dihapus.')));
      }
    }
  }

  InputDecoration _dec(String label, {String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
      suffixIcon: suffix,
      fillColor: Colors.white,
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Ibu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _namaC,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Nama Lengkap'),
                validator: (v) => _required(v, label: 'Nama'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempatLahirC,
                      decoration: _dec('Tempat Lahir'),
                      validator: (v) => _required(v, label: 'Tempat lahir'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _tanggalLahirC,
                      readOnly: true,
                      decoration: _dec(
                        'Tanggal Lahir',
                        hint: 'dd/MM/yyyy',
                        suffix: const Icon(Icons.date_range),
                      ),
                      onTap: _pickDate,
                      validator: (_) =>
                          _tgl == null ? 'Tanggal lahir wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noHpC,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                ],
                decoration: _dec('No. HP', hint: '0812… atau +62812…'),
                validator: _validPhone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _alamatC,
                decoration: _dec('Alamat'),
                validator: (v) => _required(v, label: 'Alamat'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _desaKelurahanC,
                      decoration: _dec('Desa/Kelurahan'),
                      validator: (v) => _required(v, label: 'Desa/Kelurahan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _kecamatanC,
                      decoration: _dec('Kecamatan'),
                      validator: (v) => _required(v, label: 'Kecamatan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _posyanduC,
                decoration: _dec('Posyandu'),
                validator: (v) => _required(v, label: 'Posyandu'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
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
}
