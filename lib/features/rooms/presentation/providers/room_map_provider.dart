import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../domain/entities/room_search_query.dart';

class RoomMapState {
  const RoomMapState({
    required this.query,
    this.pendingCenter,
    this.pendingZoom = 13,
    this.canSearchThisArea = false,
  });

  final RoomSearchQuery query;

  /// Tâm camera sau lần lia gần nhất, chưa gửi lên API.
  final LatLng? pendingCenter;
  final double pendingZoom;

  /// Hiện nút “Tìm khu vực này”.
  final bool canSearchThisArea;

  RoomMapState copyWith({
    RoomSearchQuery? query,
    LatLng? pendingCenter,
    double? pendingZoom,
    bool? canSearchThisArea,
  }) {
    return RoomMapState(
      query: query ?? this.query,
      pendingCenter: pendingCenter ?? this.pendingCenter,
      pendingZoom: pendingZoom ?? this.pendingZoom,
      canSearchThisArea: canSearchThisArea ?? this.canSearchThisArea,
    );
  }
}

final roomMapControllerProvider =
    NotifierProvider.autoDispose<RoomMapController, RoomMapState>(
      RoomMapController.new,
    );

class RoomMapController extends Notifier<RoomMapState> {
  @override
  RoomMapState build() {
    return const RoomMapState(
      query: RoomSearchQuery(sort: 'RELEVANCE', page: 1, limit: 50),
    );
  }

  /// Chỉ chạy khi camera ngừng chuyển động.
  /// Chưa gọi API ở bước này.
  void stageViewport({required LatLng center, required double zoom}) {
    final currentLat = state.query.latitude;
    final currentLng = state.query.longitude;

    final movedEnough =
        currentLat == null ||
        currentLng == null ||
        (center.latitude - currentLat).abs() > 0.001 ||
        (center.longitude - currentLng).abs() > 0.001;

    if (!movedEnough) return;

    state = state.copyWith(
      pendingCenter: center,
      pendingZoom: zoom,
      canSearchThisArea: true,
    );
  }

  /// Chỉ hàm này mới thay query và khiến API được gọi lại.
  void searchThisArea() {
    final center = state.pendingCenter;
    if (center == null) return;

    state = state.copyWith(
      query: state.query.copyWith(
        latitude: _normalize(center.latitude),
        longitude: _normalize(center.longitude),
        radiusMeters: _radiusFromZoom(state.pendingZoom),
        sort: 'DISTANCE',
        page: 1,
        limit: 50,
      ),
      canSearchThisArea: false,
    );
  }

  void initialize(RoomSearchQuery query) {
    state = state.copyWith(
      query: query.copyWith(
        latitude: query.latitude ?? state.query.latitude,
        longitude: query.longitude ?? state.query.longitude,
        sort: 'DISTANCE',
        page: 1,
        limit: 50,
        radiusMeters: query.radiusMeters ?? state.query.radiusMeters,
      ),
      canSearchThisArea: false,
    );
  }

  void updateFilters(RoomSearchQuery filteredQuery) {
    state = state.copyWith(
      query: filteredQuery.copyWith(
        latitude: state.query.latitude,
        longitude: state.query.longitude,
        radiusMeters: state.query.radiusMeters,
        sort: 'DISTANCE',
        page: 1,
        limit: 50,
      ),
      canSearchThisArea: false,
    );
  }

  void useCurrentLocation(LatLng location) {
    state = state.copyWith(
      pendingCenter: location,
      pendingZoom: 15,
      canSearchThisArea: false,
      query: state.query.copyWith(
        latitude: _normalize(location.latitude),
        longitude: _normalize(location.longitude),
        radiusMeters: 3000,
        sort: 'DISTANCE',
        page: 1,
        limit: 50,
      ),
    );
  }

  void searchLocation(LatLng location) {
    state = state.copyWith(
      pendingCenter: location,
      pendingZoom: 14,
      canSearchThisArea: false,
      query: state.query.copyWith(
        latitude: _normalize(location.latitude),
        longitude: _normalize(location.longitude),
        radiusMeters: 5000,
        sort: 'DISTANCE',
        page: 1,
        limit: 50,
      ),
    );
  }

  void expandRadius() {
    final current = state.query.radiusMeters ?? 3000;
    final next = switch (current) {
      < 5000 => 5000,
      < 10000 => 10000,
      _ => 20000,
    };
    state = state.copyWith(
      query: state.query.copyWith(radiusMeters: next, page: 1, limit: 50),
      canSearchThisArea: false,
    );
  }

  static double _normalize(double value) {
    return double.parse(value.toStringAsFixed(4));
  }

  static int _radiusFromZoom(double zoom) {
    if (zoom >= 16) return 1000;
    if (zoom >= 14) return 3000;
    if (zoom >= 12) return 5000;
    return 10000;
  }
}
