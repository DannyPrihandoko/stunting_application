// lib/pages/rekap_berat_page.dart

import 'package:stunting_application/models/child_repository.dart';
import 'package:stunting_application/models/mother_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ChildWeightRecapPage extends StatefulWidget {
  final String? motherId;
  final String? childId;
  final String childName;
  final int? childBirthDateMs;

  const ChildWeightRecapPage({
    super.key,
    this.motherId,
    this.childId,
    required this.childName,
    this.childBirthDateMs,
  });

  @override
  State<ChildWeightRecapPage> createState() => _ChildWeightRecapPageState();
}

class _ChildWeightRecapPageState extends State<ChildWeightRecapPage> {
  final _motherRepo = MotherProfileRepository();
  final _childRepo = ChildRepository();

  List<WeightData> _weightData = [];
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
      // Untuk mode admin, childId sudah diberikan. Untuk mode ibu, kita harus mencari tahu.
      // Asumsi saat ini childId selalu diberikan via widget constructor.
      final childId = widget.childId;

      if (motherId == null || childId == null) {
        throw Exception("ID Ibu atau Anak tidak ditemukan.");
      }
      _resolvedMotherId = motherId;
      _resolvedChildId = childId;

      final data = await _childRepo.getWeightRecords(motherId, childId);
      data.sort((a, b) => a.measurementDate.compareTo(b.measurementDate));
      if (mounted) {
        setState(() {
          _weightData = data;
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

  Future<void> _showAddWeightEntryDialog() async {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    double? weight;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Data Berat Badan'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Berat Badan (kg)',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mohon masukkan berat badan';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Format tidak valid';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        weight = double.tryParse(value!);
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
                      if (weight != null) {
                        try {
                          final newRecord = WeightData(
                            weightKg: weight!,
                            measurementDate: selectedDate,
                          );
                          await _childRepo.addWeightRecord(
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
        title: Text('Rekap Berat: ${widget.childName}'),
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
              : _weightData.isEmpty
                  ? Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Belum ada data berat badan.'),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Input Data Pertama"),
                          onPressed: _showAddWeightEntryDialog,
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
      floatingActionButton: _weightData.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddWeightEntryDialog,
              tooltip: 'Tambah Data',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildChartCard() {
    final spots = _weightData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weightKg);
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Grafik Pertumbuhan Berat Badan",
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
                      color: Theme.of(context).primaryColor,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
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
            DataColumn(label: Text('Berat (kg)')),
            DataColumn(label: Text('Usia Saat Ukur')),
          ],
          rows: _weightData.map((data) {
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
              DataCell(Text(data.weightKg.toStringAsFixed(1))),
              DataCell(Text(age)),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}