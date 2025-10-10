// lib/pages/srs_history_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/mother_profile_repository.dart';

// ===============================
// MODELS DATA
// ===============================

class SrsRow {
  final String id;
  final String motherId; // Ditambahkan untuk pengelompokan
  final int score;
  final String category;
  final String recommendation;
  final int timestamp;
  final Map<String, bool> w2;
  final Map<String, bool> w1;
  final String motherName;

  SrsRow({
    required this.id,
    required this.motherId,
    required this.score,
    required this.category,
    required this.recommendation,
    required this.timestamp,
    required this.w2,
    required this.w1,
    required this.motherName,
  });

  factory SrsRow.fromMap(String id, Map<dynamic, dynamic> m) {
    Map<String, bool> _mapBool(dynamic x) {
      if (x is Map) {
        return Map<String, bool>.from(
          x.map((k, v) => MapEntry("$k", v == true)),
        );
      }
      return {};
    }

    final mother = (m['mother'] ?? {}) as Map? ?? {};
    final motherName = (mother['name'] ?? m['motherName'] ?? '').toString();
    // Menggunakan ownerId dari mother object atau default 'unknown'
    final motherId = (mother['ownerId'] ?? 'unknown_srs').toString();

    int parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse("$v") ?? 0;
    }

    return SrsRow(
      id: id,
      motherId: motherId,
      score: parseInt(m['score']),
      category: (m['category'] ?? '-').toString(),
      recommendation: (m['recommendation'] ?? '-').toString(),
      timestamp: parseInt(m['timestamp'] ?? m['createdAt']),
      w2: _mapBool(m['risk_factors_weight2']),
      w1: _mapBool(m['risk_factors_weight1']),
      motherName: motherName,
    );
  }

  String get formattedDate {
    if (timestamp == 0) return "-";
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}";
  }

  String get searchIndex =>
      '${motherName.toLowerCase()} ${category.toLowerCase()} ${score}';
}

class CalculatorRecord {
  final String id;
  final String motherId; // Ditambahkan untuk pengelompokan
  final int score;
  final String riskLabel;
  final String advice;
  final int timestamp;
  final Map<String, bool> checked;
  final Map<String, dynamic> groups;
  final Map<String, dynamic> meta;

  CalculatorRecord({
    required this.id,
    required this.motherId,
    required this.score,
    required this.riskLabel,
    required this.advice,
    required this.timestamp,
    required this.checked,
    required this.groups,
    required this.meta,
  });

  factory CalculatorRecord.fromMap(String id, Map<dynamic, dynamic> m) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse("$v") ?? 0;
    }

    // Mengambil motherId dari meta atau default 'unknown'
    final motherId = (m['meta']?['ownerId'] ?? 'unknown_calc').toString();

    final Map<String, dynamic> meta = (m['meta'] is Map)
        ? Map<String, dynamic>.from(m['meta'] as Map)
        : {};

    return CalculatorRecord(
      id: id,
      motherId: motherId,
      score: parseInt(m['score']),
      riskLabel: (m['riskLabel'] ?? '-').toString(),
      advice: (m['advice'] ?? '-').toString(),
      timestamp: parseInt(m['timestamp'] ?? m['createdAt']),
      checked: (m['checked'] ?? {}) is Map
          ? Map<String, bool>.from(m['checked'] as Map)
          : {},
      groups: (m['groups'] ?? {}) is Map
          ? Map<String, dynamic>.from(m['groups'] as Map)
          : {},
      meta: meta,
    );
  }

  String get formattedDate {
    if (timestamp == 0) return "-";
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}";
  }

  String get childLine {
    final child = (meta['child'] ?? {}) as Map? ?? {};
    final name = (child['name'] ?? '').toString();
    final sex = (child['sex'] ?? '').toString();
    final age = child['ageMonths'];
    final sexStr = sex == 'L' ? 'L' : (sex == 'P' ? 'P' : '-');
    final ageStr = (age == null) ? '-' : '$age bln';
    final nm = name.isEmpty ? '—' : name;
    return "$nm • $sexStr • $ageStr";
  }

  String get searchIndex =>
      '${childLine.toLowerCase()} ${riskLabel.toLowerCase()} ${score}';
}

