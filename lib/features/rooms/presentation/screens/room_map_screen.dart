import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../core/config/goong_config.dart';
import '../../../../core/location/location_failure.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../preferences/domain/entities/amenity.dart';
import '../../../preferences/presentation/providers/preference_provider.dart';
import '../../../landlord/rooms/presentation/create_room/providers/property_location_provider.dart';
import '../../../landlord/rooms/domain/entities/location/geocoded_address.dart';
import '../../domain/entities/room_search_query.dart';
import '../../domain/entities/room_map_args.dart';
import '../../domain/entities/room_summary.dart';
import '../providers/room_providers.dart';
import '../providers/room_map_provider.dart';

const _hanoiFallbackLocation = LatLng(21.0285, 105.8542);

class RoomMapScreen extends ConsumerStatefulWidget {
  const RoomMapScreen({this.initialQuery, this.initialFocusLabel, super.key});

  final RoomSearchQuery? initialQuery;
  final String? initialFocusLabel;

  @override
  ConsumerState<RoomMapScreen> createState() => _RoomMapScreenState();
}

class _RoomMapScreenState extends ConsumerState<RoomMapScreen> {
  MapLibreMapController? _mapController;
  final Map<String, RoomSummary> _roomBySymbolId = {};
  final Map<String, Symbol> _symbolByRoomId = {};
  final Map<String, _RoomMarkerGroup> _clusterBySymbolId = {};
  bool _styleLoaded = false;
  RoomSummary? _selectedRoom;
  LatLng? _currentLocation;
  Symbol? _userLocationSymbol;
  bool _locating = false;
  bool _locationExplained = false;
  bool _mapStateReady = false;
  bool _awaitingInitialLocation = false;

  List<RoomSummary>? _pendingMarkerRooms;
  List<RoomSummary> _latestMarkerRooms = const [];
  bool _renderingMarkers = false;
  String _renderSignature = '';
  int _selectionRevision = 0;
  final Set<String> _registeredMarkerImages = {};
  LatLng? _focusLocation;
  String? _focusLabel;
  LatLng? _pendingCameraLocation;
  double _pendingCameraZoom = 14;
  bool _pendingCameraAnimated = false;

