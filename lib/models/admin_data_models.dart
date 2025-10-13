// lib/models/admin_data_models.dart

import 'package:stunting_application/models/child_repository.dart';
import 'package:stunting_application/models/mother_profile_repository.dart';

/// Model gabungan untuk menampilkan data ibu beserta anak-anaknya di halaman admin.
class MotherWithChildren {
  final MotherProfile mother;
  final List<ChildData> children;

  const MotherWithChildren({
    required this.mother,
    required this.children,
  });
}