class PregCheckRow {
  final String id;
  final String motherId;
  final String motherName;
  final int timestamp;
  final String conditionLabel;
  final double? bmi;
  final String bmiCategory;
  final int sri;
  final String category;
  final double? heightCm;
  final double? weightKg;
  final double? lilaCm;
  final String recommendation;

  PregCheckRow({
    required this.id,
    required this.motherId,
    required this.motherName,
    required this.timestamp,
    required this.conditionLabel,
    required this.bmi,
    required this.bmiCategory,
    required this.sri,
    required this.category,
    required this.heightCm,
    required this.weightKg,
    required this.lilaCm,
    required this.recommendation,
  });

  factory PregCheckRow.fromMap(
    String id,
    String motherIdFallback,
    Map<dynamic, dynamic> m,
  ) {
    T? asNum<T extends num>(dynamic v) {
      if (v == null) return null;
      if (v is T) return v;
      final p = double.tryParse('$v');
      if (p == null) return null;
      if (T == int) return (p.toInt()) as T;
      return p as T;
    }

    String label = (m['condition']?['label'] ?? '-').toString();
    final derived = m['derived'] ?? {};
    final input = m['input'] ?? {};
    final motherName = (m['motherName'] ?? '').toString();
    // Menggunakan motherId dari data input jika ada, atau dari argumen fallback
    final motherId = (m['motherId'] ?? motherIdFallback).toString();

    return PregCheckRow(
      id: id,
      motherId: motherId,
      motherName: motherName,
      timestamp: asNum<int>(m['timestamp']) ?? 0,
      conditionLabel: label,
      bmi: asNum<double>(derived['bmi']),
      bmiCategory: (derived['bmiCategory'] ?? '-').toString(),
      sri: asNum<int>(derived['sri']) ?? 0,
      category: (derived['category'] ?? '-').toString(),
      heightCm: asNum<double>(input['heightCm']),
      weightKg: asNum<double>(input['weightKg']),
      lilaCm: asNum<double>(input['lilaCm']),
      recommendation: (m['recommendation'] ?? '-').toString(),
    );
  }

  String get formattedDate {
    if (timestamp == 0) return "-";
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}";
  }

  String get searchIndex =>
      '${motherName.toLowerCase()} ${category.toLowerCase()} ${sri} ${conditionLabel.toLowerCase()}';
}

// ===============================
// HISTORY PAGE
// ===============================

class SrsHistoryPage extends StatefulWidget {
  const SrsHistoryPage({super.key});

  @override
  State<SrsHistoryPage> createState() => _SrsHistoryPageState();
}

