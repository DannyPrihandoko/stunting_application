// lib/providers/gizi_status_provider.dart
import 'package:flutter/material.dart';
import 'package:stunting_application/models/child_repository.dart';
import 'package:stunting_application/models/mother_profile_repository.dart';
import 'package:stunting_application/models/who_anthro_mock.dart';
import 'package:firebase_database/firebase_database.dart';

class GiziStatusNotifier extends ChangeNotifier {
  final _motherRepo = MotherProfileRepository();
  final _childRepo = ChildRepository();
  final DatabaseReference _dbRefGiziHistory =
      FirebaseDatabase.instance.ref("gizi_wfh_history");

  bool _loading = true;
  bool get loading => _loading;

  bool _saving = false;
  bool get saving => _saving;

  String? _motherId;
  List<ChildData> _children = [];
  List<ChildData> get children => _children;

  String? _selectedChildId;
  String? get selectedChildId => _selectedChildId;

  String _giziCategory = '-';
  String get giziCategory => _giziCategory;

  String _zScoreText = '-';
  String get zScoreText => _zScoreText;

  Color _resultColor = Colors.grey;
  Color get resultColor => _resultColor;

  double _score = 0.0;
  double get score => _score;
  
  double? _inputHeight;
  double? _inputWeight;

  GiziStatusNotifier() {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _motherId = await _motherRepo.getCurrentId();
      if (_motherId != null) {
        final snap = await _childRepo.streamForMother(_motherId!).first;
        _children = snap;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  void setSelectedChildId(String? id) {
    _selectedChildId = id;
    notifyListeners();
  }

  ChildData? get selectedChild {
    if (_selectedChildId == null) return null;
    try {
      return _children.firstWhere((c) => c.id == _selectedChildId);
    } catch (e) {
      return null;
    }
  }
  
  void calculateGiziStatus(String height, String weight) {
    if (_selectedChildId == null || selectedChild?.sex.isEmpty == true) {
      // Sebaiknya tampilkan pesan error ke UI
      return;
    }
    final h = double.tryParse(height.replaceAll(',', '.'));
    final w = double.tryParse(weight.replaceAll(',', '.'));

    if (h == null || w == null || h <= 0 || w <= 0) {
      return;
    }
    
    _inputHeight = h;
    _inputWeight = w;

    final sex = selectedChild!.sex;
    final dataMap = WhoAnthroData.getWfhData(h, sex);

    if (dataMap == null) {
      _giziCategory = 'Data SD Tidak Tersedia';
      _zScoreText = '-';
      _resultColor = Colors.blueGrey;
      _score = 0.0;
      notifyListeners();
      return;
    }
    
    final M = dataMap["M"]!;
    final SD_3 = dataMap["-3"]!;
    final SD_2 = dataMap["-2"]!;
    final SD1 = dataMap["+1"]!;
    final SD2 = dataMap["+2"]!;
    final SD3 = dataMap["+3"]!;

    double estimatedZ = 0.0;

    if (w > SD3) {
      estimatedZ = 3.0 + (w - SD3) / (SD3 - SD2);
    } else if (w > SD2) {
      estimatedZ = _interpolate(w, SD2, 2.0, SD3, 3.0);
    } else if (w > SD1) {
      estimatedZ = _interpolate(w, SD1, 1.0, SD2, 2.0);
    } else if (w >= M) {
      estimatedZ = _interpolate(w, M, 0.0, SD1, 1.0);
    } else if (w >= SD_2) {
      estimatedZ = _interpolate(w, SD_2, -2.0, M, 0.0);
    } else if (w >= SD_3) {
      estimatedZ = _interpolate(w, SD_3, -3.0, SD_2, -2.0);
    } else {
      estimatedZ = -3.0 - (SD_3 - w) / (SD_2 - SD_3);
    }

    final result = _getGiziCategory(estimatedZ);
    _score = estimatedZ;
    _giziCategory = result.category;
    _zScoreText = 'Z-Score Est: ${estimatedZ.toStringAsFixed(2)} SD';
    _resultColor = result.color;

    notifyListeners();
  }
  
  Future<bool> saveGiziResult() async {
    if (_giziCategory == '-' || _motherId == null || _selectedChildId == null) {
      return false;
    }

    _saving = true;
    notifyListeners();

    final payload = {
      'timestamp': ServerValue.timestamp,
      'motherId': _motherId,
      'childId': _selectedChildId,
      'childName': selectedChild!.name.isEmpty ? null : selectedChild!.name,
      'childSex': selectedChild!.sex,
      'input': {'heightCm': _inputHeight, 'weightKg': _inputWeight},
      'result': {
        'zScore': double.parse(_score.toStringAsFixed(2)),
        'category': _giziCategory,
        'scoreText': _zScoreText,
      },
      'scoringMethod': 'WFH_Mock_V1',
    };

    try {
      await _dbRefGiziHistory.child(_selectedChildId!).push().set(payload);
      return true;
    } catch (e) {
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
  
  double _interpolate(double x, double x1, double y1, double x2, double y2) {
    if (x1 == x2) return y1;
    return y1 + (x - x1) * (y2 - y1) / (x2 - x1);
  }

  ({String category, Color color}) _getGiziCategory(double z) {
    if (z >= 3) return (category: 'Kategori Obesitas', color: Colors.purple.shade700);
    if (z >= 2) return (category: 'Kategori Gizi Lebih', color: Colors.red.shade700);
    if (z >= 1) return (category: 'Berisiko Gizi Lebih', color: Colors.orange.shade700);
    if (z >= -2) return (category: 'Gizi Baik / Normal', color: Colors.green.shade700);
    if (z >= -3) return (category: 'Gizi Kurang', color: Colors.amber.shade700);
    return (category: 'Gizi Buruk', color: Colors.red.shade900);
  }
}