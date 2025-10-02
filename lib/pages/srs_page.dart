import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Tambahkan import ini
// Import model RiskFactor yang baru kita buat
// --- PENTING: SESUAIKAN PATH INI DENGAN NAMA PROYEK ANDA ---
import 'package:stunting_application/models/risk_factor.dart';
// --- AKHIR PENTING ---

/// Halaman Perhitungan "Skor Risiko Stunting (SRS)"
/// Catatan:
/// - Ini HEURISTIK programatik untuk penyaringan risiko, bukan diagnosis klinis.
/// - Bobot & ambang sesuai ringkasan jurnal yang kamu berikan.
///   Bobot 2: Ibu_pendek, BBLR, Prematur, PanjangLahirPendek/IUGR, ASI_nonEksklusif,
///            MPASI_tidakAdekuat, WASH_buruk
///   Bobot 1: UsiaIbuRemaja, LILA_kurang, PendidikanIbuRendah, PendapatanRendah,
///            ART_banyak, Ayah_pendek, Anak_laki, Diare_berulang/Infeksi,
///            Imunisasi_tidak_lengkap, PolaAsuh_tidak_adekuat, Pajanan_pestisida
///   Kategori: 0–4 Rendah, 5–8 Sedang, ≥9 Tinggi
class SrsPage extends StatefulWidget {
  const SrsPage({super.key});

  @override
  State<SrsPage> createState() => _SrsPageState();
}

class _SrsPageState extends State<SrsPage> {
  /// Kelompok variabel bobot 2 (nilai 1 jika "ya/berisiko")
  /// Kini disimpan sebagai Map dengan kunci String dan nilai objek RiskFactor.
  Map<String, RiskFactor> _riskFactorsWeight2 = {};

  /// Kelompok variabel bobot 1 (nilai 1 jika "ya/berisiko")
  /// Kini disimpan sebagai Map dengan kunci String dan nilai objek RiskFactor.
  Map<String, RiskFactor> _riskFactorsWeight1 = {};

  int _score = 0;
  String _kategori = '-';
  String _saran = '—';
  bool _isLoading = true; // State untuk menunjukkan apakah data faktor risiko sedang dimuat

  // Inisialisasi referensi ke Realtime Database untuk menyimpan hasil perhitungan SRS
  // Kita akan menyimpan data di jalur "srs_calculations" sesuai rules-mu
  final DatabaseReference _dbRefSrsCalculations = FirebaseDatabase.instance.ref("srs_calculations");
  // Referensi baru ke path "risk_factors" untuk memuat konfigurasi faktor risiko
  final DatabaseReference _dbRefRiskFactors = FirebaseDatabase.instance.ref("risk_factors");

  @override
  void initState() {
    super.initState();
    _loadRiskFactors(); // Muat faktor risiko dari Firebase saat halaman diinisialisasi
  }

