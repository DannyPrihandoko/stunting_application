// lib/models/child_repository.dart
import 'package:firebase_database/firebase_database.dart';
import 'mother_profile_repository.dart';

class ChildData {
  final String? id;
  final String name;
  final DateTime? birthDate;
  /// 'L' = Laki-laki, 'P' = Perempuan
  final String sex;
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
          : null,
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
      'sex': sex, // 'L' atau 'P'
      if (includeCreatedAt) 'createdAt': now,
      'updatedAt': now,
    };
  }

  ChildData copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    String? sex,
    int? createdAt,
    int? updatedAt,
  }) {
    return ChildData(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ChildRepository {
  ChildRepository({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;
  final _motherRepo = MotherProfileRepository();

  DatabaseReference _childrenRef(String motherId) =>
      _db.ref().child('mothers').child(motherId).child('children');

  Future<String?> getCurrentMotherId() => _motherRepo.getCurrentId();

  Future<String> createForMother(String motherId, ChildData child) async {
    final ref = _childrenRef(motherId).push();
    await ref.set(child.toMap(includeCreatedAt: true));
    return ref.key!;
  }

  Future<void> updateForMother(
      String motherId, String childId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    if (updates.containsKey('name')) {
      updates['name_lower'] = (updates['name'] as String).toLowerCase().trim();
    }
    await _childrenRef(motherId).child(childId).update(updates);
  }

  Future<void> deleteForMother(String motherId, String childId) async {
    await _childrenRef(motherId).child(childId).remove();
  }

  /// Stream daftar anak untuk ibu tertentu
  Stream<List<ChildData>> streamForMother(String motherId) {
    return _childrenRef(motherId).onValue.map((evt) {
      final snap = evt.snapshot;
      if (!snap.exists || snap.value == null) return <ChildData>[];
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      final list = map.entries
          .where((e) => e.value is Map)
          .map((e) => ChildData.fromMap(e.key.toString(),
              Map<dynamic, dynamic>.from(e.value as Map)))
          .toList();
      // Sort terbaru di atas
      list.sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
      return list;
    });
  }
}
