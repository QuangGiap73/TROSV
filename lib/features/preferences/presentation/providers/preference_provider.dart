import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/preference_remote_data_source.dart';
import '../../data/datasources/university_local_data_source.dart';
import '../../data/repositories/preference_repository_impl.dart';
import '../../domain/entities/amenity.dart';
import '../../domain/entities/tenant_preference.dart';
import '../../domain/entities/university_location.dart';
import '../../domain/repositories/preference_repository.dart';

final preferenceRemoteDataSourceProvider = Provider<PreferenceRemoteDataSource>(
  (ref) {
    return PreferenceRemoteDataSource(ref.watch(dioProvider));
  },
);

final preferenceRepositoryProvider = Provider<PreferenceRepository>((ref) {
  return PreferenceRepositoryImpl(
    ref.watch(preferenceRemoteDataSourceProvider),
  );
});

final amenitiesProvider = FutureProvider<List<Amenity>>((ref) {
  return ref.watch(preferenceRepositoryProvider).getAmenities();
});

final universitiesProvider = FutureProvider<List<UniversityLocation>>((ref) {
  return const UniversityLocalDataSource().getUniversities();
});

final tenantPreferenceProvider =
    AsyncNotifierProvider<TenantPreferenceController, TenantPreference?>(
      TenantPreferenceController.new,
    );

class TenantPreferenceController extends AsyncNotifier<TenantPreference?> {
  PreferenceRepository get _repository =>
      ref.read(preferenceRepositoryProvider);

  @override
  Future<TenantPreference?> build() {
    return _repository.getMyPreference();
  }

  Future<bool> save(TenantPreference preference) async {
    state = const AsyncLoading();

    try {
      final saved = await _repository.saveMyPreference(preference);
      state = AsyncData(saved);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError<TenantPreference?>(error, stackTrace);

      return false;
    }
  }
}
