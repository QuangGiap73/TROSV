import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/room_trust.dart';
import '../network_video_player.dart';

class SharedRoomDetailData {
  const SharedRoomDetailData({
    required this.title,
    required this.status,
    required this.priceMonthly,
    this.estimatedMonthlyCost,
    this.trust,
    required this.depositAmount,
    required this.areaM2,
    required this.maxPeople,
    required this.address,
    this.latitude,
    this.longitude,
    required this.imageUrls,
    this.videoUrls = const [],
    required this.amenities,
    required this.costs,
    this.floor,
    this.description,
    this.houseRules,
    this.availableDate,
    this.lastConfirmedAt,
    this.viewsCount = 0,
    this.rejectionReason,
  });
  final String title, status, address;
  final int priceMonthly, depositAmount, maxPeople, viewsCount;
  final int? estimatedMonthlyCost;
  final RoomTrust? trust;
  final double areaM2;
  final double? latitude, longitude;
  final int? floor;
  final List<String> imageUrls, amenities;
  final List<String> videoUrls;
  final Map<String, int> costs;
  final String? description, houseRules, rejectionReason;
  final DateTime? availableDate, lastConfirmedAt;
}

class SharedRoomDetailContent extends StatelessWidget {
  const SharedRoomDetailContent({
    required this.room,
    this.onRefresh,
    super.key,
  });
  final SharedRoomDetailData room;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
      children: [
        _Gallery(urls: room.imageUrls),
        if (room.videoUrls.isNotEmpty) ...[
          const SizedBox(height: 14),
          _VideoSection(urls: room.videoUrls),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                room.title,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _Status(status: room.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${formatVnd(room.priceMonthly)}/tháng',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF00856F),
          ),
        ),
        if (room.estimatedMonthlyCost case final estimated?
            when estimated > 0) ...[
          const SizedBox(height: 5),
          Text(
            'Chi phí dự kiến: ${formatVnd(estimated)}/tháng',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF667571),
            ),
          ),
        ],
        const SizedBox(height: 14),
        _Card(
          child: Row(
            children: [
              Expanded(
                child: _Fact(
                  Icons.square_foot_rounded,
                  '${_decimal(room.areaM2)} m²',
                ),
              ),
              const _Divider(),
              Expanded(
                child: _Fact(
                  Icons.layers_outlined,
                  room.floor == null ? 'Chưa rõ tầng' : 'Tầng ${room.floor}',
                ),
              ),
              const _Divider(),
              Expanded(
                child: _Fact(
                  Icons.people_alt_outlined,
                  '${room.maxPeople} người',
                ),
              ),
            ],
          ),
        ),
        if (room.address.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Location(
            address: room.address,
            latitude: room.latitude,
            longitude: room.longitude,
          ),
        ],
        if (room.rejectionReason?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _Notice(text: 'Lý do từ chối: ${room.rejectionReason}'),
        ],
        if (room.availableDate != null ||
            room.lastConfirmedAt != null ||
            room.viewsCount > 0) ...[
          const SizedBox(height: 14),
          _Meta(room: room),
        ],
        if (room.description?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 14),
          _Section(
            title: 'Mô tả',
            icon: Icons.description_outlined,
            child: Text(room.description!, style: const TextStyle(height: 1.5)),
          ),
        ],
        const SizedBox(height: 14),
        _Costs(room: room),
        const SizedBox(height: 14),
        _Amenities(items: room.amenities),
        if (room.houseRules?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 14),
          _Section(
            title: 'Nội quy',
            icon: Icons.rule_outlined,
            child: Text(room.houseRules!, style: const TextStyle(height: 1.5)),
          ),
        ],
      ],
    );
    return onRefresh == null
        ? content
        : RefreshIndicator(onRefresh: onRefresh!, child: content);
  }
}

class SharedRoomDetailTabView extends StatelessWidget {
  const SharedRoomDetailTabView({
    required this.room,
    this.onRefresh,
    this.trustLoading = false,
    this.trustError = false,
    this.onRetryTrust,
    this.onReport,
    super.key,
  });