  @override
  void initState() {
    super.initState();

    final query = widget.initialQuery;
    _focusLabel = widget.initialFocusLabel;
    if (_focusLabel != null &&
        query?.latitude != null &&
        query?.longitude != null) {
      _focusLocation = LatLng(query!.latitude!, query.longitude!);
    }
    final initialMapQuery = _focusLocation == null
        ? query ?? const RoomSearchQuery()
        : query!.copyWith(
            radiusMeters: 3000,
            sort: 'DISTANCE',
            page: 1,
            limit: 50,
          );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _initializeStartingPosition(initialMapQuery);
    });
  }

  Future<void> _initializeStartingPosition(RoomSearchQuery query) async {
    final controller = ref.read(roomMapControllerProvider.notifier);

    if (query.latitude != null && query.longitude != null) {
      controller.initialize(query);
      if (mounted) setState(() => _mapStateReady = true);
      return;
    }

    // Lưu các bộ lọc trước, nhưng chưa dựng map/call API cho tới khi GPS xong.
    controller.initialize(query);
    controller.searchLocation(_hanoiFallbackLocation);
    setState(() {
      _awaitingInitialLocation = true;
      _mapStateReady = true;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final accepted = await _confirmLocationUse();
    if (!mounted) return;

    if (accepted) {
      setState(() => _awaitingInitialLocation = false);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      // Dùng chính xác cùng handler với nút định vị xanh.
      await _goToCurrentLocation(skipPermissionExplanation: true);
      return;
    }

    if (mounted && _awaitingInitialLocation) {
      setState(() => _awaitingInitialLocation = false);
    }
  }

  Future<bool> _confirmLocationUse() async {
    if (_locationExplained) return true;

    // Quyền do hệ điều hành quản lý được giữ lại giữa các lần mở ứng dụng.
    // Nếu người dùng đã cấp quyền, bỏ qua màn giải thích và lấy GPS ngay.
    final status = await ref.read(locationServiceProvider).getStatus();
    if (!mounted) return false;
    if (status.permissionGranted) {
      _locationExplained = true;
      return true;
    }

    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (sheetContext) => _LocationPermissionCard(
        onLater: () => Navigator.pop(sheetContext, false),
        onAllow: () => Navigator.pop(sheetContext, true),
      ),
    );
    if (accepted == true) _locationExplained = true;
    return accepted == true;
  }

  @override
  Widget build(BuildContext context) {
    if (!GoongConfig.hasMaptilesKey) return const _MissingMapKeyScreen();
    if (!_mapStateReady) return const _MapInitializingScreen();

    final mapState = ref.watch(roomMapControllerProvider);
    ref.listen<RoomMapState>(roomMapControllerProvider, (previous, next) {
      final previousLat = previous?.query.latitude;
      final previousLng = previous?.query.longitude;
      final nextLat = next.query.latitude;
      final nextLng = next.query.longitude;
      if (nextLat == null || nextLng == null) return;
      if (previousLat == nextLat && previousLng == nextLng) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          _moveCameraTo(
            LatLng(nextLat, nextLng),
            zoom: _focusLocation != null ? 14 : next.pendingZoom,
            animated: true,
          ),
        );
      });
    });
    final AsyncValue<List<RoomSummary>> rooms = _awaitingInitialLocation
        ? const AsyncLoading<List<RoomSummary>>()
        : ref.watch(roomSearchProvider(mapState.query));
    final mappableRooms =
        rooms.asData?.value.where(_hasCoordinates).take(50).toList() ??
        const <RoomSummary>[];

    _scheduleMarkerRender(mappableRooms);

    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            child: MapLibreMap(
              styleString: GoongConfig.mapStyleUrl,
              initialCameraPosition: CameraPosition(
                target: _initialCameraTarget(mapState),
                zoom: _focusLocation != null
                    ? 14
                    : mapState.query.latitude != null &&
                          mapState.query.longitude != null
                    ? 13
                    : 5.5,
              ),
              compassEnabled: false,
              logoEnabled: false,
              attributionButtonPosition: null,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: false,
              trackCameraPosition: true,
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
              onCameraIdle: _onCameraIdle,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 12,
            right: 12,
            child: _MapSearchBar(
              label: _focusLabel,
              onBack: _returnToList,
              onSearch: _openLocationSearch,
              onFilter: _openFilters,
            ),
          ),
          if (mapState.canSearchThisArea)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 72,
              left: 0,
              right: 0,
              child: Center(
                child: _SearchThisAreaButton(
                  onTap: () => ref
                      .read(roomMapControllerProvider.notifier)
                      .searchThisArea(),
                ),
              ),
            ),
          if (rooms.isLoading && !_awaitingInitialLocation)
            const Positioned.fill(child: _MapLoadingOverlay()),
          if (rooms.hasError)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 124,
              left: 16,
              right: 16,
              child: _MapErrorBanner(
                onRetry: () =>
                    ref.invalidate(roomSearchProvider(mapState.query)),
              ),
            ),
          if (!_awaitingInitialLocation &&
              rooms.asData != null &&
              mappableRooms.isEmpty)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 94,
              left: 24,
              right: 24,
              bottom: MediaQuery.paddingOf(context).bottom + 82,
              child: _EmptyMapResults(
                radiusMeters: mapState.query.radiusMeters ?? 3000,
                onExpandRadius: () =>
                    ref.read(roomMapControllerProvider.notifier).expandRadius(),
              ),
            ),
          if (_selectedRoom case final room?)
            Positioned(
              left: 14,
              right: 14,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: _RoomMapPreview(
                room: room,
                distanceLabel: _distanceLabel(room),
                onClose: _clearRoomSelection,
                onTap: () => context.push('/rooms/${room.id}'),
              ),
            )
          else
            Positioned(
              left: 24,
              right: 24,
              bottom: MediaQuery.paddingOf(context).bottom + 18,
              child: _ShowListButton(
                count: mappableRooms.length,
                onTap: _returnToList,
              ),
            ),
          Positioned(
            right: 16,
            bottom:
                MediaQuery.paddingOf(context).bottom +
                (_selectedRoom == null ? 84 : 146),
            child: _LocationButton(
              loading: _locating,
              onTap: _locating ? null : _goToCurrentLocation,
            ),
          ),
        ],
      ),
    );
  }

  LatLng _initialCameraTarget(RoomMapState mapState) {
    if (_focusLocation case final schoolLocation?) return schoolLocation;

    final latitude = mapState.query.latitude;
    final longitude = mapState.query.longitude;
    if (latitude != null && longitude != null) {
      return LatLng(latitude, longitude);
    }

    return _hanoiFallbackLocation;
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    controller.onSymbolTapped.add(_onSymbolTapped);
    unawaited(_syncCameraWithSelectedLocation());
  }

  Future<void> _syncCameraWithSelectedLocation() async {
    final mapState = ref.read(roomMapControllerProvider);
    final latitude = mapState.query.latitude;
    final longitude = mapState.query.longitude;
    if (latitude == null || longitude == null) return;

    await _moveCameraTo(
      LatLng(latitude, longitude),
      zoom: _focusLocation != null ? 14 : mapState.pendingZoom,
      animated: false,
    );
  }

  Future<void> _moveCameraTo(
    LatLng location, {
    required double zoom,
    required bool animated,
  }) async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) {
      _pendingCameraLocation = location;
      _pendingCameraZoom = zoom;
      _pendingCameraAnimated = animated;
      return;
    }
    final update = CameraUpdate.newCameraPosition(
      CameraPosition(target: location, zoom: zoom),
    );
    if (animated) {
      await controller.animateCamera(update);
    } else {
      await controller.moveCamera(update);
    }
  }

  Future<void> _onStyleLoaded() async {
    final controller = _mapController;
    if (controller == null) return;
    // Room markers are clustered before rendering. Allowing overlap here keeps
    // the university marker visible even when it is close to a room cluster.
    await controller.setSymbolIconAllowOverlap(true);
    _registeredMarkerImages.clear();
    _userLocationSymbol = null;
    _styleLoaded = true;
    final pendingLocation = _pendingCameraLocation;
    if (pendingLocation != null) {
      final pendingZoom = _pendingCameraZoom;
      final pendingAnimated = _pendingCameraAnimated;
      _pendingCameraLocation = null;
      await _moveCameraTo(
        pendingLocation,
        zoom: pendingZoom,
        animated: pendingAnimated,
      );
    } else {
      await _syncCameraWithSelectedLocation();
    }
    if (_currentLocation != null) await _drawUserLocation();
    final query = ref.read(roomMapControllerProvider).query;
    final items =
        ref
            .read(roomSearchProvider(query))
            .asData
            ?.value
            .where(_hasCoordinates)
            .take(50)
            .toList() ??
        const <RoomSummary>[];
    _scheduleMarkerRender(items);
  }

  void _onCameraIdle() {
    final camera = _mapController?.cameraPosition;
    if (camera == null) return;
    _renderSignature = '';
    _scheduleMarkerRender(_latestMarkerRooms);
    ref
        .read(roomMapControllerProvider.notifier)
        .stageViewport(center: camera.target, zoom: camera.zoom);
  }

  void _returnToList() {
    final query = ref.read(roomMapControllerProvider).query;
    final result = RoomMapArgs(query: query, focusLabel: _focusLabel);
    if (context.canPop()) {
      context.pop(result);
      return;
    }
    context.go('/search');
  }

  Future<void> _openFilters() async {
    final current = ref.read(roomMapControllerProvider).query;
    final amenities =
        ref.read(amenitiesProvider).asData?.value ?? const <Amenity>[];
    final result = await showModalBottomSheet<RoomSearchQuery>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapFilterSheet(query: current, amenities: amenities),
    );
    if (!mounted || result == null) return;
    ref.read(roomMapControllerProvider.notifier).updateFilters(result);
  }

  Future<void> _openLocationSearch() async {
    final result = await showModalBottomSheet<_MapPlaceResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MapPlaceSearchSheet(),
    );
    if (!mounted || result == null) return;

    setState(() {
      _focusLabel = result.label;
      _focusLocation = result.location;
      _renderSignature = '';
    });
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: result.location, zoom: 14),
      ),
    );
    ref
        .read(roomMapControllerProvider.notifier)
        .searchLocation(result.location);
  }

  Future<void> _goToCurrentLocation({
    bool skipPermissionExplanation = false,
  }) async {
    final accepted = skipPermissionExplanation || await _confirmLocationUse();
    if (!accepted || !mounted) return;

    setState(() => _locating = true);
    try {
      final position = await ref
          .read(locationServiceProvider)
          .getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = location;
        _focusLocation = null;
        _focusLabel = null;
      });

      ref.read(roomMapControllerProvider.notifier).useCurrentLocation(location);
      await _moveCameraTo(location, zoom: 15, animated: true);
      if (_styleLoaded) await _drawUserLocation();
    } on LocationFailure catch (failure) {
      if (!mounted) return;
      await _handleLocationFailure(failure);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _handleLocationFailure(LocationFailure failure) async {
    final service = ref.read(locationServiceProvider);

    if (failure.type == LocationFailureType.serviceDisabled) {
      final open = await _showLocationDialog(
        title: 'GPS đang tắt',
        message: failure.message,
        actionLabel: 'Mở cài đặt GPS',
      );
      if (open == true) await service.openLocationSettings();
      return;
    }

    if (failure.type == LocationFailureType.permissionDeniedForever) {
      final open = await _showLocationDialog(
        title: 'Chưa có quyền vị trí',
        message:
            'Bạn đã từ chối quyền vị trí. Hãy mở cài đặt ứng dụng và cho phép '
            'TrọSV sử dụng vị trí khi đang dùng ứng dụng.',
        actionLabel: 'Mở cài đặt ứng dụng',
      );
      if (open == true) await service.openAppSettings();
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }

  Future<bool?> _showLocationDialog({
    required String title,
    required String message,
    required String actionLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _drawUserLocation() async {
    final controller = _mapController;
    final location = _currentLocation;
    if (controller == null || !_styleLoaded || location == null) return;

    const imageName = 'current-location-pin-v1';
    if (!_registeredMarkerImages.contains(imageName)) {
      await controller.addImage(imageName, await _createUserLocationMarker());
      _registeredMarkerImages.add(imageName);
    }

    final previous = _userLocationSymbol;
    if (previous != null) await controller.removeSymbol(previous);
    _userLocationSymbol = await controller.addSymbol(
      SymbolOptions(
        geometry: location,
        iconImage: imageName,
        iconSize: .62,
        iconAnchor: 'bottom',
        zIndex: 20,
      ),
    );
  }

  void _scheduleMarkerRender(List<RoomSummary> rooms) {
    if (!_styleLoaded) return;
    _latestMarkerRooms = List<RoomSummary>.unmodifiable(rooms);
    final signature = _markerSignature(rooms);
    if (signature == _renderSignature) return;

    _pendingMarkerRooms = List<RoomSummary>.unmodifiable(rooms);
    if (_renderingMarkers) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _drainMarkerQueue();
    });
  }

  Future<void> _drainMarkerQueue() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded || _renderingMarkers) return;

    _renderingMarkers = true;
    try {
      while (_pendingMarkerRooms != null) {
        final rooms = _pendingMarkerRooms!;
        _pendingMarkerRooms = null;
        await controller.clearSymbols();
        _userLocationSymbol = null;
        _roomBySymbolId.clear();
        _symbolByRoomId.clear();
        _clusterBySymbolId.clear();

        if (rooms.isNotEmpty) {
          await _ensureMarkerImages(controller, rooms);
          final groups = _clusterRooms(
            rooms,
            controller.cameraPosition?.zoom ?? _pendingCameraZoom,
          );
          await _ensureClusterImages(controller, groups);
          final symbols = await controller.addSymbols(
            groups
                .map(
                  (group) => SymbolOptions(
                    geometry: group.location,
                    iconImage: group.isCluster
                        ? _clusterImageName(group.rooms.length)
                        : _markerImageName(
                            group.rooms.single.priceMonthly,
                            selected:
                                group.rooms.single.id == _selectedRoom?.id,
                          ),
                    iconSize:
                        !group.isCluster &&
                            group.rooms.single.id == _selectedRoom?.id
                        ? .88
                        : .80,
                    iconAnchor: 'bottom',
                    zIndex:
                        !group.isCluster &&
                            group.rooms.single.id == _selectedRoom?.id
                        ? 2
                        : 1,
                  ),
                )
                .toList(growable: false),
          );
          for (var index = 0; index < symbols.length; index++) {
            final group = groups[index];
            if (group.isCluster) {
              _clusterBySymbolId[symbols[index].id] = group;
            } else {
              final room = group.rooms.single;
              _roomBySymbolId[symbols[index].id] = room;
              _symbolByRoomId[room.id] = symbols[index];
            }
          }
        }

        await _drawFocusMarker(controller);
        await _drawUserLocation();
        _renderSignature = _markerSignature(rooms);
      }
    } finally {
      _renderingMarkers = false;
      if (_pendingMarkerRooms != null && mounted) {
        _drainMarkerQueue();
      }
    }
  }

  String _markerSignature(List<RoomSummary> rooms) {
    final zoom = _mapController?.cameraPosition?.zoom ?? _pendingCameraZoom;
    final roomSignature = rooms
        .map(
          (room) =>
              '${room.id}:${room.latitude}:${room.longitude}:${room.priceMonthly}',
        )
        .join('|');
    return '${zoom.toStringAsFixed(2)}:'
        '${_focusLocation?.latitude}:${_focusLocation?.longitude}:'
        '$roomSignature';
  }

  List<_RoomMarkerGroup> _clusterRooms(List<RoomSummary> rooms, double zoom) {
    // At normal/near zoom levels, keep every price marker visible. Clustering
    // starts only after zooming out; truly co-located rooms are always grouped
    // so users can open their room list instead of seeing stacked markers.
    final clusterByViewport = zoom < 13.5;
    final clusterRadiusPixels = zoom < 11
        ? 92.0
        : zoom < 12.5
        ? 74.0
        : 56.0;
    final groups = <_RoomMarkerGroup>[];
    for (final room in rooms) {
      final selected = room.id == _selectedRoom?.id;
      final point = _projectToWorldPixels(
        room.latitude!,
        room.longitude!,
        zoom,
      );
      _RoomMarkerGroup? nearest;
      var nearestDistance = double.infinity;
      if (!selected) {
        for (final group in groups) {
          if (group.containsSelected) continue;
          final pixelDistance = math.sqrt(
            math.pow(point.x - group.worldPoint.x, 2) +
                math.pow(point.y - group.worldPoint.y, 2),
          );
          final center = group.location;
          final locationDistance = _distanceBetweenMeters(
            room.latitude!,
            room.longitude!,
            center.latitude,
            center.longitude,
          );
          final shouldCluster =
              locationDistance <= 15 ||
              (clusterByViewport && pixelDistance <= clusterRadiusPixels);
          if (shouldCluster && pixelDistance < nearestDistance) {
            nearest = group;
            nearestDistance = pixelDistance;
          }
        }
      }
      if (nearest == null) {
        groups.add(
          _RoomMarkerGroup(
            room: room,
            worldPoint: point,
            containsSelected: selected,
          ),
        );
      } else {
        nearest.add(room, point);
      }
    }
    return groups;
  }

  Future<void> _ensureClusterImages(
    MapLibreMapController controller,
    List<_RoomMarkerGroup> groups,
  ) async {
    for (final group in groups.where((item) => item.isCluster)) {
      final count = group.rooms.length;
      final name = _clusterImageName(count);
      if (_registeredMarkerImages.contains(name)) continue;
      await controller.addImage(
        name,
        await _createPriceMarkerImage(const Color(0xFF006F5F), '$count phòng'),
      );
      _registeredMarkerImages.add(name);
    }
  }

  Future<void> _ensureMarkerImages(
    MapLibreMapController controller,
    List<RoomSummary> rooms,
  ) async {
    for (final room in rooms) {
      final selected = room.id == _selectedRoom?.id;
      await _ensureSingleMarkerImage(controller, room, selected: selected);
    }
  }

  Future<void> _ensureSingleMarkerImage(
    MapLibreMapController controller,
    RoomSummary room, {
    required bool selected,
  }) async {
    final name = _markerImageName(room.priceMonthly, selected: selected);
    if (_registeredMarkerImages.contains(name)) return;
    await controller.addImage(
      name,
      await _createPriceMarkerImage(
        selected ? const Color(0xFF006F5F) : const Color(0xFF00A884),
        _shortPrice(room.priceMonthly),
      ),
    );
    _registeredMarkerImages.add(name);
  }

  Future<void> _drawFocusMarker(MapLibreMapController controller) async {
    final location = _focusLocation;
    if (location == null) return;
    final label = _focusLabel?.trim().isNotEmpty == true
        ? _focusLabel!.trim()
        : 'Khu vực đang tìm';
    final imageName = 'map-focus-v2-${label.hashCode}';
    if (!_registeredMarkerImages.contains(imageName)) {
      await controller.addImage(
        imageName,
        await _createSchoolMarkerImage(label),
      );
      _registeredMarkerImages.add(imageName);
    }
    await controller.addSymbol(
      SymbolOptions(
        geometry: location,
        iconImage: imageName,
        iconSize: .76,
        iconAnchor: 'bottom',
        zIndex: 10,
      ),
    );
  }

  void _onSymbolTapped(Symbol symbol) {
    final cluster = _clusterBySymbolId[symbol.id];
    if (cluster != null) {
      final currentZoom = _mapController?.cameraPosition?.zoom ?? 12;
      if (cluster.maxDistanceMeters <= 15 || currentZoom >= 18) {
        unawaited(_showClusterRooms(cluster));
        return;
      }
      unawaited(
        _moveCameraTo(
          cluster.location,
          zoom: math.min(currentZoom + 2, 19),
          animated: true,
        ),
      );
      return;
    }
    final room = _roomBySymbolId[symbol.id];
    if (room == null || !mounted) return;
    _selectRoom(room);
  }

  void _selectRoom(RoomSummary room) {
    final previous = _selectedRoom;
    if (previous?.id == room.id) {
      if (mounted) setState(() {});
      return;
    }
    final revision = ++_selectionRevision;
    setState(() => _selectedRoom = room);
    unawaited(_updateSelectedSymbols(previous, room, revision));
  }

  void _clearRoomSelection() {
    final previous = _selectedRoom;
    if (previous == null) return;
    final revision = ++_selectionRevision;
    setState(() => _selectedRoom = null);
    unawaited(_updateSelectedSymbols(previous, null, revision));
  }

  Future<void> _updateSelectedSymbols(
    RoomSummary? previous,
    RoomSummary? current,
    int revision,
  ) async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;
    try {
      if (current != null) {
        await _ensureSingleMarkerImage(controller, current, selected: true);
      }
      if (revision != _selectionRevision || !mounted) return;

      if (previous != null && previous.id != current?.id) {
        final previousSymbol = _symbolByRoomId[previous.id];
        if (previousSymbol != null) {
          await controller.updateSymbol(
            previousSymbol,
            SymbolOptions(
              iconImage: _markerImageName(
                previous.priceMonthly,
                selected: false,
              ),
              iconSize: .80,
              zIndex: 1,
            ),
          );
        }
      }
      if (revision != _selectionRevision || !mounted || current == null) return;
      final currentSymbol = _symbolByRoomId[current.id];
      if (currentSymbol != null) {
        await controller.updateSymbol(
          currentSymbol,
          SymbolOptions(
            iconImage: _markerImageName(current.priceMonthly, selected: true),
            iconSize: .88,
            zIndex: 2,
          ),
        );
      }
    } catch (_) {
      // A camera/style refresh may replace symbols while an update is pending.
      // The next marker render will apply the current selected state.
    }
  }

  String? _distanceLabel(RoomSummary room) {
    double? meters;
    final current = _currentLocation;
    if (current != null && room.latitude != null && room.longitude != null) {
      meters = _distanceBetweenMeters(
        current.latitude,
        current.longitude,
        room.latitude!,
        room.longitude!,
      );
    } else {
      meters = room.distanceMeters;
      final query = ref.read(roomMapControllerProvider).query;
      if (meters == null &&
          query.latitude != null &&
          query.longitude != null &&
          room.latitude != null &&
          room.longitude != null) {
        meters = _distanceBetweenMeters(
          query.latitude!,
          query.longitude!,
          room.latitude!,
          room.longitude!,
        );
      }
    }
    return meters == null ? null : _formatDistance(meters);
  }

  Future<void> _showClusterRooms(_RoomMarkerGroup cluster) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .72,
        child: Material(
          color: const Color(0xFFF5F9F8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8C6C2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      color: Color(0xFF008E79),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${cluster.rooms.length} phòng tại vị trí này',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: cluster.rooms.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final room = cluster.rooms[index];
                    return _RoomMapPreview(
                      room: room,
                      distanceLabel: _distanceLabel(room),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.push('/rooms/${room.id}');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomMarkerGroup {
  _RoomMarkerGroup({
    required RoomSummary room,
    required this.worldPoint,
    required this.containsSelected,
  }) : rooms = [room],
       _latitudeTotal = room.latitude!,
       _longitudeTotal = room.longitude!;

  final List<RoomSummary> rooms;
  final bool containsSelected;
  math.Point<double> worldPoint;
  double _latitudeTotal;
  double _longitudeTotal;

  bool get isCluster => rooms.length > 1;
  double get maxDistanceMeters {
    if (rooms.length < 2) return 0;
    var maxDistance = 0.0;
    for (var first = 0; first < rooms.length - 1; first++) {
      for (var second = first + 1; second < rooms.length; second++) {
        final distance = _distanceBetweenMeters(
          rooms[first].latitude!,
          rooms[first].longitude!,
          rooms[second].latitude!,
          rooms[second].longitude!,
        );
        if (distance > maxDistance) maxDistance = distance;
      }
    }
    return maxDistance;
  }

  LatLng get location =>
      LatLng(_latitudeTotal / rooms.length, _longitudeTotal / rooms.length);

  void add(RoomSummary room, math.Point<double> point) {
    final previousCount = rooms.length;
    rooms.add(room);
    _latitudeTotal += room.latitude!;
    _longitudeTotal += room.longitude!;
    worldPoint = math.Point<double>(
      (worldPoint.x * previousCount + point.x) / rooms.length,
      (worldPoint.y * previousCount + point.y) / rooms.length,
    );
  }
}

math.Point<double> _projectToWorldPixels(
  double latitude,
  double longitude,
  double zoom,
) {
  final scale = 256.0 * math.pow(2, zoom).toDouble();
  final x = (longitude + 180) / 360 * scale;
  final sinLatitude = math.sin(latitude * math.pi / 180).clamp(-0.9999, 0.9999);
  final y =
      (0.5 - math.log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * math.pi)) *
      scale;
  return math.Point<double>(x, y);
}

double _distanceBetweenMeters(
  double latitudeA,
  double longitudeA,
  double latitudeB,
  double longitudeB,
) {
  const earthRadiusMeters = 6371000.0;
  final latitudeDelta = (latitudeB - latitudeA) * math.pi / 180;
  final longitudeDelta = (longitudeB - longitudeA) * math.pi / 180;
  final latitudeARadians = latitudeA * math.pi / 180;
  final latitudeBRadians = latitudeB * math.pi / 180;
  final haversine =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(latitudeARadians) *
          math.cos(latitudeBRadians) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  return 2 *
      earthRadiusMeters *
      math.asin(math.sqrt(haversine.clamp(0.0, 1.0)));
}

String _formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final kilometers = meters / 1000;
  return '${kilometers.toStringAsFixed(kilometers < 10 ? 1 : 0)} km';
}

String _shortPrice(int price) {
  final millions = price / 1000000;
  final value = millions == millions.roundToDouble()
      ? millions.toStringAsFixed(0)
      : millions.toStringAsFixed(1).replaceAll('.', ',');
  return '${value}tr';
}

String _markerImageName(int price, {required bool selected}) =>
    'room-price-v2-$price-${selected ? 'selected' : 'normal'}';

String _clusterImageName(int count) => 'room-cluster-v1-$count';

Future<Uint8List> _createPriceMarkerImage(Color color, String label) async {
  // Render at twice the previous size so both the price text and its touch
  // target remain crisp instead of scaling up a small bitmap on the map.
  const width = 264.0;
  const height = 160.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = color;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(4, 4, 256, 120),
      const Radius.circular(42),
    ),
    paint,
  );
  final path = Path()
    ..moveTo(108, 122)
    ..lineTo(132, 158)
    ..lineTo(156, 122)
    ..close();
  canvas.drawPath(path, paint);
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 54,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: 248);
  painter.paint(
    canvas,
    Offset((width - painter.width) / 2, 62 - painter.height / 2),
  );
  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<Uint8List> _createSchoolMarkerImage(String label) async {
  const width = 660.0;
  const height = 188.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = const Color(0xFF2478F2);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(4, 4, 652, 136),
      const Radius.circular(48),
    ),
    paint,
  );
  final path = Path()
    ..moveTo(296, 138)
    ..lineTo(330, 186)
    ..lineTo(364, 138)
    ..close();
  canvas.drawPath(path, paint);
  canvas.drawCircle(
    const Offset(76, 72),
    50,
    Paint()..color = const Color(0x33FFFFFF),
  );
  final icon = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(Icons.school_rounded.codePoint),
      style: TextStyle(
        color: Colors.white,
        fontSize: 62,
        fontFamily: Icons.school_rounded.fontFamily,
        package: Icons.school_rounded.fontPackage,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  icon.paint(canvas, Offset(76 - icon.width / 2, 72 - icon.height / 2));
  final title = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 44,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: 488);
  title.paint(canvas, Offset(140, 72 - title.height / 2));
  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<Uint8List> _createUserLocationMarker() async {
  const width = 144.0;
  const height = 184.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final pin = Path()
    ..moveTo(72, 178)
    ..cubicTo(60, 155, 16, 112, 16, 70)
    ..cubicTo(16, 34, 41, 8, 72, 8)
    ..cubicTo(103, 8, 128, 34, 128, 70)
    ..cubicTo(128, 112, 84, 155, 72, 178)
    ..close();

  canvas.drawShadow(pin, const Color(0x66000000), 8, false);
  canvas.drawPath(
    pin,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawPath(pin, Paint()..color = const Color(0xFFE53935));
  canvas.drawCircle(const Offset(72, 68), 31, Paint()..color = Colors.white);

  final icon = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(Icons.my_location_rounded.codePoint),
      style: TextStyle(
        color: const Color(0xFFE53935),
        fontSize: 39,
        fontFamily: Icons.my_location_rounded.fontFamily,
        package: Icons.my_location_rounded.fontPackage,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  icon.paint(canvas, Offset(72 - icon.width / 2, 68 - icon.height / 2));

  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

bool _hasCoordinates(RoomSummary room) {
  final latitude = room.latitude;
  final longitude = room.longitude;
  return latitude != null &&
      longitude != null &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

class _MapSearchBar extends StatelessWidget {
  const _MapSearchBar({
    required this.label,
    required this.onBack,
    required this.onSearch,
    required this.onFilter,
  });

  final String? label;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _MapButton(
        icon: Icons.arrow_back_rounded,
        tooltip: 'Quay lại',
        onTap: onBack,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Material(
          color: Colors.white,
          elevation: 5,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(25),
          child: InkWell(
            onTap: onSearch,
            borderRadius: BorderRadius.circular(25),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  SizedBox(width: 15),
                  Icon(
                    Icons.search_rounded,
                    size: 21,
                    color: Color(0xFF687571),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      label?.trim().isNotEmpty == true
                          ? label!
                          : 'Tìm khu vực, trường học...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFF87928F), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      _MapButton(icon: Icons.tune_rounded, tooltip: 'Bộ lọc', onTap: onFilter),
    ],
  );
}

class _SearchThisAreaButton extends StatelessWidget {
  const _SearchThisAreaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF009B80),
    elevation: 7,
    shadowColor: Colors.black26,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, color: Colors.white, size: 20),
            SizedBox(width: 7),
            Text(
              'Tìm kiếm khu vực này',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LocationPermissionCard extends StatelessWidget {
  const _LocationPermissionCard({required this.onLater, required this.onAllow});

  final VoidCallback onLater;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F7F3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF009B80),
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cho phép truy cập vị trí',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Để tìm phòng xung quanh bạn dễ dàng hơn.',
                      style: TextStyle(
                        color: Color(0xFF6C7775),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onAllow,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00A98F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Cho phép truy cập',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          TextButton(
            onPressed: onLater,
            child: const Text(
              'Để sau, dùng vị trí Hà Nội',
              style: TextStyle(color: Color(0xFF65716F)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MapLoadingOverlay extends StatelessWidget {
  const _MapLoadingOverlay();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0x52000000),
    child: Center(
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 20),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF00A98F),
              ),
            ),
            SizedBox(height: 17),
            Text(
              'Đang tìm phòng quanh khu vực này...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              'Vui lòng đợi trong giây lát.',
              style: TextStyle(color: Color(0xFF7A8583), fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyMapResults extends StatelessWidget {
  const _EmptyMapResults({
    required this.radiusMeters,
    required this.onExpandRadius,
  });

  final int radiusMeters;
  final VoidCallback onExpandRadius;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 310),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.manage_search_rounded,
            size: 48,
            color: Color(0xFF60706D),
          ),
          const SizedBox(height: 10),
          const Text(
            'Không tìm thấy phòng trong khu vực này',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            'Thử mở rộng bán kính ${_formatRadius(radiusMeters)} hoặc thay đổi bộ lọc để xem thêm kết quả nhé.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6F7B79),
              height: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 17),
          OutlinedButton.icon(
            onPressed: onExpandRadius,
            icon: const Icon(Icons.my_location_rounded, size: 18),
            label: const Text('Mở rộng bán kính'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF008E79),
              side: const BorderSide(color: Color(0xFF9EDDD2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  static String _formatRadius(int meters) {
    if (meters >= 1000) return '${meters ~/ 1000} km';
    return '$meters m';
  }
}

class _MapErrorBanner extends StatelessWidget {
  const _MapErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFF2F1),
    elevation: 4,
    borderRadius: BorderRadius.circular(16),
    child: ListTile(
      dense: true,
      leading: const Icon(Icons.wifi_off_rounded, color: Colors.redAccent),
      title: const Text(
        'Không thể tải phòng trong khu vực này.',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: TextButton(onPressed: onRetry, child: const Text('Thử lại')),
    ),
  );
}

class _ShowListButton extends StatelessWidget {
  const _ShowListButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 8,
    shadowColor: Colors.black26,
    borderRadius: BorderRadius.circular(26),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.format_list_bulleted_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Xem danh sách ($count phòng)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 4,
    shadowColor: Colors.black26,
    shape: const CircleBorder(),
    child: IconButton(onPressed: onTap, tooltip: tooltip, icon: Icon(icon)),
  );
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 6,
    shadowColor: Colors.black26,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 52,
        height: 52,
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(Icons.my_location_rounded, color: Color(0xFF2878FF)),
        ),
      ),
    ),
  );
}

class _RoomMapPreview extends StatelessWidget {
  const _RoomMapPreview({
    required this.room,
    required this.onTap,
    this.distanceLabel,
    this.onClose,
  });

  final RoomSummary room;
  final String? distanceLabel;
  final VoidCallback? onClose;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 10,
    shadowColor: Colors.black38,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: (room.estimatedMonthlyCost ?? 0) > 0 ? 132 : 112,
        child: Row(
          children: [
            SizedBox(
              width: 112,
              height: double.infinity,
              child: room.imageUrl?.isNotEmpty == true
                  ? Image.network(
                      room.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ImageFallback(),
                    )
                  : const _ImageFallback(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (onClose != null)
                          IconButton(
                            onPressed: onClose,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded, size: 19),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF008E79),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${formatVnd(room.priceMonthly)}/tháng',
                      style: const TextStyle(
                        color: Color(0xFF008E79),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (room.estimatedMonthlyCost case final estimated?
                        when estimated > 0)
                      Text(
                        'Dự kiến ${formatVnd(estimated)}/tháng',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF667571),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            [?distanceLabel, room.fullAddress].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF667571),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE4ECEA),
    child: Center(child: Icon(Icons.home_work_outlined, size: 36)),
  );
}

class _MapPlaceResult {
  const _MapPlaceResult({required this.label, required this.location});

  final String label;
  final LatLng location;
}

class _MapPlaceSearchSheet extends ConsumerStatefulWidget {
  const _MapPlaceSearchSheet();

  @override
  ConsumerState<_MapPlaceSearchSheet> createState() =>
      _MapPlaceSearchSheetState();
}

class _MapPlaceSearchSheetState extends ConsumerState<_MapPlaceSearchSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<GoongPlacePrediction> _suggestions = const [];
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String rawValue) {
    _debounce?.cancel();
    final value = rawValue.trim();
    if (value.length < 2) {
      _requestId++;
      setState(() {
        _loading = false;
        _error = null;
        _suggestions = const [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadSuggestions(value);
    });
  }

  Future<void> _loadSuggestions(String value) async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final suggestions = await ref
          .read(goongLocationDataSourceProvider)
          .autocomplete(input: value, limit: 6);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _suggestions = suggestions;
        _error = suggestions.isEmpty
            ? 'Không tìm thấy địa điểm phù hợp.'
            : null;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _suggestions = const [];
        _error = 'Không tải được gợi ý. Hãy kiểm tra kết nối và thử lại.';
      });
    }
  }

  Future<void> _select(GoongPlacePrediction prediction) async {
    _debounce?.cancel();
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ref
          .read(goongLocationDataSourceProvider)
          .placeDetail(placeId: prediction.placeId);
      if (!mounted || requestId != _requestId) return;
      Navigator.pop(
        context,
        _MapPlaceResult(
          label: prediction.mainText,
          location: LatLng(detail.latitude, detail.longitude),
        ),
      );
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _error = 'Không lấy được vị trí của địa điểm này.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF9FBFA),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    clipBehavior: Clip.antiAlias,
    child: AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1DBD8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tìm khu vực, trường học',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Nhập trường đại học, quận hoặc địa chỉ...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF008E79),
                  ),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            _onChanged('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 19),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: const BorderSide(color: Color(0xFFDDE7E4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: const BorderSide(color: Color(0xFFDDE7E4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: const BorderSide(
                      color: Color(0xFF00A884),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            if (_loading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF00A884),
                backgroundColor: Colors.transparent,
              )
            else
              const SizedBox(height: 2),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF687571)),
                ),
              )
            else if (_suggestions.isEmpty)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'Nhập ít nhất 2 ký tự để nhận gợi ý địa điểm từ Goong.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF75827E)),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final prediction = _suggestions[index];
                    return ListTile(
                      onTap: _loading ? null : () => _select(prediction),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE2F5F0),
                        foregroundColor: Color(0xFF008E79),
                        child: Icon(Icons.location_on_outlined),
                      ),
                      title: Text(
                        prediction.mainText,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: prediction.secondaryText.isEmpty
                          ? null
                          : Text(
                              prediction.secondaryText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: const Icon(Icons.north_west_rounded, size: 18),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _MapFilterSheet extends StatefulWidget {
  const _MapFilterSheet({required this.query, required this.amenities});

  final RoomSearchQuery query;
  final List<Amenity> amenities;

  @override
  State<_MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<_MapFilterSheet> {
  static const _roomTypes = <(String, String)>[
    ('ROOM_SINGLE', 'Phòng đơn'),
    ('ROOM_SHARED', 'Ở ghép'),
    ('STUDIO', 'Studio'),
    ('ONE_BEDROOM', '1 phòng ngủ'),
    ('WHOLE_HOUSE', 'Nguyên căn'),
  ];

  late RangeValues _price;
  late RangeValues _area;
  String? _roomType;
  late Set<String> _amenityCodes;

  @override
  void initState() {
    super.initState();
    _price = RangeValues(
      (widget.query.minPrice ?? 0) / 1000000,
      (widget.query.maxPrice ?? 10000000) / 1000000,
    );
    _area = RangeValues(
      widget.query.minArea ?? 10,
      widget.query.maxArea ?? 100,
    );
    _roomType = widget.query.roomType;
    _amenityCodes = widget.query.amenityCodes.toSet();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD5DEDC),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bộ lọc tìm phòng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(onPressed: _reset, child: const Text('Đặt lại')),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FilterTitle(
            title: 'Khoảng giá (triệu/tháng)',
            value:
                '${_price.start.toStringAsFixed(0)} - ${_price.end.toStringAsFixed(0)} triệu',
          ),
          RangeSlider(
            values: _price,
            min: 0,
            max: 10,
            divisions: 20,
            activeColor: const Color(0xFF00A884),
            labels: RangeLabels(
              '${_price.start.toStringAsFixed(1)}tr',
              '${_price.end.toStringAsFixed(1)}tr',
            ),
            onChanged: (value) => setState(() => _price = value),
          ),
          const SizedBox(height: 8),
          const Text(
            'Loại phòng',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _roomType == null,
                onSelected: (_) => setState(() => _roomType = null),
              ),
              ..._roomTypes.map(
                (item) => ChoiceChip(
                  label: Text(item.$2),
                  selected: _roomType == item.$1,
                  onSelected: (_) => setState(() => _roomType = item.$1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _FilterTitle(
            title: 'Diện tích (m²)',
            value:
                '${_area.start.toStringAsFixed(0)} - ${_area.end.toStringAsFixed(0)} m²',
          ),
          RangeSlider(
            values: _area,
            min: 10,
            max: 100,
            divisions: 18,
            activeColor: const Color(0xFF00A884),
            labels: RangeLabels(
              '${_area.start.toStringAsFixed(0)}m²',
              '${_area.end.toStringAsFixed(0)}m²',
            ),
            onChanged: (value) => setState(() => _area = value),
          ),
          if (widget.amenities.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Tiện ích',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.amenities
                  .map((amenity) {
                    final selected = _amenityCodes.contains(amenity.code);
                    return FilterChip(
                      avatar: Icon(
                        _amenityIcon(amenity.code),
                        size: 17,
                        color: selected
                            ? const Color(0xFF008E79)
                            : const Color(0xFF60706C),
                      ),
                      label: Text(amenity.name),
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: const Color(0xFFDDF5EF),
                      onSelected: (_) {
                        setState(() {
                          if (selected) {
                            _amenityCodes.remove(amenity.code);
                          } else {
                            _amenityCodes.add(amenity.code);
                          }
                        });
                      },
                    );
                  })
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _apply,
              child: const Text(
                'Áp dụng bộ lọc',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _reset() {
    setState(() {
      _price = const RangeValues(0, 10);
      _area = const RangeValues(10, 100);
      _roomType = null;
      _amenityCodes.clear();
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      widget.query.copyWith(
        clearPrice: true,
        minPrice: _price.start <= 0 ? null : (_price.start * 1000000).round(),
        maxPrice: _price.end >= 10 ? null : (_price.end * 1000000).round(),
        clearArea: true,
        minArea: _area.start <= 10 ? null : _area.start,
        maxArea: _area.end >= 100 ? null : _area.end,
        roomType: _roomType,
        clearRoomType: _roomType == null,
        amenityCodes: _amenityCodes.toList(growable: false),
        page: 1,
      ),
    );
  }
}

IconData _amenityIcon(String code) {
  final normalized = code.toUpperCase();
  if (normalized.contains('WIFI')) return Icons.wifi_rounded;
  if (normalized.contains('AIR') || normalized.contains('CONDITION')) {
    return Icons.ac_unit_rounded;
  }
  if (normalized.contains('WASH')) return Icons.local_laundry_service_outlined;
  if (normalized.contains('BED')) return Icons.bed_outlined;
  if (normalized.contains('BALCON')) return Icons.balcony_outlined;
  if (normalized.contains('DESK')) return Icons.desk_outlined;
  if (normalized.contains('FRIDGE')) return Icons.kitchen_outlined;
  if (normalized.contains('PARK')) return Icons.local_parking_rounded;
  return Icons.check_circle_outline_rounded;
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE9F7F3),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF008E79),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ],
  );
}

class _MapInitializingScreen extends StatelessWidget {
  const _MapInitializingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFFF3F7F6),
    body: Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: Color(0xFF00A884),
      ),
    ),
  );
}

class _MissingMapKeyScreen extends StatelessWidget {
  const _MissingMapKeyScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bản đồ phòng trọ')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.key_off_outlined, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Chưa có GOONG_MAPTILES_KEY',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy chạy ứng dụng với --dart-define=GOONG_MAPTILES_KEY=...',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    ),
  );
}
