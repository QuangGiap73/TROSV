import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../../../core/config/goong_config.dart';
import '../../../../../../core/location/location_provider.dart';
import '../../../domain/entities/location/geocoded_address.dart';
import '../providers/property_location_provider.dart';

class PropertyInlineMapResult {
  const PropertyInlineMapResult({
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.province,
    required this.district,
    required this.ward,
  });

  final double latitude;
  final double longitude;
  final String addressText;
  final String province;
  final String district;
  final String ward;
}

class PropertyInlineMap extends ConsumerStatefulWidget {
  const PropertyInlineMap({
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.enabled,
    required this.onLocationChanged,
    super.key,
  });

  final double? latitude;
  final double? longitude;
  final String addressText;
  final bool enabled;
  final ValueChanged<PropertyInlineMapResult> onLocationChanged;

  @override
  ConsumerState<PropertyInlineMap> createState() =>
      _PropertyInlineMapState();
}

class _PropertyInlineMapState extends ConsumerState<PropertyInlineMap> {
  static const LatLng _defaultTarget = LatLng(
    21.0285,
    105.8542,
  );

  MapLibreMapController? _controller;

  late LatLng _selected;

  bool _hasLocation = false;
  bool _locating = false;

  /// true khi map đang được di chuyển bằng animateCamera().
  /// Trong thời gian này không reverse geocode ở onCameraIdle.
  bool _programmaticCameraMove = false;

  /// Dùng để bỏ qua reverse geocode lặp lại cùng một vị trí.
  LatLng? _lastReverseTarget;

  /// Chống response cũ trả về sau response mới.
  int _reverseRequestId = 0;

  late final ValueNotifier<_AddressPanelState> _addressState;

  @override
  void initState() {
    super.initState();

    _hasLocation =
        widget.latitude != null && widget.longitude != null;

    _selected = _hasLocation
        ? LatLng(
            widget.latitude!,
            widget.longitude!,
          )
        : _defaultTarget;

    _addressState = ValueNotifier<_AddressPanelState>(
      widget.addressText.trim().isNotEmpty
          ? _AddressPanelState.ready(
              widget.addressText.trim(),
            )
          : const _AddressPanelState.idle(),
    );
  }

  @override
  void didUpdateWidget(
    covariant PropertyInlineMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final hasNewLocation =
        widget.latitude != null && widget.longitude != null;

    if (!hasNewLocation) {
      _hasLocation = false;
      _lastReverseTarget = null;

      if (widget.addressText.trim().isEmpty) {
        _addressState.value =
            const _AddressPanelState.idle();
      }

      return;
    }

    final target = LatLng(
      widget.latitude!,
      widget.longitude!,
    );

    final targetChanged =
        !_hasLocation ||
        (_selected.latitude - target.latitude).abs() > 0.000001 ||
        (_selected.longitude - target.longitude).abs() > 0.000001;

    _hasLocation = true;

    /// Khi forward geocode từ ô địa chỉ trả về,
    /// cập nhật text trên panel map nhưng không reverse lại.
    if (widget.addressText.trim().isNotEmpty &&
        widget.addressText != oldWidget.addressText) {
      _addressState.value = _AddressPanelState.ready(
        widget.addressText.trim(),
      );
    }

    if (!targetChanged) {
      return;
    }

    _selected = target;

    /// Vị trí đến từ form/property -> coi như đã biết địa chỉ,
    /// không cần reverse lại ngay sau animate.
    _lastReverseTarget = target;

    _animateTo(
      target,
      zoom: 16,
    );
  }