  /// Fungsi untuk memuat definisi faktor risiko dari Firebase Realtime Database.
  Future<void> _loadRiskFactors() async {
    // --- DEBUG LOG START ---
    print('DEBUG SRS_PAGE: _loadRiskFactors() dimulai. _isLoading = true');
    // --- DEBUG LOG END ---

    try {
      final snapshot = await _dbRefRiskFactors.get();

      // --- DEBUG LOG START ---
      print('DEBUG SRS_PAGE: Snapshot diterima dari Firebase Realtime Database.');
      print('DEBUG SRS_PAGE: snapshot.exists: ${snapshot.exists}');
      print('DEBUG SRS_PAGE: snapshot.value: ${snapshot.value != null ? 'Data Ada' : 'Null'}');
      // --- DEBUG LOG END ---

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        // --- DEBUG LOG START ---
        print('DEBUG SRS_PAGE: Data dari Firebase berhasil di-cast: $data');
        // --- DEBUG LOG END ---

        final Map<String, RiskFactor> tempRisk2 = {};
        final Map<String, RiskFactor> tempRisk1 = {};

        if (data['weight_2'] != null) {
          // --- DEBUG LOG START ---
          print('DEBUG SRS_PAGE: Memproses faktor bobot 2...');
          // --- DEBUG LOG END ---
          (data['weight_2'] as Map<dynamic, dynamic>).forEach((key, value) {
            tempRisk2[key.toString()] = RiskFactor.fromMap(key.toString(), value);
          });
          // --- DEBUG LOG START ---
          print('DEBUG SRS_PAGE: Selesai memproses ${tempRisk2.length} faktor bobot 2.');
          // --- DEBUG LOG END ---
        } else {
          // --- DEBUG LOG START ---
          print('DEBUG SRS_PAGE: Tidak ada data \'weight_2\' di Firebase. Pastikan struktur JSON benar.');
          // --- DEBUG LOG END ---
        }

        if (data['weight_1'] != null) {
          // --- DEBUG LOG START ---
          print('DEBUG SRS_PAGE: Memproses faktor bobot 1...');
          // --- DEBUG LOG END ---
          (data['weight_1'] as Map<dynamic, dynamic>).forEach((key, value) {
            tempRisk1[key.toString()] = RiskFactor.fromMap(key.toString(), value);
          });
          // --- DEBUG LOG START ---
          print('DEBUG SRS_PAGE: Selesai memproses ${tempRisk1.length} faktor bobot 1.');
          // --- DEBUG LOG END ---
        } else {
          // --- DEBUG LOG START ---
          print('DEBUG SRS_PAGE: Tidak ada data \'weight_1\' di Firebase. Pastikan struktur JSON benar.');
          // --- DEBUG LOG END ---
        }

        setState(() {
          _riskFactorsWeight2 = tempRisk2;
          _riskFactorsWeight1 = tempRisk1;
          _isLoading = false; // Set loading menjadi false karena data sudah dimuat
          // --- DEBUG LOG START ---
          print('DEBUG SRS_PAGE: setState() untuk data berhasil. _isLoading sekarang false.');
          // --- DEBUG LOG END ---
        });
      } else {
        // --- DEBUG LOG START ---
        print('DEBUG SRS_PAGE: Snapshot tidak ada atau value-nya null. Mengatur _isLoading ke false.');
        // --- DEBUG LOG END ---
        setState(() {
          _isLoading = false; // Set loading ke false meskipun tidak ada data
          // --- DEBUG LOG START ---
          print('DEBUG SRS_PAGE: setState() untuk data tidak ada. _isLoading sekarang false.');
          // --- DEBUG LOG END ---
        });
        // Opsional: tampilkan pesan error atau muat data default lokal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat memuat konfigurasi faktor risiko dari Firebase. Pastikan ada data di path `/risk_factors`.')),
        );
      }
    } catch (e) {
      // --- DEBUG LOG START ---
      print('DEBUG SRS_PAGE: Terjadi ERROR saat memuat faktor risiko: $e');
      // --- DEBUG LOG END ---
      setState(() {
        _isLoading = false; // Set loading ke false jika ada error
        // --- DEBUG LOG START ---
        print('DEBUG SRS_PAGE: setState() untuk error. _isLoading sekarang false.');
        // --- DEBUG LOG END ---
      });
      // Opsional: tampilkan pesan error kepada pengguna
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat konfigurasi faktor risiko: $e')),
      );
    }
  }


  void _hitungSRS() async {
    // Ubah metode menjadi async karena akan ada operasi I/O (database)
    int sum2 = 0;
    // Iterasi melalui semua objek RiskFactor di _riskFactorsWeight2
    _riskFactorsWeight2.forEach((key, rf) {
      if (rf.isSelected) { // Jika faktor risiko ini dicentang
        sum2++; // Hitung sebagai 1 (karena bobotnya sudah 2 di perhitungan akhir)
      }
    });

    int sum1 = 0;
    // Iterasi melalui semua objek RiskFactor di _riskFactorsWeight1
    _riskFactorsWeight1.forEach((key, rf) {
      if (rf.isSelected) { // Jika faktor risiko ini dicentang
        sum1++; // Hitung sebagai 1 (karena bobotnya sudah 1 di perhitungan akhir)
      }
    });

    // Perhitungan SRS menggunakan bobot yang telah ditentukan
    final int srs = (2 * sum2) + (1 * sum1);

    String kategori;
    String saran;
    if (srs >= 9) {
      kategori = 'Tinggi';
      saran =
          'Kunjungan rumah mingguan, konseling menyusui & MP-ASI, paket PMT protein hewani, '
          'perbaikan WASH prioritas, rujuk bila ada infeksi.';
    } else if (srs >= 5) {
      kategori = 'Sedang';
      saran =
          'Kelas ibu & caregiver, monitoring bulanan, paket edukasi MP-ASI, cek & lengkapi imunisasi.';
    } else {
      kategori = 'Rendah';
      saran = 'Intervensi universal & pemantauan rutin (posyandu/MT).';
    }

    setState(() {
      _score = srs;
      _kategori = kategori;
      _saran = saran;
    });

    // --- BAGIAN BARU: Kirim data ke Firebase Realtime Database ---
    try {
      // Konversi Map<String, RiskFactor> kembali ke Map<String, bool>
      // untuk menyimpan hanya status pilihan faktor risiko
      final Map<String, bool> selectedRisk2 = {};
      _riskFactorsWeight2.forEach((key, rf) {
        selectedRisk2[key] = rf.isSelected;
      });

      final Map<String, bool> selectedRisk1 = {};
      _riskFactorsWeight1.forEach((key, rf) {
        selectedRisk1[key] = rf.isSelected;
      });

      // Siapkan data perhitungan SRS untuk disimpan
      final Map<String, dynamic> srsData = {
        'timestamp': ServerValue.timestamp, // Mencatat waktu data dibuat
        'score': _score,
        'category': _kategori,
        'recommendation': _saran,
        'risk_factors_weight2': selectedRisk2, // Kirim semua faktor risiko bobot 2 yang terpilih
        'risk_factors_weight1': selectedRisk1, // Kirim semua faktor risiko bobot 1 yang terpilih
        // Kamu bisa menambahkan UID pengguna di sini jika sudah ada autentikasi
        // 'userId': FirebaseAuth.instance.currentUser?.uid,
      };

      // Menggunakan .push() untuk membuat ID unik baru, lalu .set() untuk menyimpan data
      await _dbRefSrsCalculations.push().set(srsData);

      // Tampilkan pesan sukses kepada pengguna
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data SRS berhasil disimpan ke database!'),
        ),
      );
    } catch (e) {
      // Tampilkan pesan error jika gagal
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data SRS: $e')));
      print(
        'Error saving SRS data: $e',
      ); // Cetak error ke konsol untuk debugging
    }
    // --- AKHIR BAGIAN BARU ---
  }

  void _reset() {
    setState(() {
      // Reset semua status isSelected dari objek RiskFactor menjadi false
      _riskFactorsWeight2.forEach((key, rf) => rf.isSelected = false);
      _riskFactorsWeight1.forEach((key, rf) => rf.isSelected = false);
      _score = 0;
      _kategori = '-';
      _saran = '—';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prediksi Stunting - Skor Risiko (SRS)"),
      ),
      body: Column(
        children: [
          // Info bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            // ignore: deprecated_member_use
            color: Colors.orange.withOpacity(0.15),
            child: const Text(
              "Checklist faktor risiko berdasarkan ringkasan jurnal. "
              "SRS dipakai untuk penyaringan/triase program, bukan diagnosis.",
              textAlign: TextAlign.center,
            ),
          ),

          // Tampilkan loading spinner jika data faktor risiko sedang dimuat
          _isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()))
              : Expanded( // Setelah data dimuat, tampilkan form checklist
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Membangun kartu grup untuk faktor risiko bobot 2
                        _buildGroupCard(
                          context,
                          title: "Faktor Bobot 2 (determinasi kuat)",
                          subtitle:
                              "Centang jika kondisi TERPENUHI/berisiko. Bobot ×2 per item.",
                          items: _riskFactorsWeight2, // Menggunakan map objek RiskFactor
                        ),
                        const SizedBox(height: 12),
                        // Membangun kartu grup untuk faktor risiko bobot 1
                        _buildGroupCard(
                          context,
                          title: "Faktor Bobot 1 (pendukung penting)",
                          subtitle:
                              "Centang jika kondisi TERPENUHI/berisiko. Bobot ×1 per item.",
                          items: _riskFactorsWeight1, // Menggunakan map objek RiskFactor
                        ),
                        const SizedBox(height: 90), // ruang untuk tombol bawah
                      ],
                    ),
                  ),
                ),

          // Hasil & tombol aksi fixed di bawah
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.orange.shade200)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                _ResultBar(score: _score, kategori: _kategori),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Tindak lanjut:",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Align(alignment: Alignment.centerLeft, child: Text(_saran)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _hitungSRS,
                        icon: const Icon(Icons.calculate),
                        label: const Text("Hitung SRS"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reset"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun widget Card untuk grup faktor risiko (bobot 1 atau 2).
  /// Kini menerima Map<String, RiskFactor> sebagai daftar item.
  Widget _buildGroupCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Map<String, RiskFactor> items, // Tipe diubah menjadi Map objek RiskFactor
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          initiallyExpanded: true,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          // Menggunakan items.values untuk mendapatkan list objek RiskFactor
          children: items.values.map((riskFactor) {
            return CheckboxListTile(
              value: riskFactor.isSelected, // Menggunakan properti isSelected dari objek RiskFactor
              onChanged: (v) {
                setState(() {
                  riskFactor.isSelected = v ?? false; // Memperbarui status isSelected pada objek RiskFactor
                  // Opsi: Anda bisa panggil _hitungSRS() di sini jika ingin skor langsung terupdate
                  // Atau biarkan tombol "Hitung SRS" yang memicu perhitungan, seperti yang sudah ada.
                });
              },
              title: Text(riskFactor.label), // Menggunakan label dari objek RiskFactor
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  final int score;
  final String kategori;
  const _ResultBar({required this.score, required this.kategori});

  Color _badgeColor() {
    if (kategori == 'Tinggi') return Colors.red;
    if (kategori == 'Sedang') return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: _badgeColor().withOpacity(0.08),
        border: Border.all(color: _badgeColor()),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.assessment),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Skor Risiko Stunting (SRS): $score",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _badgeColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              kategori,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
