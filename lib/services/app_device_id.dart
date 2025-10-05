// lib/services/app_device_id.dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Penyedia ID perangkat yang stabil per-app.
/// - Android: gunakan ANDROID_ID (SSAID).
/// - iOS: buat UUID dan simpan di Keychain (persist lintas reinstall).
/// Juga simpan clientKey (random) di secure storage.
class AppDeviceId {
  static const _kKeychainDeviceId = 'app_device_id';
  static const _kKeychainClientKey = 'app_client_key';
  static const _kPrefsFallbackId = 'app_device_id_fallback'; // Android fallback

  static final _secure = const FlutterSecureStorage();
  static final _deviceInfo = DeviceInfoPlugin();
  static final _uuid = const Uuid();

  /// ID perangkat aplikasi yang stabil (lihat catatan Android/iOS di atas).
  static Future<String> getId() async {
    if (Platform.isIOS) {
      final existing = await _secure.read(key: _kKeychainDeviceId);
      if (existing != null && existing.isNotEmpty) return existing;
      final id = _uuid.v4();
      await _secure.write(key: _kKeychainDeviceId, value: id);
      return id;
    } else if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      final ssaid = info.id; // ANDROID_ID
      if (ssaid.isNotEmpty) return ssaid;

      // Fallback jarang dipakai (untuk device tak memberi ANDROID_ID)
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kPrefsFallbackId);
      if (saved != null && saved.isNotEmpty) return saved;
      final generated = _uuid.v4();
      await prefs.setString(_kPrefsFallbackId, generated);
      return generated;
    } else {
      // Platform lain: pakai secure storage + fallback
      final existing = await _secure.read(key: _kKeychainDeviceId);
      if (existing != null && existing.isNotEmpty) return existing;
      final id = _uuid.v4();
      await _secure.write(key: _kKeychainDeviceId, value: id);
      return id;
    }
  }

  /// Kunci lokal random untuk tambahan verifikasi di sisi app (opsional).
  static Future<String> getClientKey() async {
    final existing = await _secure.read(key: _kKeychainClientKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final key = _uuid.v4().replaceAll('-', '') + _uuid.v4().replaceAll('-', '');
    await _secure.write(key: _kKeychainClientKey, value: key);
    return key;
  }
}
