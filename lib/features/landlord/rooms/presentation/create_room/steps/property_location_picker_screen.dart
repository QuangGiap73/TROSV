import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../../../core/config/goong_config.dart';
import '../../../../../../core/location/location_provider.dart';
import '../../../domain/entities/location/geocoded_address.dart';
import '../providers/property_location_provider.dart';

class PropertyLocationResult {
  const PropertyLocationResult({
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.province,
    required this.district,
    required this.ward,
  });

  final double latitude, longitude;
  final String addressText, province, district, ward;
}

class PropertyLocationPickerScreen extends ConsumerStatefulWidget {
  const PropertyLocationPickerScreen({
    this.latitude,
    this.longitude,
    super.key,
  });
  final double? latitude;
  final double? longitude;

  @override
  ConsumerState<PropertyLocationPickerScreen> createState() =>
      _PropertyLocationPickerScreenState();
}

class _PropertyLocationPickerScreenState
    extends ConsumerState<PropertyLocationPickerScreen> {
  MapLibreMapController? _controller;
  late LatLng _selected;
  late LocationCoordinates _lookupCoordinates;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _selected = LatLng(
      widget.latitude ?? 21.0285,
      widget.longitude ?? 105.8542,
    );
    _lookupCoordinates = (
      latitude: _selected.latitude,
      longitude: _selected.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!GoongConfig.hasMaptilesKey) {
      return const Scaffold(
        body: Center(child: Text('Chưa cấu hình GOONG_MAPTILES_KEY.')),
      );
    }

    final address = ref.watch(reverseGeocodeProvider(_lookupCoordinates));
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn vị trí khu trọ')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MapLibreMap(
            styleString: GoongConfig.mapStyleUrl,
            initialCameraPosition: CameraPosition(
              target: _selected,
              zoom: widget.latitude == null ? 12 : 16,
            ),
            compassEnabled: true,
            // Bắt buộc bật để controller.cameraPosition và callback camera
            // luôn phản ánh đúng tâm bản đồ sau khi người dùng kéo.
            trackCameraPosition: true,
            logoEnabled: false,
            attributionButtonPosition: null,
            onMapCreated: (controller) => _controller = controller,
            // Chỉ ghi nhận tâm mới khi kéo, không gọi API tại đây.
            onCameraMove: (position) => _selected = position.target,
            // Khi camera dừng mới cập nhật provider và gọi Goong đúng một lần.
            onCameraIdle: _onCameraIdle,
          ),
          const IgnorePointer(
            child: Padding(
              padding: EdgeInsets.only(bottom: 42),
              child: Icon(
                Icons.location_pin,
                size: 54,
                color: Colors.redAccent,
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 205,
            child: FloatingActionButton.small(
              heroTag: 'property-current-location',
              onPressed: _locating ? null : _goToCurrentLocation,
              child: _locating
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _AddressPanel(
              address: address,
              coordinates: _lookupCoordinates,
              onRetry: () =>
                  ref.invalidate(reverseGeocodeProvider(_lookupCoordinates)),
              onConfirm: address.value == null
                  ? null
                  : () => _confirm(address.requireValue),
            ),
          ),
        ],
      ),
    );
  }

  void _onCameraIdle() {
    // onCameraMove cung cấp tâm mới chính xác nhất. cameraPosition được dùng
    // làm phương án dự phòng khi bản đồ di chuyển bằng animateCamera.
    final target = _selected;
    _selected = target;

    final changed =
        (target.latitude - _lookupCoordinates.latitude).abs() > 0.000001 ||
        (target.longitude - _lookupCoordinates.longitude).abs() > 0.000001;
    if (!changed || !mounted) return;

    setState(() {
      _lookupCoordinates = (
        latitude: target.latitude,
        longitude: target.longitude,
      );
    });
  }

  Future<void> _goToCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await ref
          .read(locationServiceProvider)
          .getCurrentPosition();
      final target = LatLng(position.latitude, position.longitude);
      _selected = target;
      await _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16),
        ),
      );
      if (mounted) {
        setState(() {
          _lookupCoordinates = (
            latitude: target.latitude,
            longitude: target.longitude,
          );
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm(GeocodedAddress address) {
    Navigator.pop(
      context,
      PropertyLocationResult(
        latitude: _lookupCoordinates.latitude,
        longitude: _lookupCoordinates.longitude,
        addressText: address.formattedAddress,
        province: address.province,
        district: address.district,
        ward: address.ward,
      ),
    );
  }
}

class _AddressPanel extends StatelessWidget {
  const _AddressPanel({
    required this.address,
    required this.coordinates,
    required this.onRetry,
    required this.onConfirm,
  });

  final AsyncValue<GeocodedAddress> address;
  final LocationCoordinates coordinates;
  final VoidCallback onRetry;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ tại ghim',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            address.when(
              loading: () => const Row(
                children: [
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Đang tìm địa chỉ mới...'),
                ],
              ),
              error: (error, _) => Row(
                children: [
                  const Expanded(child: Text('Không lấy được địa chỉ.')),
                  TextButton(onPressed: onRetry, child: const Text('Thử lại')),
                ],
              ),
              data: (value) => Text(
                value.formattedAddress,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${coordinates.latitude.toStringAsFixed(6)}, '
              '${coordinates.longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.check),
                label: const Text('Xác nhận vị trí'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
