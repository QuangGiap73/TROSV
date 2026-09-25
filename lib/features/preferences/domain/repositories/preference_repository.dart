import '../entities/amenity.dart';
import '../entities/tenant_preference.dart';

abstract interface class PreferenceRepository {
  Future<TenantPreference?> getMyPreference();

  Future<TenantPreference> saveMyPreference(TenantPreference preference);

  Future<List<Amenity>> getAmenities();
}

class PreferenceFailure implements Exception {
  const PreferenceFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
