// lib/models/mother_profile_repository.dart
//
// DEPENDENSI YANG DIPERLUKAN DI pubspec.yaml:
//   device_info_plus: ^10.1.0
//   flutter_secure_storage: ^9.0.0
//   uuid: ^4.4.0
//   shared_preferences: ^2.2.3
//
// Perubahan penting:
// - Tambah _safeKey() untuk sanitize deviceId saat dipakai di path Realtime DB.
// - Semua akses /device_index/{id} kini memakai _deviceIndexRef(_safeKey(id)).
// - Menghindari error "Invalid Firebase Database path".

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// ===== Util: ID perangkat aplikasi (stabil per app) =====
class _DeviceIdentity {
  static const _kKeychainDeviceId = 'app_device_id';
  static const _kKeychainClientKey = 'app_client_key';
  static const _kPrefsFallbackId = 'app_device_id_fallback';

  static final _secure = const FlutterSecureStorage();
  static final _deviceInfo = DeviceInfoPlugin();
  static final _uuid = const Uuid();

  /// ID perangkat aplikasi yang stabil per instalasi (iOS cenderung persist, Android tergantung).
  static Future<String> getId() async {
    // 1) Coba baca yang pernah disimpan
    final existing = await _secure.read(key: _kKeychainDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;

    // 2) (Opsional) ambil info perangkat sebagai kandidat (bisa saja bukan unik)
    String? candidate;
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        // WARNING: info.id = Build ID (sering ada titik & tidak unik). Jangan pakai langsung untuk path.
        // Kita tetap jadikan bagian kandidat string, namun TIDAK dipakai langsung sebagai key path.
        candidate = 'android-${info.id}-${info.model}-${info.hardware}';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        candidate = 'ios-${info.model}-${info.systemVersion}';
      } else {
        candidate = 'other';
      }
    } catch (_) {
      candidate = null;
    }

    // 3) Generate UUID untuk device id aplikasi (yang benar2 kita simpan)
    final gen = _uuid.v4();
    final deviceId = candidate == null ? gen : '$candidate-$gen';

    await _secure.write(key: _kKeychainDeviceId, value: deviceId);

