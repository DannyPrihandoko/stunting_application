
// lib/services/pin_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  final _storage = const FlutterSecureStorage();
  static const _pinKey = 'admin_pin';
  static const String defaultPin = '1234'; // PIN awal

  /// Mengambil PIN yang tersimpan. Jika belum ada, kembalikan PIN default.
  Future<String> getPin() async {
    return await _storage.read(key: _pinKey) ?? defaultPin;
  }

  /// Menyimpan PIN baru ke secure storage.
  Future<void> setPin(String newPin) async {
    await _storage.write(key: _pinKey, value: newPin);
  }

  /// Memverifikasi PIN yang dimasukkan dengan PIN yang tersimpan.
  Future<bool> verifyPin(String inputPin) async {
    final storedPin = await getPin();
    return storedPin == inputPin;
  }
}