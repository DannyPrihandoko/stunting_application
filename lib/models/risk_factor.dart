// lib/models/risk_factor.dart

/// Kelas model untuk merepresentasikan setiap faktor risiko secara terstruktur.
class RiskFactor {
  final String key;      // Kunci unik dari Firebase (misal: "ibu_pendek")
  final String label;    // Label untuk tampilan (misal: "Ibu bertubuh pendek")
  final int weight;      // Bobot faktor risiko (1 atau 2)
  bool isSelected;       // Status checkbox, diatur oleh pengguna di UI

  RiskFactor({
    required this.key,
    required this.label,
    required this.weight,
    this.isSelected = false, // Default ke false saat pertama kali dimuat
  });

  /// Factory constructor untuk membuat objek RiskFactor dari Map yang diambil dari Firebase.
  /// Ini mengurai data dari struktur JSON `risk_factors` Anda.
  factory RiskFactor.fromMap(String key, Map<dynamic, dynamic> map) {
    return RiskFactor(
      key: key,
      label: map['label']?.toString() ?? key, // Fallback ke key jika label tidak ada
      weight: map['weight'] as int? ?? 1,      // Default weight 1 jika tidak ada
      isSelected: false, // Selalu mulai dengan false saat dimuat dari database
    );
  }
}
