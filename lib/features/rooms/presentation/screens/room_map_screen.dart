import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../core/config/goong_config.dart';
import '../../../../core/location/location_failure.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/room_search_query.dart';
import '../../domain/entities/room_summary.dart';
import '../providers/room_providers.dart';

const _mapRoomQuery = RoomSearchQuery(limit: 100);

class RoomMapScreen extends ConsumerStatefulWidget {
  const RoomMapScreen({super.key});

  @override
  ConsumerState<RoomMapScreen> createState() => _RoomMapScreenState();
}

class _RoomMapScreenState extends ConsumerState<RoomMapScreen> {
  MapLibreMapController? _mapController;
  final Map<String, RoomSummary> _roomByCircleId = {};
  bool _styleLoaded = false;
  bool _renderingMarkers = false;
  String _renderSignature = '';
  RoomSummary? _selectedRoom;
  LatLng? _currentLocation;
  Circle? _userLocationCircle;
  bool _locating = false;
  bool _locationExplained = false;

  @override
  Widget build(BuildContext context) {
    if (!GoongConfig.hasMaptilesKey) return const _MissingMapKeyScreen();

    final rooms = ref.watch(roomSearchProvider(_mapRoomQuery));
    final mappableRooms = rooms.asData?.value.where(_hasCoordinates).toList();

    if (mappableRooms != null) {
      final signature = mappableRooms.map((room) => room.id).join('|');
      if (_styleLoaded && signature != _renderSignature) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _renderMarkers(mappableRooms, signature);
        });
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: GoongConfig.mapStyleUrl,
            initialCameraPosition: const CameraPosition(
              target: LatLng(21.0285, 105.8542),
              zoom: 11.5,
            ),
            compassEnabled: true,
            logoEnabled: false,
            attributionButtonPosition: null,
            onMapCreated: (controller) {
              _mapController = controller;
              controller.onCircleTapped.add(_onCircleTapped);
            },
            onStyleLoadedCallback: () {
              _styleLoaded = true;
              final items = ref
                  .read(roomSearchProvider(_mapRoomQuery))
                  .asData
                  ?.value
                  .where(_hasCoordinates)
                  .toList();
              if (items != null) {
                _renderMarkers(items, items.map((room) => room.id).join('|'));
              }
            },
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 12,
            child: _MapButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Quay lại',
              onTap: () => context.pop(),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 66,
            right: 66,
            child: _RoomCount(
              loading: rooms.isLoading,
              count: mappableRooms?.length,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            right: 12,
            child: _MapButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Tải lại phòng',
              onTap: () => ref.invalidate(roomSearchProvider(_mapRoomQuery)),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 68,
            left: 14,
            right: 14,
            child: _MapViewSelector(onListTap: () => context.pop()),
          ),
          if (rooms.hasError)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 116,
              left: 16,
              right: 16,
              child: Material(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Không thể tải vị trí phòng. Hãy kiểm tra kết nối và thử lại.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (_selectedRoom case final room?)
            Positioned(
              left: 14,
              right: 14,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: _RoomMapPreview(
                room: room,
                onClose: () => setState(() => _selectedRoom = null),
                onTap: () => context.push('/rooms/${room.id}'),
              ),
            ),
          Positioned(
            right: 16,
            bottom:
                MediaQuery.paddingOf(context).bottom +
                (_selectedRoom == null ? 24 : 146),
            child: _LocationButton(
              loading: _locating,
              onTap: _locating ? null : _goToCurrentLocation,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    if (!_locationExplained) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sử dụng vị trí của bạn?'),
          content: const Text(
            'TrọSV cần vị trí để đưa bản đồ đến nơi bạn đang đứng và tìm '
            'phòng ở gần. Vị trí chỉ được lấy khi bạn sử dụng chức năng này.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
      _locationExplained = true;
    }

    setState(() => _locating = true);
    try {
      final position = await ref
          .read(locationServiceProvider)
          .getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      _currentLocation = location;

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 15),
        ),
      );
      await _drawUserLocation();
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

    final previous = _userLocationCircle;
    if (previous != null) await controller.removeCircle(previous);
    _userLocationCircle = await controller.addCircle(
      CircleOptions(
        geometry: location,
        circleRadius: 10,
        circleColor: '#2878FF',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 4,
      ),
    );
  }

  Future<void> _renderMarkers(List<RoomSummary> rooms, String signature) async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded || _renderingMarkers) return;

    _renderingMarkers = true;
    try {
      await controller.clearCircles();
      _roomByCircleId.clear();

      final circles = await controller.addCircles(
        rooms
            .map(
              (room) => CircleOptions(
                geometry: LatLng(room.latitude!, room.longitude!),
                circleRadius: 9,
                circleColor: '#008E79',
                circleStrokeColor: '#FFFFFF',
                circleStrokeWidth: 3,
              ),
            )
            .toList(),
      );
      for (var index = 0; index < circles.length; index++) {
        _roomByCircleId[circles[index].id] = rooms[index];
      }
      _userLocationCircle = null;
      await _drawUserLocation();
      _renderSignature = signature;
    } finally {
      _renderingMarkers = false;
    }
  }

  void _onCircleTapped(Circle circle) {
    final room = _roomByCircleId[circle.id];
    if (room == null || !mounted) return;
    setState(() => _selectedRoom = room);
  }
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

class _MapViewSelector extends StatelessWidget {
  const _MapViewSelector({required this.onListTap});

  final VoidCallback onListTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 4,
    shadowColor: Colors.black26,
    borderRadius: BorderRadius.circular(22),
    child: Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _MapViewOption(
              icon: Icons.format_list_bulleted_rounded,
              label: 'Danh sách',
              selected: false,
              onTap: onListTap,
            ),
          ),
          const Expanded(
            child: _MapViewOption(
              icon: Icons.map_outlined,
              label: 'Bản đồ',
              selected: true,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MapViewOption extends StatelessWidget {
  const _MapViewOption({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF008E79) : Colors.transparent,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : const Color(0xFF566763),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF566763),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RoomCount extends StatelessWidget {
  const _RoomCount({required this.loading, required this.count});

  final bool loading;
  final int? count;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 4,
    shadowColor: Colors.black26,
    borderRadius: BorderRadius.circular(24),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        loading ? 'Đang tải phòng...' : '${count ?? 0} phòng trên bản đồ',
        textAlign: TextAlign.center,
        maxLines: 1,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _RoomMapPreview extends StatelessWidget {
  const _RoomMapPreview({
    required this.room,
    required this.onClose,
    required this.onTap,
  });

  final RoomSummary room;
  final VoidCallback onClose;
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
        height: 112,
        child: Row(
          children: [
            SizedBox(
              width: 112,
              height: 112,
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
                        IconButton(
                          onPressed: onClose,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded, size: 19),
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
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            room.fullAddress,
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