  final SharedRoomDetailData room;
  final Future<void> Function()? onRefresh;
  final bool trustLoading, trustError;
  final VoidCallback? onRetryTrust, onReport;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        _tab([
          _Gallery(urls: room.imageUrls),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  room.title,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _Status(status: room.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${formatVnd(room.priceMonthly)}/tháng',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF00856F),
            ),
          ),
          if (room.estimatedMonthlyCost case final estimated?
              when estimated > 0) ...[
            const SizedBox(height: 5),
            Text(
              'Chi phí dự kiến: ${formatVnd(estimated)}/tháng',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF667571),
              ),
            ),
          ],
          const SizedBox(height: 14),
          _Card(
            child: Row(
              children: [
                Expanded(
                  child: _Fact(
                    Icons.square_foot_rounded,
                    '${_decimal(room.areaM2)} m²',
                  ),
                ),
                const _Divider(),
                Expanded(
                  child: _Fact(
                    Icons.layers_outlined,
                    room.floor == null ? 'Chưa rõ tầng' : 'Tầng ${room.floor}',
                  ),
                ),
                const _Divider(),
                Expanded(
                  child: _Fact(
                    Icons.people_alt_outlined,
                    '${room.maxPeople} người',
                  ),
                ),
              ],
            ),
          ),
          if (room.address.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Location(
              address: room.address,
              latitude: room.latitude,
              longitude: room.longitude,
            ),
          ],
          if (room.rejectionReason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _Notice(text: 'Lý do từ chối: ${room.rejectionReason}'),
          ],
          if (room.availableDate != null ||
              room.lastConfirmedAt != null ||
              room.viewsCount > 0) ...[
            const SizedBox(height: 14),
            _Meta(room: room),
          ],
          if (room.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _Section(
              title: 'Mô tả',
              icon: Icons.description_outlined,
              child: Text(
                room.description!,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ],
          if (room.houseRules?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _Section(
              title: 'Nội quy',
              icon: Icons.rule_outlined,
              child: Text(
                room.houseRules!,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ],
          if (room.trust != null || trustLoading || trustError) ...[
            const SizedBox(height: 14),
            _TrustCard(
              trust: room.trust,
              loading: trustLoading,
              hasError: trustError,
              onRetry: onRetryTrust,
              onReport: onReport,
            ),
          ],
        ]),
        _tab([
          _Section(
            title: 'Hình ảnh phòng (${room.imageUrls.length})',
            icon: Icons.photo_library_outlined,
            child: room.imageUrls.isEmpty
                ? const Text('Chưa cập nhật hình ảnh.')
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: room.imageUrls.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.2,
                        ),
                    itemBuilder: (_, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        room.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFE7F3F0),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
          ),
          if (room.videoUrls.isNotEmpty) ...[
            const SizedBox(height: 14),
            _VideoSection(urls: room.videoUrls),
          ],
        ]),
        _tab([_Amenities(items: room.amenities)]),
        _tab([_Costs(room: room)]),
      ],
    );
  }

  Widget _tab(List<Widget> children) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
      children: children,
    );
    return onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

class SharedRoomDetailTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SharedRoomDetailTabBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(49);

  @override
  Widget build(BuildContext context) {
    return const TabBar(
      labelColor: Color(0xFF00856F),
      unselectedLabelColor: Color(0xFF687571),
      indicatorColor: Color(0xFF00A889),
      indicatorWeight: 3,
      dividerColor: Color(0xFFE3EBE8),
      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      tabs: [
        Tab(text: 'Thông tin'),
        Tab(text: 'Hình ảnh'),
        Tab(text: 'Tiện ích'),
        Tab(text: 'Chi phí'),
      ],
    );
  }
}

class _VideoSection extends StatelessWidget {
  const _VideoSection({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) => _Section(
    title: 'Video phòng (${urls.length})',
    icon: Icons.play_circle_outline_rounded,
    child: Column(
      children: [
        for (var index = 0; index < urls.length; index++) ...[
          NetworkVideoPlayer(key: ValueKey(urls[index]), url: urls[index]),
          if (index < urls.length - 1) const SizedBox(height: 12),
        ],
      ],
    ),
  );
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.urls});
  final List<String> urls;
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int index = 0;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      height: 235,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.urls.isEmpty)
            const ColoredBox(
              color: Color(0xFFE7F3F0),
              child: Icon(
                Icons.home_work_outlined,
                size: 70,
                color: Color(0xFF78A79C),
              ),
            )
          else
            PageView.builder(
              itemCount: widget.urls.length,
              onPageChanged: (value) => setState(() => index = value),
              itemBuilder: (_, i) => Image.network(
                widget.urls[i],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFE7F3F0),
                  child: Icon(Icons.broken_image_outlined, size: 50),
                ),
              ),
            ),
          if (widget.urls.isNotEmpty)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${index + 1}/${widget.urls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Location extends StatelessWidget {
  const _Location({required this.address, this.latitude, this.longitude});
  final String address;
  final double? latitude, longitude;

  Future<void> _openGoogleMaps(BuildContext context) async {
    final query = latitude != null && longitude != null
        ? '$latitude,$longitude'
        : address;
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Không thể mở Google Maps.')));
  }

  @override
  Widget build(BuildContext context) => _Card(
    onTap: () => _openGoogleMaps(context),
    color: const Color(0xFFF0FAF7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.location_on_rounded, color: Color(0xFF00856F)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vị trí phòng',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                address,
                style: const TextStyle(height: 1.4, color: Color(0xFF687571)),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Icon(
            Icons.open_in_new_rounded,
            size: 19,
            color: Color(0xFF00856F),
          ),
        ),
      ],
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.room});
  final SharedRoomDetailData room;
  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      children: [
        if (room.availableDate != null)
          _MetaRow(
            Icons.event_available_outlined,
            'Có thể vào ở',
            _date(room.availableDate!),
          ),
        if (room.lastConfirmedAt != null)
          _MetaRow(
            Icons.verified_outlined,
            'Xác nhận còn trống',
            _date(room.lastConfirmedAt!),
          ),
        if (room.viewsCount > 0)
          _MetaRow(Icons.visibility_outlined, 'Lượt xem', '${room.viewsCount}'),
      ],
    ),
  );
}

