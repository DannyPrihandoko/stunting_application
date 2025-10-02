import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Tambahkan import ini

/// Halaman Perhitungan "Skor Risiko Stunting (SRS)"
/// Catatan:
/// - Ini HEURISTIK programatik untuk penyaringan risiko, bukan diagnosis klinis.
/// - Bobot & ambang sesuai ringkasan jurnal yang kamu berikan.
///   Bobot 2: Ibu_pendek, BBLR, Prematur, PanjangLahirPendek/IUGR, ASI_nonEksklusif,
///            MPASI_tidakAdekuat, WASH_buruk
///   Bobot 1: UsiaIbuRemaja, LILA_kurang, PendidikanIbuRendah, PendapatanRendah,
///            ART_banyak, Ayah_pendek, Anak_laki, Diare_berulang/Infeksi,
///            Imunisasi_tidak_lengkap, PolaAsuh_tidak_adeuat, Pajanan_pestisida
///   Kategori: 0–4 Rendah, 5–8 Sedang, ≥9 Tinggi
class SrsPage extends StatefulWidget {
  const SrsPage({super.key});

  @override
  State<SrsPage> createState() => _SrsPageState();
}

class _SrsPageState extends State<SrsPage> {
  /// Kelompok variabel bobot 2 (nilai 1 jika "ya/berisiko")
  final Map<String, bool> _risk2 = {
    'Ibu_pendek': false,
    'BBLR': false,
    'Prematur': false,
    'PanjangLahirPendek/IUGR': false,
    'ASI_nonEksklusif': false,
    'MPASI_tidakAdekuat': false,
    'WASH_buruk': false,
  };

  /// Kelompok variabel bobot 1 (nilai 1 jika "ya/berisiko")
  final Map<String, bool> _risk1 = {
    'UsiaIbuRemaja': false,
    'LILA_kurang': false,
    'PendidikanIbuRendah': false,
    'PendapatanRendah': false,
    'ART_banyak (≥5)': false,
    'Ayah_pendek': false,
    'Anak_laki': false,
    'Diare_berulang/Infeksi': false,
    'Imunisasi_tidak_lengkap': false,
    'PolaAsuh_tidak_adekuat': false, // (label diperbaiki ejaan)
    'Pajanan_pestisida': false,
  };

  int _score = 0;
  String _kategori = '-';
  String _saran = '—';

  // Inisialisasi referensi ke Realtime Database
  // Kita akan menyimpan data di jalur "srs_calculations" sesuai rules-mu
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(
    "srs_calculations",
  );

  void _hitungSRS() async {
    // Ubah metode menjadi async karena akan ada operasi I/O (database)
    final int sum2 = _risk2.values.where((v) => v).length;
    final int sum1 = _risk1.values.where((v) => v).length;
    final int srs = 2 * sum2 + 1 * sum1;

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
      final Map<String, dynamic> srsData = {
        'timestamp': ServerValue.timestamp, // Mencatat waktu data dibuat
        'score': _score,
        'category': _kategori,
        'recommendation': _saran,
        'risk_factors_weight2': _risk2.map(
          (key, value) => MapEntry(key, value),
        ), // Kirim semua faktor risiko bobot 2
        'risk_factors_weight1': _risk1.map(
          (key, value) => MapEntry(key, value),
        ), // Kirim semua faktor risiko bobot 1
        // Kamu bisa menambahkan UID pengguna di sini jika sudah ada autentikasi
        // 'userId': FirebaseAuth.instance.currentUser?.uid,
      };

      // Menggunakan .push() untuk membuat ID unik baru, lalu .set() untuk menyimpan data
      await _dbRef.push().set(srsData);

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
    for (final k in _risk2.keys) {
      _risk2[k] = false;
    }
    for (final k in _risk1.keys) {
      _risk1[k] = false;
    }
    setState(() {
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

          // Form checklist
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildGroupCard(
                    context,
                    title: "Faktor Bobot 2 (determinasi kuat)",
                    subtitle:
                        "Centang jika kondisi TERPENUHI/berisiko. Bobot ×2 per item.",
                    items: _risk2,
                    prettyMap: const {
                      'Ibu_pendek': 'Ibu bertubuh pendek',
                      'BBLR': 'Berat Badan Lahir Rendah (BBLR)',
                      'Prematur': 'Prematur',
                      'PanjangLahirPendek/IUGR': 'Panjang lahir pendek / IUGR',
                      'ASI_nonEksklusif': 'Tidak ASI eksklusif 0–6 bln',
                      'MPASI_tidakAdekuat': 'MP-ASI tidak adekuat',
                      'WASH_buruk':
                          'WASH buruk (jamban tidak layak/air tidak diolah)',
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildGroupCard(
                    context,
                    title: "Faktor Bobot 1 (pendukung penting)",
                    subtitle:
                        "Centang jika kondisi TERPENUHI/berisiko. Bobot ×1 per item.",
                    items: _risk1,
                    prettyMap: const {
                      'UsiaIbuRemaja': 'Kehamilan usia remaja',
                      'LILA_kurang': 'LILA ibu kurang',
                      'PendidikanIbuRendah': 'Pendidikan ibu rendah',
                      'PendapatanRendah': 'Pendapatan keluarga rendah',
                      'ART_banyak (≥5)': 'Anggota rumah tangga banyak (≥5)',
                      'Ayah_pendek': 'Ayah bertubuh pendek',
                      'Anak_laki': 'Jenis kelamin anak laki-laki',
                      'Diare_berulang/Infeksi': 'Diare berulang / infeksi',
                      'Imunisasi_tidak_lengkap': 'Imunisasi tidak lengkap',
                      'PolaAsuh_tidak_adekuat': 'Pola asuh tidak adekuat',
                      'Pajanan_pestisida': 'Pajanan pestisida',
                    },
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

  Widget _buildGroupCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Map<String, bool> items,
    required Map<String, String> prettyMap,
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
          children: items.keys.map((key) {
            final label = prettyMap[key] ?? key;
            final value = items[key] ?? false;
            return CheckboxListTile(
              value: value,
              onChanged: (v) => setState(() => items[key] = v ?? false),
              title: Text(label),
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
