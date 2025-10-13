// lib/models/child_repository.dart
import 'package:firebase_database/firebase_database.dart';
import 'mother_profile_repository.dart';

// Model untuk data berat badan
class WeightData {
  final String? id;
  final double weightKg;
  final DateTime measurementDate;

  WeightData({this.id, required this.weightKg, required this.measurementDate});

  factory WeightData.fromMap(String id, Map<dynamic, dynamic> data) {
    return WeightData(
      id: id,
      weightKg: (data['weightKg'] as num).toDouble(),
      measurementDate:
          DateTime.fromMillisecondsSinceEpoch(data['measurementDateMs'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weightKg': weightKg,
      'measurementDateMs': measurementDate.millisecondsSinceEpoch,
    };
  }
}

// Model untuk data tinggi badan
class HeightData {
  final String? id;
  final double heightCm;
  final DateTime measurementDate;

  HeightData({this.id, required this.heightCm, required this.measurementDate});

  factory HeightData.fromMap(String id, Map<dynamic, dynamic> data) {
    return HeightData(
      id: id,
      heightCm: (data['heightCm'] as num).toDouble(),
      measurementDate:
          DateTime.fromMillisecondsSinceEpoch(data['measurementDateMs'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'heightCm': heightCm,
      'measurementDateMs': measurementDate.millisecondsSinceEpoch,
    };
  }
}

// Model utama untuk data anak
class ChildData {
  final String? id;
  final String name;
  final DateTime? birthDate;
  final String sex; // 'L' atau 'P'
  final int? createdAt;
  final int? updatedAt;

  const ChildData({
    this.id,
    required this.name,
    required this.birthDate,
    required this.sex,
    this.createdAt,
    this.updatedAt,
  });

  factory ChildData.fromMap(String id, Map<dynamic, dynamic> m) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse('$v');
    }

    return ChildData(
      id: id,
      name: (m['name'] ?? '').toString(),
      birthDate: m['birthDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(asInt(m['birthDate']) ?? 0)
          : (m['birthDateMs'] != null ? DateTime.fromMillisecondsSinceEpoch(asInt(m['birthDateMs']) ?? 0) : null),
      sex: (m['sex'] ?? '').toString(),
      createdAt: asInt(m['createdAt']),
      updatedAt: asInt(m['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool includeCreatedAt = false}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'name': name,
      'name_lower': name.toLowerCase().trim(),
      'birthDate': birthDate?.millisecondsSinceEpoch,
      'sex': sex,
      if (includeCreatedAt) 'createdAt': now,
      'updatedAt': now,
    };
  }
}

// Repository untuk mengelola data anak
class ChildRepository {
  ChildRepository({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;
  final _motherRepo = MotherProfileRepository();

  DatabaseReference _childrenRef(String motherId, [String? childId]) {
    var ref = _db.ref().child('mothers').child(motherId).child('children');
    if (childId != null) {
      ref = ref.child(childId);
    }
    return ref;
  }

  Future<String?> getCurrentMotherId() => _motherRepo.getCurrentId();

  // --- Metode yang dibutuhkan oleh data_anak_page.dart ---

  Future<String> createForMother(String motherId, ChildData child) async {
    final ref = _childrenRef(motherId).push();
    await ref.set(child.toMap(includeCreatedAt: true));
    return ref.key!;
  }

  Future<void> deleteForMother(String motherId, String childId) async {
    await _childrenRef(motherId, childId).remove();
  }

  Stream<List<ChildData>> streamForMother(String motherId) {
    return _childrenRef(motherId).onValue.map((evt) {
      final snap = evt.snapshot;
      if (!snap.exists || snap.value == null) return <ChildData>[];
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      final list = map.entries
          .where((e) => e.value is Map)
          .map((e) => ChildData.fromMap(e.key.toString(),
              Map<String, dynamic>.from(e.value as Map)))
          .toList();
      list.sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
      return list;
    });
  }

  // --- Metode tambahan untuk rekap berat & tinggi ---

  Future<List<WeightData>> getWeightRecords(
      String motherId, String childId) async {
    final ref = _childrenRef(motherId, childId).child('weight_records');
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.entries
        .map((e) => WeightData.fromMap(e.key, Map<String, dynamic>.from(e.value)))
        .toList();
  }

  Future<void> addWeightRecord(
      String motherId, String childId, WeightData record) async {
    final ref = _childrenRef(motherId, childId).child('weight_records').push();
    await ref.set(record.toMap());
  }

  Future<List<HeightData>> getHeightRecords(
      String motherId, String childId) async {
    final ref = _childrenRef(motherId, childId).child('height_records');
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.entries
        .map((e) => HeightData.fromMap(e.key, Map<String, dynamic>.from(e.value)))
        .toList();
  }

  Future<void> addHeightRecord(
      String motherId, String childId, HeightData record) async {
    final ref = _childrenRef(motherId, childId).child('height_records').push();
    await ref.set(record.toMap());
  }
}