    // 4) Android extra fallback (jaga-jaga) ke SharedPreferences bila secure storage tidak available
    if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefsFallbackId, deviceId);
    }
    return deviceId;
  }

  /// ClientKey lokal (opsional, untuk pencatatan).
  static Future<String> getClientKey() async {
    final existing = await _secure.read(key: _kKeychainClientKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final key = _uuid.v4().replaceAll('-', '') + _uuid.v4().replaceAll('-', '');
    await _secure.write(key: _kKeychainClientKey, value: key);
    return key;
  }
}

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
  final String? ownerId;        // diisi jika auth tersedia
  final String? ownerDeviceId;  // ID perangkat pemilik data (value di DB, bukan path)
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
    String? forceOwnerId,        // isi kalau auth available
    String? forceOwnerDeviceId,  // isi ID perangkat
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

  MotherProfile copyWith({
    String? id,
    String? nama,
    String? tempatLahir,
    DateTime? tanggalLahir,
    String? noHp,
    String? alamat,
    String? desaKelurahan,
    String? kecamatan,
    String? posyandu,
    String? ownerId,
    String? ownerDeviceId,
    int? createdAt,
    int? updatedAt,
  }) {
    return MotherProfile(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      noHp: noHp ?? this.noHp,
      alamat: alamat ?? this.alamat,
      desaKelurahan: desaKelurahan ?? this.desaKelurahan,
      kecamatan: kecamatan ?? this.kecamatan,
      posyandu: posyandu ?? this.posyandu,
      ownerId: ownerId ?? this.ownerId,
      ownerDeviceId: ownerDeviceId ?? this.ownerDeviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Repository CRUD Profil Ibu (path: /mothers/{id}) dengan fallback bila Auth dimatikan.
/// Tambahan: binding ke perangkat via /device_index/{safeDeviceId}.
class MotherProfileRepository {
  MotherProfileRepository({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  DatabaseReference get _root => _db.ref();
  DatabaseReference _motherRef(String id) => _root.child('mothers').child(id);

  // Sanitize key untuk path Firebase
  String _safeKey(String s) => s.replaceAll(RegExp(r'[.#$\[\]/]'), '_');

  DatabaseReference _deviceIndexRef(String rawDeviceId) =>
      _root.child('device_index').child(_safeKey(rawDeviceId));

  // ====== Auth helpers (graceful fallback) ======
  Future<void> _tryEnsureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return;
    try {
      await auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      // Bila Anonymous dimatikan: jangan gagalkan operasi (tetap tanpa login).
      if (e.code == 'operation-not-allowed' || e.code == 'admin-restricted-operation') {
        return;
      }
      rethrow; // error lain tetap dilempar
    }
  }

  /// Backward-compat: method publik supaya pemanggilan lama tetap jalan.
  Future<void> ensureSignedIn() => _tryEnsureSignedIn();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ====== current id helpers (satu profil aktif per device) ======
  static const _kCurrentId = 'mother_current_id';

  Future<void> setCurrentId(String id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCurrentId, id);

    // Simpan juga pointer ke /device_index/{safeDeviceId} untuk auto-recover
    final deviceId = await _DeviceIdentity.getId();
    final clientKey = await _DeviceIdentity.getClientKey();
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

    // Auto-recover setelah reinstall: baca dari /device_index/{safeDeviceId}
    final deviceId = await _DeviceIdentity.getId();
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
    // Tidak menghapus device_index agar tetap bisa recover.
  }

  // ===================== CRUD =====================

  /// CREATE baru, return id & set sebagai current.
  Future<String> create(MotherProfile profile) async {
    await _tryEnsureSignedIn();
    final ref = _root.child('mothers').push();
    final uid = _uid; // bisa null kalau auth dimatikan
    final deviceId = await _DeviceIdentity.getId();

    await ref.set(profile.toMap(
      includeCreatedAt: true,
      forceOwnerId: uid,
      forceOwnerDeviceId: deviceId, // value saja, tidak dipakai sbg path
    ));

    final id = ref.key!;
    await setCurrentId(id);
    return id;
  }

  /// READ by id
  Future<MotherProfile?> read(String id) async {
    await _tryEnsureSignedIn(); // tidak fatal bila gagal
    final snap = await _motherRef(id).get();
    if (!snap.exists || snap.value == null) return null;
    return MotherProfile.fromMap(id, Map<String, dynamic>.from(snap.value as Map));
  }

  /// READ current
  Future<MotherProfile?> readCurrent() async {
    await _tryEnsureSignedIn();
    final id = await getCurrentId();
    if (id == null) return null;
    return read(id);
  }

  /// UPDATE by id (partial)
  Future<void> update(String id, Map<String, dynamic> updates) async {
    await _tryEnsureSignedIn();
    updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    if (updates.containsKey('nama')) {
      updates['nama_lower'] = (updates['nama'] as String).toLowerCase().trim();
    }
    if (updates.containsKey('noHp')) {
      updates['noHp_norm'] = MotherProfile._normalizePhone(updates['noHp'] as String);
    }
    // bila auth ada, pertahankan ownerId
    final uid = _uid;
    if (uid != null && updates['ownerId'] == null) {
      updates['ownerId'] = uid;
    }
    await _motherRef(id).update(updates);
  }

  /// UPDATE current
  Future<void> updateCurrent(Map<String, dynamic> updates) async {
    final id = await getCurrentId();
    if (id == null) throw StateError('No current mother id');
    await update(id, updates);
  }

  /// DELETE by id
  Future<void> delete(String id) async {
    await _tryEnsureSignedIn();
    await _motherRef(id).remove();
    final cur = await getCurrentId();
    if (cur == id) await clearCurrentId();
  }

  /// DELETE current
  Future<void> deleteCurrent() async {
    final id = await getCurrentId();
    if (id == null) return;
    await delete(id);
  }

  /// LIST:
  /// - Jika auth tersedia → ambil milik user (ownerId == uid), lalu filter nama di client.
  /// - Jika auth tidak tersedia → ambil global (limitToLast) dan boleh pakai prefix server-side.
  Future<List<MotherProfile>> list({
    int limit = 50,
    String? namePrefixLower,
  }) async {
    await _tryEnsureSignedIn();

    final uid = _uid;
    Query q;

    if (uid != null) {
      // Mode aman (per user)
      q = _root
          .child('mothers')
          .orderByChild('ownerId')
          .equalTo(uid)
          .limitToLast(limit);
    } else {
      // Fallback DEV (tanpa auth). Bisa pakai prefix server-side bila ada.
      if (namePrefixLower != null && namePrefixLower.isNotEmpty) {
        final start = namePrefixLower;
        final end = '$namePrefixLower\uf8ff';
        q = _root
            .child('mothers')
            .orderByChild('nama_lower')
            .startAt(start)
            .endAt(end)
            .limitToLast(limit);
      } else {
        q = _root.child('mothers').limitToLast(limit);
      }
    }

    final snap = await q.get();
    if (!snap.exists || snap.value == null) return <MotherProfile>[];

    final map = Map<String, dynamic>.from(snap.value as Map);
    var list = map.entries
        .map((e) =>
            MotherProfile.fromMap(e.key, Map<String, dynamic>.from(e.value as Map)))
        .toList();

    // Jika auth ada dan user minta filter nama → lakukan di client
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
