import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/university_location.dart';

class UniversityLocalDataSource {
  const UniversityLocalDataSource();

  Future<List<UniversityLocation>> getUniversities() async {
    final jsonText = await rootBundle.loadString(
      'assets/data/universities.json',
    );
    final decoded = jsonDecode(jsonText);
    if (decoded is! List) {
      throw const FormatException('Danh sách trường không hợp lệ.');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(UniversityLocation.fromJson)
        .toList(growable: false);
  }
}
