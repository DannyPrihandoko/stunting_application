// lib/models/who_anthro_mock.dart
// Data mock Z-score (SD) WHO untuk WFH (Weight-for-Height/Length)
// Digunakan untuk menilai status Gizi (Gizi Buruk hingga Obesitas)
// Data disederhanakan: WFH berdasarkan Panjang/Tinggi Badan (L) dalam cm.
// Sumber data sebenarnya sangat kompleks, ini adalah representasi MOCK data statis.

abstract final class WhoAnthroData {
  // Nilai Median (M), SD -3, -2, +1, +2, +3 untuk BB berdasarkan TB
  // Kunci map: Tinggi Badan (cm)
  static const Map<String, Map<String, double>> wfhBoys = {
    // 45 cm (sekitar newborn)
    "45.0": {"M": 2.5, "-3": 1.9, "-2": 2.1, "+1": 2.9, "+2": 3.2, "+3": 3.4},
    // 65 cm (sekitar 6 bln)
    "65.0": {"M": 7.3, "-3": 5.7, "-2": 6.2, "+1": 8.3, "+2": 9.0, "+3": 9.7},
    // 85 cm (sekitar 18 bln)
    "85.0": {
      "M": 11.7,
      "-3": 9.6,
      "-2": 10.3,
      "+1": 13.0,
      "+2": 13.9,
      "+3": 14.8,
    },
    // 100 cm (sekitar 3 tahun)
    "100.0": {
      "M": 15.6,
      "-3": 12.9,
      "-2": 13.9,
      "+1": 17.5,
      "+2": 18.7,
      "+3": 19.9,
    },
    // 110 cm (sekitar 4.5 tahun)
    "110.0": {
      "M": 19.1,
      "-3": 16.0,
      "-2": 17.1,
      "+1": 21.4,
      "+2": 22.9,
      "+3": 24.4,
    },
  };

  static const Map<String, Map<String, double>> wfhGirls = {
    // 45 cm
    "45.0": {"M": 2.4, "-3": 1.9, "-2": 2.1, "+1": 2.8, "+2": 3.0, "+3": 3.3},
    // 65 cm
    "65.0": {"M": 6.8, "-3": 5.3, "-2": 5.8, "+1": 7.8, "+2": 8.4, "+3": 9.0},
    // 85 cm
    "85.0": {
      "M": 11.2,
      "-3": 9.1,
      "-2": 9.8,
      "+1": 12.4,
      "+2": 13.2,
      "+3": 14.1,
    },
    // 100 cm
    "100.0": {
      "M": 15.1,
      "-3": 12.4,
      "-2": 13.4,
      "+1": 17.0,
      "+2": 18.1,
      "+3": 19.3,
    },
    // 110 cm
    "110.0": {
      "M": 18.4,
      "-3": 15.3,
      "-2": 16.5,
      "+1": 20.6,
      "+2": 21.9,
      "+3": 23.3,
    },
  };

  /// Fungsi untuk mendapatkan nilai Z-Score SD terdekat (M, -3, -2, +1, +2, +3)
  /// Berdasarkan tinggi (heightCm) dan jenis kelamin (sex: "L"/"P").
  static Map<String, double>? getWfhData(double heightCm, String sex) {
    final Map<String, Map<String, double>> data = sex == 'L'
        ? wfhBoys
        : wfhGirls;

    // Cari tinggi terdekat yang ada di data (linear interpolation diabaikan untuk kesederhanaan)
    final sortedHeights = data.keys.map(double.parse).toList()..sort();

    double? nearestHeightKey;
    double minDiff = double.infinity;

    for (var h in sortedHeights) {
      double diff = (h - heightCm).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearestHeightKey = h;
      }
    }

    if (nearestHeightKey != null) {
      return data[nearestHeightKey.toStringAsFixed(1)];
    }
    return null;
  }
}
