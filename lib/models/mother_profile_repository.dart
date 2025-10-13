// lib/models/mother_profile_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // <-- Pastikan dependensi ini ada
import '../services/app_device_id.dart';

/// Data model untuk Profil Ibu.
class MotherProfile {
  final String? id;
  final String nama;
  final String tempatLahir;
  final DateTime? tanggalLahir;
  final String noHp;
  final String alamat;
  final String desaKelurahan;
  final String kecamatan;
  final String posyandu;
  final String? ownerId;
  final String? ownerDeviceId;
  final int? createdAt;
  final int? updatedAt;

  const MotherProfile({
    this.id,
    required this.nama,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.noHp,
    required this.alamat,
    required this.desaKelurahan,
    required this.kecamatan,
    required this.posyandu,
    this.ownerId,
    this.ownerDeviceId,
    this.createdAt,
    this.updatedAt,
  });

  factory MotherProfile.fromMap(String id, Map data) {
    int? _asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse('$v');
    }

    return MotherProfile(
      id: id,
      nama: (data['nama'] ?? '') as String,
      tempatLahir: (data['tempatLahir'] ?? '') as String,
      tanggalLahir: data['tanggalLahir'] != null
          ? DateTime.fromMillisecondsSinceEpoch(_asInt(data['tanggalLahir']) ?? 0)
          : null,
      noHp: (data['noHp'] ?? '') as String,
      alamat: (data['alamat'] ?? '') as String,
      desaKelurahan: (data['desaKelurahan'] ?? '') as String,
      kecamatan: (data['kecamatan'] ?? '') as String,
      posyandu: (data['posyandu'] ?? '') as String,
      ownerId: data['ownerId'] as String?,
      ownerDeviceId: data['ownerDeviceId'] as String?,
      createdAt: _asInt(data['createdAt']),
      updatedAt: _asInt(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({
    bool includeCreatedAt = false,
    String? forceOwnerId,
    String? forceOwnerDeviceId,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return <String, dynamic>{
      'nama': nama,
      'nama_lower': nama.toLowerCase().trim(),
      'tempatLahir': tempatLahir,
      'tanggalLahir': tanggalLahir?.millisecondsSinceEpoch,
      'noHp': noHp,
      'noHp_norm': _normalizePhone(noHp),
      'alamat': alamat,
      'desaKelurahan': desaKelurahan,
      'kecamatan': kecamatan,
      'posyandu': posyandu,
      if (forceOwnerId != null) 'ownerId': forceOwnerId,
      if (forceOwnerDeviceId != null) 'ownerDeviceId': forceOwnerDeviceId,
      if (includeCreatedAt) 'createdAt': now,
      'updatedAt': now,
    };
  }

  static String _normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('0')) return '+62${digits.substring(1)}';
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('62')) return '+$digits';
    return digits;
  }
}