class _Costs extends StatelessWidget {
  const _Costs({required this.room});
  final SharedRoomDetailData room;
  @override
  Widget build(BuildContext context) {
    final values = <String, int>{
      'Tiền thuê': room.priceMonthly,
      'Tiền cọc': room.depositAmount,
      ...room.costs,
    };
    return _Section(
      title: 'Chi phí',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        children: values.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key)),
                    Text(
                      formatVnd(e.value),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard({
    required this.trust,
    required this.loading,
    required this.hasError,
    this.onRetry,
    this.onReport,
  });

  final RoomTrust? trust;
  final bool loading, hasError;
  final VoidCallback? onRetry, onReport;

  @override
  Widget build(BuildContext context) {
    if (loading && trust == null) {
      return const _Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (hasError && trust == null) {
      return _Card(
        child: Row(
          children: [
            const Expanded(child: Text('Không thể tải độ tin cậy của tin đăng.')),
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final value = trust!;
    final scoreColor = value.score >= 75
        ? const Color(0xFF00A884)
        : value.score >= 50
        ? const Color(0xFFF0B429)
        : const Color(0xFFE85D4A);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIN CẬY TRỌSV',
                      style: TextStyle(
                        color: Color(0xFFE11D2E),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .3,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Kiểm tra trước khi liên hệ',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor.withValues(alpha: .6), width: 6),
                ),
                child: Text(
                  '${value.score}',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final signal in value.signals) _TrustSignalRow(signal: signal),
          if (value.advice.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                value.advice.join('\n'),
                style: const TextStyle(height: 1.55, color: Color(0xFF374151)),
              ),
            ),
          ],
          if (onReport != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.outlined_flag_rounded, size: 19),
                label: const Text('Báo cáo dấu hiệu bất thường'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFD71920)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrustSignalRow extends StatelessWidget {
  const _TrustSignalRow({required this.signal});
  final TrustSignal signal;

  @override
  Widget build(BuildContext context) {
    final good = signal.status.toLowerCase() == 'good';
    final color = good ? const Color(0xFF00A884) : const Color(0xFFFF7A00);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            good ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
            size: 21,
            color: color,
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(signal.label, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

class _Amenities extends StatelessWidget {
  const _Amenities({required this.items});
  final List<String> items;
  @override
  Widget build(BuildContext context) => _Section(
    title: 'Tiện ích',
    icon: Icons.weekend_outlined,
    child: items.isEmpty
        ? const Text('Chưa cập nhật tiện ích.')
        : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: .95,
            ),
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDCE6E3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_icon(items[i]), color: const Color(0xFF00856F)),
                  const SizedBox(height: 5),
                  Text(
                    items[i],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00856F)),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.color = Colors.white, this.onTap});
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFDCE6E3)),
        ),
        child: child,
      ),
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final good = status == 'PUBLISHED';
    final color = good ? const Color(0xFF00856F) : const Color(0xFF6D7976);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _status(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => _Card(
    color: const Color(0xFFFFF0F0),
    child: Text(text, style: const TextStyle(color: Color(0xFF8D3B3B))),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: const Color(0xFFE8EEEC));
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: const Color(0xFF00856F)),
      const SizedBox(height: 5),
      Text(
        text,
        maxLines: 1,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF00856F)),
        const SizedBox(width: 9),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

String _decimal(double value) =>
    value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _status(String value) => switch (value) {
  'PUBLISHED' => 'Đang còn phòng',
  'RENTED' => 'Đã cho thuê',
  'HIDDEN' => 'Đang ẩn',
  'PENDING_REVIEW' => 'Chờ duyệt',
  'DRAFT' => 'Bản nháp',
  'REJECTED' => 'Bị từ chối',
  _ => value,
};
IconData _icon(String value) {
  final text = value.toLowerCase();
  if (text.contains('wifi')) return Icons.wifi;
  if (text.contains('điều hòa')) return Icons.ac_unit;
  if (text.contains('máy giặt')) return Icons.local_laundry_service_outlined;
  if (text.contains('tủ lạnh')) return Icons.kitchen_outlined;
  if (text.contains('thang máy')) return Icons.elevator_outlined;
  if (text.contains('ban công')) return Icons.balcony_outlined;
  if (text.contains('giường')) return Icons.bed_outlined;
  if (text.contains('camera')) return Icons.videocam_outlined;
  if (text.contains('xe')) return Icons.two_wheeler_outlined;
  return Icons.check_circle_outline_rounded;
}
