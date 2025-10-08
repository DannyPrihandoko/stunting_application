// lib/pages/rekap_menu_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/mother_profile_repository.dart';
import 'cek_perkembangan_kehamilan_page.dart';
import 'rekap_tinggi_page.dart';
import 'rekap_berat_page.dart';

class RekapMenuPage extends StatefulWidget {
  const RekapMenuPage({super.key});

  @override
  State<RekapMenuPage> createState() => _RekapMenuPageState();
}

class _RekapMenuPageState extends State<RekapMenuPage> {
  final _db = FirebaseDatabase.instance;
  final _motherRepo = MotherProfileRepository();

  bool _loading = true;
  String? _motherId;
  String? _motherName;

  @override
  void initState() {
    super.initState();
    _initMother();
  }

  Future<void> _initMother() async {
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
      _loading = false;
    });
  }

  // ---------- navigasi ----------
  void _openPregnancyRecap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CekPerkembanganKehamilanPage()),
    );
  }

  Future<void> _pickChildAndOpenHeightRecap() async {
    final child = await _pickChild();
    if (child == null) return;

    // pastikan DOB terisi; kalau null, coba fetch dari /profile
    final bd =
        child['birthDateMs'] as int? ??
        await _loadChildBirthDateMs(child['id'] as String);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildGrowthRecapPage(
          motherId: _motherId!,
          childId: child['id'] as String,
          childName: child['name'] as String? ?? '',
          childBirthDateMs: bd,
        ),
      ),
    );
  }

  Future<void> _pickChildAndOpenWeightRecap() async {
    final child = await _pickChild();
    if (child == null) return;

    final bd =
        child['birthDateMs'] as int? ??
        await _loadChildBirthDateMs(child['id'] as String);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildWeightRecapPage(
          motherId: _motherId!,
          childId: child['id'] as String,
          childName: child['name'] as String? ?? '',
          childBirthDateMs: bd,
        ),
      ),
    );
  }

  // ---------- pilih anak (bottom sheet) ----------
  Future<Map<String, dynamic>?> _pickChild() async {
    if (_motherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil Ibu belum dipilih/dibuat.')),
      );
      return null;
    }
    final snap = await _db.ref('mothers/$_motherId/children').get();
    final items = <Map<String, dynamic>>[];

    if (snap.exists && snap.value is Map) {
      final m = Map<dynamic, dynamic>.from(snap.value as Map);
      m.forEach((id, v) {
        if (v is Map) {
          final mm = Map<dynamic, dynamic>.from(v);

          // Ekstrak nama (beberapa kemungkinan kunci)
          final name = _extractName(mm);

          // Ekstrak DOB dari root atau submap 'profile'
          final dob = _extractBirthDateMs(mm);

          items.add({
            'id': id.toString(),
            'name': name ?? '',
            'birthDateMs': dob, // bisa null; nanti dicoba fetch khusus
          });
        }
      });
    }

    if (items.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada data anak untuk Ibu ini.')),
      );
      return null;
    }

    if (!mounted) return null;
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
          itemBuilder: (_, i) {
            final it = items[i];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.child_care)),
              title: Text(
                it['name']?.toString().isNotEmpty == true
                    ? it['name'] as String
                    : '(Tanpa nama)',
              ),
              subtitle: (it['birthDateMs'] != null)
                  ? Text(_fmtDate(it['birthDateMs'] as int))
                  : const Text('Tgl lahir: —'),
              onTap: () => Navigator.pop(context, it),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: items.length,
        );
      },
    );
  }

  // ---------- helper ekstraksi nama & DOB ----------
  String? _extractName(Map mm) {
    final profile = (mm['profile'] is Map) ? Map.from(mm['profile']) : null;
    final candidates = [
      mm['name'],
      mm['nama'],
      mm['childName'],
      profile?['name'],
      profile?['nama'],
    ];
    for (final c in candidates) {
      final s = c?.toString();
      if (s != null && s.trim().isNotEmpty) return s.trim();
    }
    return null;
  }

  int? _extractBirthDateMs(Map mm) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final profile = (mm['profile'] is Map) ? Map.from(mm['profile']) : null;

    // cek di root
    for (final k in const [
      'birthDateMs',
      'dobMs',
      'tanggalLahirMs',
      'tglLahirMs',
      'lahirMs',
      'birthMs',
    ]) {
      final v = asInt(mm[k]);
      if (v != null) return v;
    }

    // cek di profile
    if (profile != null) {
      for (final k in const [
        'birthDateMs',
        'dobMs',
        'tanggalLahirMs',
        'tglLahirMs',
        'lahirMs',
        'birthMs',
      ]) {
        final v = asInt(profile[k]);
        if (v != null) return v;
      }
    }
    return null;
  }

  Future<int?> _loadChildBirthDateMs(String childId) async {
    try {
      // coba di /profile
      final p = await _db
          .ref('mothers/$_motherId/children/$childId/profile')
          .get();
      if (p.exists && p.value is Map) {
        final mm = Map<dynamic, dynamic>.from(p.value as Map);
        final v = _extractBirthDateMs(mm);
        if (v != null) return v;
      }
      // fallback: cek langsung di node anak (barangkali ada di root)
      final c = await _db.ref('mothers/$_motherId/children/$childId').get();
      if (c.exists && c.value is Map) {
        final mm = Map<dynamic, dynamic>.from(c.value as Map);
        final v = _extractBirthDateMs(mm);
        if (v != null) return v;
      }
    } catch (_) {}
    return null;
  }

  String _fmtDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Rekap')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_motherName != null)
                    Text(
                      'Ibu: ${_motherName!.isNotEmpty ? _motherName! : "—"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.92,
                      children: [
                        AssetImageButton(
                          title: 'Rekap\nKehamilan',
                          subtitle: 'Cek & Riwayat',
                          assetPath: 'assets/illustrations/rekap_pregnancy.jpg',
                          icon: Icons.pregnant_woman_outlined,
                          onTap: _openPregnancyRecap,
                        ),
                        AssetImageButton(
                          title: 'Rekap\nTinggi Anak',
                          subtitle: 'Ringkasan & tren',
                          assetPath: 'assets/illustrations/rekap_height.jpg',
                          icon: Icons.height,
                          onTap: _pickChildAndOpenHeightRecap,
                        ),
                        AssetImageButton(
                          title: 'Rekap\nBerat Anak',
                          subtitle: 'Ringkasan & tren',
                          assetPath: 'assets/illustrations/rekap_weight.jpg',
                          icon: Icons.monitor_weight_outlined,
                          onTap: _pickChildAndOpenWeightRecap,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class AssetImageButton extends StatelessWidget {
  const AssetImageButton({
    super.key,
    required this.title,
    this.subtitle,
    required this.assetPath,
    required this.onTap,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final String assetPath;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Material(
      elevation: 3,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            image: DecorationImage(
              image: AssetImage(assetPath),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.28),
                BlendMode.darken,
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.35),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.black87, size: 20),
                      ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        height: 1.1,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
