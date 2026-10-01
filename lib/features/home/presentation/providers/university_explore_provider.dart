import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/goong_config.dart';
import '../../data/university_location_data_source.dart';
import '../../domain/university_item.dart';

class UniversitySearchTarget {
  const UniversitySearchTarget({
    required this.university,
    required this.latitude,
    required this.longitude,
  });

  final UniversityItem university;
  final double latitude;
  final double longitude;
}

final universityGoongDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://rsapi.goong.io',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      queryParameters: {'api_key': GoongConfig.apiKey},
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final universityLocationDataSourceProvider = Provider(
  (ref) => UniversityLocationDataSource(ref.watch(universityGoongDioProvider)),
);

final universityExploreProvider =
    AsyncNotifierProvider<UniversityExploreController, UniversitySearchTarget?>(
      UniversityExploreController.new,
    );

class UniversityExploreController
    extends AsyncNotifier<UniversitySearchTarget?> {
  String? resolvingUniversityId;

  @override
  Future<UniversitySearchTarget?> build() async => null;

  Future<UniversitySearchTarget?> resolve(UniversityItem university) async {
    if (state.isLoading) return null;
    if (!GoongConfig.hasApiKey) {
      state = AsyncError(
        StateError('Chưa cấu hình GOONG_API_KEY.'),
        StackTrace.current,
      );
      return null;
    }

    resolvingUniversityId = university.id;
    state = const AsyncLoading();
    try {
      final location = await ref
          .read(universityLocationDataSourceProvider)
          .resolve(university.searchQuery);
      final target = UniversitySearchTarget(
        university: university,
        latitude: location.latitude,
        longitude: location.longitude,
      );
      resolvingUniversityId = null;
      state = AsyncData(target);
      return target;
    } catch (error, stackTrace) {
      resolvingUniversityId = null;
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  void clear() => state = const AsyncData(null);
}
