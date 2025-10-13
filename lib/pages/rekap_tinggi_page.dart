// lib/pages/rekap_tinggi_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stunting_application/models/child_repository.dart';
import 'package:stunting_application/models/mother_profile_repository.dart';

class ChildGrowthRecapPage extends StatefulWidget {
  final String? motherId;
  final String? childId;
  final String childName;
  final int? childBirthDateMs;

  const ChildGrowthRecapPage({
    super.key,
    this.motherId, // Parameter untuk admin
    this.childId,  // Parameter untuk admin
    required this.childName,
    this.childBirthDateMs,
  });

  @override
  State<ChildGrowthRecapPage> createState() => _ChildGrowthRecapPageState();
}

class _ChildGrowthRecapPageState extends State<ChildGrowthRecapPage> {
  final _motherRepo = MotherProfileRepository();
  final _childRepo = ChildRepository();

  List<HeightData> _heightData = [];
  bool _isLoading = true;
  String? _error;
  String? _resolvedMotherId;
  String? _resolvedChildId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final motherId = widget.motherId ?? await _motherRepo.getCurrentId();
      final childId = widget.childId;

      if (motherId == null || childId == null) {
        throw Exception("ID Ibu atau Anak tidak ditemukan.");
      }
      _resolvedMotherId = motherId;
      _resolvedChildId = childId;

      final data = await _childRepo.getHeightRecords(motherId, childId);
      data.sort((a, b) => a.measurementDate.compareTo(b.measurementDate));
      if (mounted) {
        setState(() {
          _heightData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Gagal memuat data: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddHeightEntryDialog() async {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    double? height;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Data Tinggi Badan'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Tinggi Badan (cm)',
                        prefixIcon: Icon(Icons.height),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon masukkan tinggi badan';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Format tidak valid';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        height = double.tryParse(value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                          'Tanggal: ${DateFormat('dd MMMM yyyy').format(selectedDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: widget.childBirthDateMs != null
                              ? DateTime.fromMillisecondsSinceEpoch(
                                  widget.childBirthDateMs!)
                              : DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      if (height != null) {
                        try {
                          final newRecord = HeightData(
                            heightCm: height!,
                            measurementDate: selectedDate,
                          );
                          await _childRepo.addHeightRecord(
                              _resolvedMotherId!, _resolvedChildId!, newRecord);
                          Navigator.of(context).pop();
                          _loadInitialData(); // Muat ulang data
                        } catch (e) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Gagal menyimpan: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rekap Tinggi: ${widget.childName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : _heightData.isEmpty
                  ? Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Belum ada data tinggi badan.'),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Input Data Pertama"),
                          onPressed: _showAddHeightEntryDialog,
                        )
                      ],
                    ))
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        _buildChartCard(),
                        const SizedBox(height: 16),
                        _buildDataTableCard(),
                      ],
                    ),
      floatingActionButton: _heightData.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddHeightEntryDialog,
              tooltip: 'Tambah Data',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildChartCard() {
    final spots = _heightData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.heightCm);
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Grafik Pertumbuhan Tinggi Badan",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.green,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTableCard() {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Tanggal')),
            DataColumn(label: Text('Tinggi (cm)')),
            DataColumn(label: Text('Usia Saat Ukur')),
          ],
          rows: _heightData.map((data) {
            String age = '-';
            if (widget.childBirthDateMs != null) {
              final birthDate =
                  DateTime.fromMillisecondsSinceEpoch(widget.childBirthDateMs!);
              final months =
                  data.measurementDate.difference(birthDate).inDays ~/ 30;
              age = '$months bulan';
            }
            return DataRow(cells: [
              DataCell(
                  Text(DateFormat('dd MMM yyyy').format(data.measurementDate))),
              DataCell(Text(data.heightCm.toStringAsFixed(1))),
              DataCell(Text(age)),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}