  @override
  void dispose() {
    _addressState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!GoongConfig.hasMaptilesKey) {
      return Container(
        height: 250,
        margin: const EdgeInsets.only(bottom: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EFED),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Chưa cấu hình GOONG_MAPTILES_KEY.',
        ),
      );
    }

    return Container(
      height: 250,
      margin: const EdgeInsets.only(bottom: 18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD6E3E0),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: !widget.enabled,
              child: MapLibreMap(
                styleString: GoongConfig.mapStyleUrl,

                initialCameraPosition: CameraPosition(
                  target: _selected,
                  zoom: _hasLocation ? 16 : 13,
                ),

                /// QUAN TRỌNG:
                /// Phiên bản MapLibre của project cần track camera
                /// để controller.cameraPosition luôn phản ánh tâm mới.
                trackCameraPosition: true,

                compassEnabled: false,
                logoEnabled: false,
                attributionButtonPosition: null,

                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },

                onMapCreated: (controller) {
                  _controller = controller;

                  if (_hasLocation &&
                      widget.addressText.trim().isEmpty) {
                    _reverseGeocode(
                      _selected,
                      emitToForm: false,
                    );
                  }
                },

                /// Không setState ở đây.
                /// Chỉ giữ tọa độ mới nhất trong biến local.
                onCameraMove: (position) {
                  if (!widget.enabled ||
                      _programmaticCameraMove) {
                    return;
                  }

                  _selected = position.target;
                },

                /// Khi user thả tay mới reverse geocode đúng 1 lần.
                onCameraIdle: _handleCameraIdle,
              ),
            ),
          ),

          const Center(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(bottom: 38),
                child: Icon(
                  Icons.location_pin,
                  size: 50,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),

          if (widget.enabled)
            Positioned(
              right: 12,
              top: 12,
              child: FloatingActionButton.small(
                heroTag: 'property-inline-current-location',
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF008E78),
                onPressed:
                    _locating ? null : _goToCurrentLocation,
                child: _locating
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),

          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: ValueListenableBuilder<_AddressPanelState>(
              valueListenable: _addressState,
              builder: (context, state, _) {
                return _AddressPanel(
                  state: state,
                );
              },
            ),
          ),

          if (!widget.enabled)
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Vị trí khu trọ đã chọn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleCameraIdle() {
    if (!widget.enabled || _programmaticCameraMove) {
      return;
    }

    /// Ưu tiên lấy tâm thật từ controller.
    /// _selected là fallback nếu controller chưa có cameraPosition.
    final target =
        _controller?.cameraPosition?.target ?? _selected;

    _selected = target;

    if (_isSameLocation(
      target,
      _lastReverseTarget,
    )) {
      return;
    }

    _reverseGeocode(
      target,
      emitToForm: true,
    );
  }

  bool _isSameLocation(
    LatLng first,
    LatLng? second,
  ) {
    if (second == null) {
      return false;
    }

    return (first.latitude - second.latitude).abs() < 0.000001 &&
        (first.longitude - second.longitude).abs() < 0.000001;
  }

  Future<void> _reverseGeocode(
    LatLng target, {
    required bool emitToForm,
  }) async {
    final requestId = ++_reverseRequestId;

    _hasLocation = true;

    _addressState.value =
        const _AddressPanelState.loading();

    try {
      final result = await ref
          .read(goongLocationDataSourceProvider)
          .reverseGeocode(
            latitude: target.latitude,
            longitude: target.longitude,
          );

      if (!mounted || requestId != _reverseRequestId) {
        return;
      }

      _lastReverseTarget = target;

      _addressState.value =
          _AddressPanelState.ready(
        result.formattedAddress,
      );

      if (!emitToForm) {
        return;
      }

      widget.onLocationChanged(
        PropertyInlineMapResult(
          latitude: target.latitude,
          longitude: target.longitude,
          addressText: result.formattedAddress,
          province: result.province,
          district: result.district,
          ward: result.ward,
        ),
      );
    } catch (_) {
      if (!mounted || requestId != _reverseRequestId) {
        return;
      }

      _addressState.value =
          const _AddressPanelState.error();
    }
  }

  Future<void> _animateTo(
    LatLng target, {
    required double zoom,
  }) async {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    _programmaticCameraMove = true;
    _selected = target;

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: zoom,
          ),
        ),
      );
    } finally {
      /// Đợi idle callback của animateCamera kết thúc.
      await Future<void>.delayed(
        const Duration(milliseconds: 120),
      );

      if (mounted) {
        _programmaticCameraMove = false;
      }
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (_locating) {
      return;
    }

    setState(() {
      _locating = true;
    });

    try {
      final position = await ref
          .read(locationServiceProvider)
          .getCurrentPosition();

      final target = LatLng(
        position.latitude,
        position.longitude,
      );

      _hasLocation = true;
      _selected = target;

      await _animateTo(
        target,
        zoom: 16,
      );

      /// Nút vị trí hiện tại là một lựa chọn mới,
      /// vì vậy reverse geocode và đẩy lại về form.
      _lastReverseTarget = null;

      await _reverseGeocode(
        target,
        emitToForm: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }
}

class _AddressPanel extends StatelessWidget {
  const _AddressPanel({
    required this.state,
  });

  final _AddressPanelState state;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 20,
              color: Color(0xFF008E78),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: switch (state.type) {
                _AddressPanelType.idle => const Text(
                    'Nhập địa chỉ hoặc kéo bản đồ để chọn vị trí.',
                    style: TextStyle(fontSize: 12),
                  ),
                _AddressPanelType.loading => const Row(
                    children: [
                      SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đang xác định địa chỉ...',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                _AddressPanelType.error => const Text(
                    'Không lấy được địa chỉ tại vị trí này.',
                    style: TextStyle(fontSize: 12),
                  ),
                _AddressPanelType.ready => Text(
                    state.text ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _AddressPanelType {
  idle,
  loading,
  ready,
  error,
}

class _AddressPanelState {
  const _AddressPanelState._(
    this.type,
    this.text,
  );

  const _AddressPanelState.idle()
      : this._(
          _AddressPanelType.idle,
          null,
        );

  const _AddressPanelState.loading()
      : this._(
          _AddressPanelType.loading,
          null,
        );

  const _AddressPanelState.error()
      : this._(
          _AddressPanelType.error,
          null,
        );

  factory _AddressPanelState.ready(
    String text,
  ) {
    return _AddressPanelState._(
      _AddressPanelType.ready,
      text,
    );
  }

  final _AddressPanelType type;
  final String? text;
}
