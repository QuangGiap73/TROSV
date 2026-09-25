import 'package:dio/dio.dart';

import '../../domain/entities/amenity.dart';
import '../../domain/entities/tenant_preference.dart';
import '../../domain/repositories/preference_repository.dart';
import '../datasources/preference_remote_data_source.dart';

class PreferenceRepositoryImpl implements PreferenceRepository {
  const PreferenceRepositoryImpl(this._remote);

  final PreferenceRemoteDataSource _remote;

  @override
  Future<TenantPreference?> getMyPreference() {
    return _execute(_remote.getMyPreference);
  }

  @override
  Future<TenantPreference> saveMyPreference(TenantPreference preference) {
    return _execute(() => _remote.saveMyPreference(preference));
  }

  @override
  Future<List<Amenity>> getAmenities() {
    return _execute(_remote.getAmenities);
  }

  Future<T> _execute<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw PreferenceFailure(_errorMessage(error));
    } on FormatException catch (error) {
      throw PreferenceFailure(error.message);
    }
  }

  String _errorMessage(DioException error) {
    final body = error.response?.data;

    if (body is Map<String, dynamic>) {
      final apiError = body['error'];

      if (apiError is Map<String, dynamic> && apiError['message'] is String) {
        return apiError['message'] as String;
      }

      if (body['detail'] is String) {
        return body['detail'] as String;
      }
    }

    if (error.response?.statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Kết nối quá thời gian. Vui lòng thử lại.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối tới máy chủ.';
    }

    return 'Không thể xử lý nhu cầu tìm trọ.';
  }
}
