import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/config/goong_config.dart';
import '../../../data/datasources/location/goong_location_data_source.dart';
import '../../../domain/entities/location/geocoded_address.dart';

final goongDioProvider = Provider<Dio>((ref) {
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

final goongLocationDataSourceProvider = Provider<GoongLocationDataSource>((
  ref,
) {
  return GoongLocationDataSource(ref.watch(goongDioProvider));
});

/// Giữ lại provider này vì PropertyLocationPickerScreen cũ
/// vẫn có thể đang sử dụng nó.
final reverseGeocodeProvider = FutureProvider.autoDispose
    .family<GeocodedAddress, LocationCoordinates>((ref, coordinates) async {
      if (!GoongConfig.hasApiKey) {
        throw StateError('Chưa cấu hình GOONG_API_KEY.');
      }

      debugPrint(
        'REVERSE GEOCODE: '
        '${coordinates.latitude}, ${coordinates.longitude}',
      );

      return ref
          .read(goongLocationDataSourceProvider)
          .reverseGeocode(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
          );
    });

/// Fallback nếu sau này muốn có nút "Tìm" khi user không chọn suggestion.
/// Không dùng provider này tự động sau mỗi lần user ngừng gõ.
final forwardGeocodeProvider = FutureProvider.autoDispose
    .family<GeocodedLocation, String>((ref, rawAddress) async {
      if (!GoongConfig.hasApiKey) {
        throw StateError('Chưa cấu hình GOONG_API_KEY.');
      }

      return ref
          .read(goongLocationDataSourceProvider)
          .forwardGeocode(address: rawAddress);
    });
