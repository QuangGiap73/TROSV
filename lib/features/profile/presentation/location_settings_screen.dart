import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_failure.dart';
import '../../../core/location/location_provider.dart';
import '../../../core/location/location_service.dart';

class LocationSettingsScreen extends ConsumerStatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  ConsumerState<LocationSettingsScreen> createState() =>
      _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends ConsumerState<LocationSettingsScreen>
    with WidgetsBindingObserver {
  LocationAccessStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    if (mounted) setState(() => _loading = true);
    final status = await ref.read(locationServiceProvider).getStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _togglePermission(bool enabled) async {
    final service = ref.read(locationServiceProvider);

    if (!enabled) {
      final open = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Tắt quyền vị trí?'),
          content: const Text(
            'Android và iOS không cho ứng dụng tự thu hồi quyền. Bạn có thể '
            'tắt quyền Vị trí của TrọSV trong cài đặt hệ thống.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Mở cài đặt'),
            ),
          ],
        ),
      );
      if (open == true) await service.openAppSettings();
      return;
    }

    setState(() => _loading = true);
    try {
      await service.getCurrentPosition();
    } on LocationFailure catch (failure) {
      if (!mounted) return;
      if (failure.type == LocationFailureType.serviceDisabled) {
        final open = await _confirmOpenSettings(
          title: 'GPS đang tắt',
          message: failure.message,
          action: 'Mở cài đặt GPS',
        );
        if (open) await service.openLocationSettings();
      } else if (failure.type == LocationFailureType.permissionDeniedForever) {
        final open = await _confirmOpenSettings(
          title: 'Quyền đã bị chặn',
          message: 'Hãy mở cài đặt ứng dụng và cấp quyền Vị trí cho TrọSV.',
          action: 'Mở cài đặt',
        );
        if (open) await service.openAppSettings();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      }
    } finally {
      await _refreshStatus();
    }
  }

  Future<bool> _confirmOpenSettings({
    required String title,
    required String message,
    required String action,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Để sau'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final permissionOn = status?.permissionGranted ?? false;
    final gpsOn = status?.serviceEnabled ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Quyền vị trí'),
        backgroundColor: const Color(0xFFF5F7F6),
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading && status == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshStatus,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDDF6EF), Color(0xFFF2FBF8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF008E79),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Vị trí giúp TrọSV tìm phòng gần bạn và tính '
                            'khoảng cách chính xác hơn.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SettingCard(
                    icon: Icons.gps_fixed_rounded,
                    title: 'Quyền truy cập vị trí',
                    subtitle: _permissionDescription(status?.permission),
                    trailing: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch(
                            value: permissionOn,
                            onChanged: _togglePermission,
                          ),
                  ),
                  const SizedBox(height: 12),
                  _SettingCard(
                    icon: Icons.satellite_alt_outlined,
                    title: 'Dịch vụ GPS của thiết bị',
                    subtitle: gpsOn ? 'Đang bật' : 'Đang tắt',
                    trailing: TextButton(
                      onPressed: () async {
                        await ref
                            .read(locationServiceProvider)
                            .openLocationSettings();
                      },
                      child: Text(gpsOn ? 'Cài đặt' : 'Bật GPS'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'TrọSV chỉ lấy vị trí khi bạn chủ động dùng bản đồ hoặc '
                    'tìm phòng gần mình. Ứng dụng không theo dõi vị trí nền.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xFF6A7874),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

String _permissionDescription(AppLocationPermission? permission) {
  return switch (permission) {
    AppLocationPermission.whileInUse => 'Được phép khi đang dùng ứng dụng',
    AppLocationPermission.always => 'Luôn được phép',
    AppLocationPermission.deniedForever => 'Đã bị chặn trong cài đặt hệ thống',
    _ => 'Chưa được cấp quyền',
  };
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F6F1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: const Color(0xFF008E79)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF71807C)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    ),
  );
}