class _SrsHistoryPageState extends State<SrsHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  final _dbRefSrs = FirebaseDatabase.instance.ref("srs_calculations");
  final _dbRefCalc = FirebaseDatabase.instance.ref("calculator_history");
  final _dbRefPreg = FirebaseDatabase.instance.ref("pregnancy_checks");
  final _motherRepo = MotherProfileRepository();

  String? _motherId;
  String? _motherName;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMother();
    _searchController.addListener(_updateSearchQuery);

    _dbRefSrs.keepSynced(true);
    _dbRefCalc.keepSynced(true);
    _dbRefPreg.keepSynced(true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_updateSearchQuery);
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchQuery() {
    if (_searchQuery != _searchController.text) {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    }
  }

  Future<void> _loadMother() async {
    try {
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
      });
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      color: Colors.grey.shade900,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Perhitungan (Admin)"),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          // --- PERUBAHAN DI SINI ---
          labelColor: Colors.white, // Warna teks tab yang aktif
          unselectedLabelColor: Colors.white.withOpacity(
            0.7,
          ), // Warna teks tab yang tidak aktif
          indicatorColor: Colors.white, // Warna garis indikator
          // --------------------------
          tabs: const [
            Tab(text: 'SRS'),
            Tab(text: 'Kalkulator'),
            Tab(text: 'Kehamilan'),
          ],
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverList(
            delegate: SliverChildListDelegate([
              _buildMotherBanner(titleStyle),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari berdasarkan nama/kategori...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _HistoryTab<SrsRow>(
              query: _searchQuery,
              dbRef: _dbRefSrs,
              motherId: _motherId,
              motherName: _motherName,
              rowFactory: (id, _, m) => SrsRow.fromMap(id, m),
              titleKey: 'motherName',
              subtitleKey: 'score',
              categoryKey: 'category',
              onTap: _showSrsDetails,
            ),
            _HistoryTab<CalculatorRecord>(
              query: _searchQuery,
              dbRef: _dbRefCalc,
              motherId: _motherId,
              motherName: _motherName,
              rowFactory: (id, _, m) => CalculatorRecord.fromMap(id, m),
              titleKey: 'childLine',
              subtitleKey: 'score',
              categoryKey: 'riskLabel',
              onTap: _showCalcDetails,
            ),
            _HistoryTab<PregCheckRow>(
              query: _searchQuery,
              dbRef: _dbRefPreg,
              motherId: _motherId,
              motherName: _motherName,
              rowFactory: (id, motherId, m) =>
                  PregCheckRow.fromMap(id, motherId, m),
              titleKey: 'motherName',
              subtitleKey: 'sri',
              categoryKey: 'category',
              onTap: _showPregDetails,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotherBanner(TextStyle titleStyle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.indigo,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mode Administrator: Menampilkan semua data riwayat.',
                style: titleStyle.copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelOf(String key) => key.replaceAll('_', ' ');

  void _showSrsDetails(SrsRow r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Detail Perhitungan SRS"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Waktu", r.formattedDate),
              _detailRow("Ibu (ID)", r.motherId),
              _detailRow("Nama Ibu", r.motherName.isEmpty ? "—" : r.motherName),
              const Divider(height: 16),
              _detailRow("Skor", r.score.toString()),
              _detailRow("Kategori", r.category),
              const SizedBox(height: 8),
              const Text(
                "Rekomendasi:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(r.recommendation),
              const Divider(height: 20),
              const Text(
                "Faktor Risiko Bobot 2",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...r.w2.entries
                  .where((e) => e.value)
                  .map((e) => Text("• ${_labelOf(e.key)}")),
              if (r.w2.entries.every((e) => !e.value))
                const Text("Tidak ada faktor bobot 2 yang terpilih."),
              const SizedBox(height: 10),
              const Text(
                "Faktor Risiko Bobot 1",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...r.w1.entries
                  .where((e) => e.value)
                  .map((e) => Text("• ${_labelOf(e.key)}")),
              if (r.w1.entries.every((e) => !e.value))
                const Text("Tidak ada faktor bobot 1 yang terpilih."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showCalcDetails(CalculatorRecord rec) {
    String _groupTitle(String k) {
      switch (k) {
        case 'directBirth':
          return 'Penyebab Langsung — Riwayat Lahir';
        case 'directFeeding':
          return 'Penyebab Langsung — Pemberian Makan';
        case 'directInfection':
          return 'Penyebab Langsung — Infeksi & Imunisasi';
        case 'maternal':
          return 'Tidak Langsung — Ibu';
        case 'householdWASH':
          return 'Tidak Langsung — Rumah Tangga & WASH';
        case 'childOther':
          return 'Faktor Anak Tambahan';
        default:
          return k;
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Detail Perhitungan Kalkulator"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Waktu", rec.formattedDate),
              _detailRow("ID Ibu", rec.motherId),
              _detailRow("Data Anak", rec.childLine),
              const Divider(height: 16),
              _detailRow("Skor", rec.score.toString()),
              _detailRow("Kategori", rec.riskLabel),
              const SizedBox(height: 8),
              const Text(
                "Saran:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(rec.advice),
              const Divider(height: 20),
              ...rec.groups.entries.map((g) {
                final list = (g.value is List) ? (g.value as List) : const [];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _groupTitle(g.key),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (list.isEmpty)
                        const Text("— (tidak ada)")
                      else
                        ...list.map(
                          (e) => Text("• ${e.toString().replaceAll('_', ' ')}"),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showPregDetails(PregCheckRow r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Detail Pemeriksaan Kehamilan"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Waktu", r.formattedDate),
              _detailRow("Ibu (ID)", r.motherId),
              _detailRow(
                "Nama Ibu",
                r.motherName.isNotEmpty ? r.motherName : r.motherId,
              ),
              _detailRow("Kondisi", r.conditionLabel),
              const Divider(height: 16),
              _detailRow("Tinggi (cm)", r.heightCm?.toStringAsFixed(1) ?? "-"),
              _detailRow("Berat (kg)", r.weightKg?.toStringAsFixed(1) ?? "-"),
              _detailRow("LILA (cm)", r.lilaCm?.toStringAsFixed(1) ?? "-"),
              _detailRow("BMI", r.bmi?.toStringAsFixed(1) ?? "-"),
              _detailRow("Kategori BMI", r.bmiCategory),
              _detailRow("SRI", r.sri.toString()),
              _detailRow("Kategori", r.category),
              const SizedBox(height: 8),
              const Text(
                "Rekomendasi:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(r.recommendation),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ===================================
// GENERIC TAB VIEW & DATA HANDLING
// ===================================

typedef RowFactory<T> =
    T Function(String id, String motherId, Map<dynamic, dynamic> map);

class _HistoryTab<T> extends StatelessWidget {
  final String query;
  final DatabaseReference dbRef;
  final String? motherId;
  final String? motherName;
  final RowFactory<T> rowFactory;
  final String titleKey;
  final String subtitleKey;
  final String categoryKey;
  final Function(T) onTap;

  const _HistoryTab({
    super.key,
    required this.query,
    required this.dbRef,
    required this.motherId,
    required this.motherName,
    required this.rowFactory,
    required this.titleKey,
    required this.subtitleKey,
    required this.categoryKey,
    required this.onTap,
  });

  Color _badgeBase(String s) {
    final x = s.toLowerCase();
    if (x.contains('tinggi') || x.contains('obesitas') || x.contains('merah'))
      return Colors.red;
    if (x.contains('sedang') || x.contains('berlebih') || x.contains('kuning'))
      return Colors.orange;
    return Colors.green;
  }

  String _getProp(T item, String key) {
    final itemDynamic = item as dynamic;

    if (key == 'category' || key == 'riskLabel') {
      if (item is CalculatorRecord) return item.riskLabel;
      if (item is SrsRow) return item.category;
      if (item is PregCheckRow) return item.category;
      return '-';
    }

    switch (key) {
      case 'motherId':
        return itemDynamic.motherId ?? '—';
      case 'motherName':
        return itemDynamic.motherName ?? '—';
      case 'childLine':
        return itemDynamic.childLine ?? '—';
      case 'score':
        return itemDynamic.score?.toString() ?? '-';
      case 'sri':
        return itemDynamic.sri?.toString() ?? '-';
      default:
        return '-';
    }
  }

  String _getGroupingKey(T item) {
    final itemDynamic = item as dynamic;
    if (item is PregCheckRow) return item.motherId;
    return itemDynamic.motherId ?? 'Unknown';
  }

  List<T> _parseSnapshot(DataSnapshot? rawSnapshot) {
    if (rawSnapshot == null ||
        !rawSnapshot.exists ||
        rawSnapshot.value == null) {
      return const [];
    }

    final List<T> list = [];
    final value = rawSnapshot.value;

    if (value is Map) {
      if (T == PregCheckRow) {
        final Map<dynamic, dynamic> checksByMother = value;
        checksByMother.forEach((motherId, motherNode) {
          if (motherNode is Map) {
            final Map<dynamic, dynamic> records = motherNode;
            records.forEach((recordId, recordData) {
              if (recordData is Map) {
                try {
                  final item = rowFactory(
                    recordId.toString(),
                    motherId.toString(),
                    Map<dynamic, dynamic>.from(recordData),
                  );
                  list.add(item);
                } catch (e) {
                  print(
                    "Error parsing PregCheck record $motherId/$recordId: $e",
                  );
                }
              }
            });
          }
        });
      } else {
        final map = Map<dynamic, dynamic>.from(value);
        map.forEach((id, recordData) {
          if (recordData is Map) {
            try {
              final item = rowFactory(
                id.toString(),
                'unused',
                Map<dynamic, dynamic>.from(recordData),
              );
              list.add(item);
            } catch (e) {
              print("Error parsing record $id: $e");
            }
          }
        });
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final Query ref = (T == PregCheckRow)
        ? dbRef
        : dbRef.orderByChild('timestamp');

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rawSnapshot = snapshot.data?.snapshot;
        final allItems = _parseSnapshot(rawSnapshot);

        final filteredItems = allItems.where((item) {
          final itemDynamic = item as dynamic;
          if (query.isNotEmpty &&
              !(itemDynamic.searchIndex as String).contains(query)) {
            return false;
          }
          return true;
        }).toList();

        if (filteredItems.isEmpty && query.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Belum ada riwayat data di tab ini.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (filteredItems.isEmpty && query.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Tidak ditemukan hasil untuk "$query".',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final Map<String, List<T>> grouped = {};
        for (final item in filteredItems) {
          final key = _getGroupingKey(item);
          grouped.putIfAbsent(key, () => []).add(item);
        }

        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) {
            if (a == motherId) return -1;
            if (b == motherId) return 1;
            return a.compareTo(b);
          });

        for (final key in sortedKeys) {
          grouped[key]!.sort(
            (a, b) =>
                (b as dynamic).timestamp.compareTo((a as dynamic).timestamp),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final key = sortedKeys[index];
            final itemsInGroup = grouped[key]!;
            final firstItem = itemsInGroup.first as dynamic;

            String title;
            if (T == CalculatorRecord) {
              title = (key == motherId && motherName != null)
                  ? 'Ibu Aktif: $motherName'
                  : 'ID Ibu: $key (${itemsInGroup.length} riwayat)';
            } else {
              title = firstItem.motherName?.isNotEmpty == true
                  ? firstItem.motherName
                  : (key == motherId && motherName != null)
                  ? 'Ibu Aktif: $motherName'
                  : 'ID Ibu: $key';
            }

            if (key == motherId) {
              title = '⭐ $title';
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  initiallyExpanded: key == motherId,
                  backgroundColor: Colors.indigo.shade50.withOpacity(0.5),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: (T == CalculatorRecord)
                      ? Text(
                          "Anak-anak: ${itemsInGroup.map((i) => (i as CalculatorRecord).childLine.split(' • ').first).toSet().join(', ')}",
                        )
                      : null,
                  children: itemsInGroup.map((item) {
                    final itemDynamic = item as dynamic;
                    final cat = _getProp(item, categoryKey);
                    final base = _badgeBase(cat);

                    final subtitle = (T == CalculatorRecord)
                        ? itemDynamic.childLine
                        : "Skor: ${_getProp(item, subtitleKey)} • Waktu: ${itemDynamic.formattedDate}";

                    return ListTile(
                      leading: Icon(
                        (T == PregCheckRow)
                            ? Icons.pregnant_woman
                            : Icons.assessment,
                        color: base.withOpacity(0.8),
                      ),
                      title: Text(itemDynamic.formattedDate),
                      subtitle: Text(subtitle),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: base.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: base.withOpacity(0.35)),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: base,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      onTap: () => onTap(item),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