/// Repository CRUD Profil Ibu (path: /mothers/{id}) dengan fallback bila Auth dimatikan.
class MotherProfileRepository {
  MotherProfileRepository({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  DatabaseReference get _root => _db.ref();
  DatabaseReference _motherRef(String id) => _root.child('mothers').child(id);

  String _safeKey(String s) => s.replaceAll(RegExp(r'[.#$\[\]/]'), '_');

  DatabaseReference _deviceIndexRef(String rawDeviceId) =>
      _root.child('device_index').child(_safeKey(rawDeviceId));

  // ## FUNGSI YANG DIPERBARUI ##
  Future<void> ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return;

    // Periksa konektivitas sebelum mencoba sign-in
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Jika tidak ada koneksi, lewati proses sign-in.
      // Aplikasi akan berjalan dengan data offline.
      print("Tidak ada koneksi internet, melewati sign-in anonim.");
      return;
    }

    try {
      await auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed' || e.code == 'admin-restricted-operation') {
        return;
      }
      // Jika errornya tetap network-request-failed, kita biarkan saja
      // agar tidak menghentikan aplikasi.
      if (e.code == 'network-request-failed') {
        print("Gagal sign-in anonim karena masalah jaringan, melanjutkan secara offline.");
        return;
      }
      rethrow;
    }
  }
  // ## AKHIR PERUBAHAN ##

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static const _kCurrentId = 'mother_current_id';

  Future<void> setCurrentId(String id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCurrentId, id);

    final deviceId = await AppDeviceId.getId();
    final clientKey = await AppDeviceId.getClientKey();
    await _deviceIndexRef(deviceId).set({
      'currentMotherId': id,
      'clientKey': clientKey,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<String?> getCurrentId() async {
    final sp = await SharedPreferences.getInstance();
    final local = sp.getString(_kCurrentId);
    if (local != null && local.isNotEmpty) return local;

    final deviceId = await AppDeviceId.getId();
    final snap = await _deviceIndexRef(deviceId).get();
    if (snap.exists && snap.value is Map) {
      final m = Map<dynamic, dynamic>.from(snap.value as Map);
      final mid = (m['currentMotherId'] ?? '').toString();
      if (mid.isNotEmpty) {
        await sp.setString(_kCurrentId, mid);
        return mid;
      }
    }
    return null;
  }

  Future<void> clearCurrentId() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kCurrentId);
  }

  Future<String> create(MotherProfile profile) async {
    await ensureSignedIn();
    final ref = _root.child('mothers').push();
    final uid = _uid;
    final deviceId = await AppDeviceId.getId();

    await ref.set(profile.toMap(
      includeCreatedAt: true,
      forceOwnerId: uid,
      forceOwnerDeviceId: deviceId,
    ));

    final id = ref.key!;
    await setCurrentId(id);
    return id;
  }

  Future<MotherProfile?> read(String id) async {
    await ensureSignedIn();
    final snap = await _motherRef(id).get();
    if (!snap.exists || snap.value == null) return null;
    return MotherProfile.fromMap(id, Map<String, dynamic>.from(snap.value as Map));
  }

  Future<MotherProfile?> readCurrent() async {
    await ensureSignedIn();
    final id = await getCurrentId();
    if (id == null) return null;
    return read(id);
  }

  Future<void> update(String id, Map<String, dynamic> updates) async {
    await ensureSignedIn();
    updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    if (updates.containsKey('nama')) {
      updates['nama_lower'] = (updates['nama'] as String).toLowerCase().trim();
    }
    if (updates.containsKey('noHp')) {
      updates['noHp_norm'] = MotherProfile._normalizePhone(updates['noHp'] as String);
    }
    final uid = _uid;
    if (uid != null && updates['ownerId'] == null) {
      updates['ownerId'] = uid;
    }
    await _motherRef(id).update(updates);
  }

  Future<void> updateCurrent(Map<String, dynamic> updates) async {
    final id = await getCurrentId();
    if (id == null) throw StateError('No current mother id');
    await update(id, updates);
  }

  Future<void> delete(String id) async {
    await ensureSignedIn();
    await _motherRef(id).remove();
    final cur = await getCurrentId();
    if (cur == id) await clearCurrentId();
  }

  Future<void> deleteCurrent() async {
    final id = await getCurrentId();
    if (id == null) return;
    await delete(id);
  }

  Future<List<MotherProfile>> list({
    int limit = 50,
    String? namePrefixLower,
  }) async {
    await ensureSignedIn();
    final uid = _uid;
    Query q;

    if (uid != null) {
      q = _root.child('mothers').orderByChild('ownerId').equalTo(uid).limitToLast(limit);
    } else {
      if (namePrefixLower != null && namePrefixLower.isNotEmpty) {
        final start = namePrefixLower;
        final end = '$namePrefixLower\uf8ff';
        q = _root.child('mothers').orderByChild('nama_lower').startAt(start).endAt(end).limitToLast(limit);
      } else {
        q = _root.child('mothers').limitToLast(limit);
      }
    }

    final snap = await q.get();
    if (!snap.exists || snap.value == null) return <MotherProfile>[];

    final map = Map<String, dynamic>.from(snap.value as Map);
    var list = map.entries
        .map((e) => MotherProfile.fromMap(e.key, Map<String, dynamic>.from(e.value as Map)))
        .toList();

    if (uid != null && namePrefixLower != null && namePrefixLower.isNotEmpty) {
      final pref = namePrefixLower.toLowerCase();
      list = list.where((p) => p.nama.toLowerCase().startsWith(pref)).toList();
    }

    list.sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
    if (limit > 0 && list.length > limit) {
      list = list.sublist(0, limit);
    }
    return list;
  }
}