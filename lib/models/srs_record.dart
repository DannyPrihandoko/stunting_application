// lib/models/srs_record.dart
import 'package:intl/intl.dart'; // Diperlukan untuk format tanggal. PASTIKAN PACKAGE INI ADA DI pubspec.yaml ANDA!

/// Model data untuk satu entri perhitungan Skor Risiko Stunting (SRS).
/// Merepresentasikan struktur data yang disimpan di /srs_calculations.
class SrsRecord {
  final String id; // Kunci unik (push key) dari Firebase
  final int timestamp;
  final int score;
  final String category;
  final String recommendation;
  final Map<String, bool> riskFactorsWeight1;
  final Map<String, bool> riskFactorsWeight2;

  SrsRecord({
    required this.id,
    required this.timestamp,
    required this.score,
    required this.category,
    required this.recommendation,
    required this.riskFactorsWeight1,
    required this.riskFactorsWeight2,
  });

  /// Factory constructor untuk membuat objek SrsRecord dari Map yang diterima dari Firebase.
  factory SrsRecord.fromMap(String id, Map<dynamic, dynamic> map) {
    return SrsRecord(
      id: id,
      timestamp: map['timestamp'] as int? ?? 0, // Default 0 jika null
      score: map['score'] as int? ?? 0,         // Default 0 jika null
      category: map['category'] as String? ?? 'N/A', // Default 'N/A' jika null
      recommendation: map['recommendation'] as String? ?? 'N/A', // Default 'N/A' jika null
      // Mengonversi Map<dynamic, dynamic> dari Firebase ke Map<String, bool>
      riskFactorsWeight1: Map<String, bool>.from(
          (map['risk_factors_weight1'] as Map<dynamic, dynamic>?)
                  ?.map((k, v) => MapEntry(k.toString(), v as bool)) ??
              {}),
      riskFactorsWeight2: Map<String, bool>.from(
          (map['risk_factors_weight2'] as Map<dynamic, dynamic>?)
                  ?.map((k, v) => MapEntry(k.toString(), v as bool)) ??
              {}),
    );
  }

  /// Helper getter untuk mendapatkan tanggal dan waktu yang diformat.
  String get formattedDate {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    // Format ke "dd/MM/yyyy HH:mm"
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
