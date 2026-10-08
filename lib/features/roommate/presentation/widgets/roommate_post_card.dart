import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/roommate_post.dart';

//
// COLORS
//
const _greenDark = Color(0xFF007B64);

const _textPrimary = Color(0xFF17211F);
const _textSecondary = Color(0xFF687571);

const _cardBackground = Colors.white;
const _border = Color(0xFFE1EAE7);

class RoommatePostCard extends StatelessWidget {
  const RoommatePostCard({
    required this.post,
    this.showStatus = false,
    this.onTap,
    this.trailing,
    super.key,
  });

  final RoommatePost post;

  /// Hiển thị trạng thái:
  /// ACTIVE / PENDING_REVIEW / REJECTED / CLOSED
  ///
  /// Thường dùng tại màn "Tin của tôi".
  final bool showStatus;

  final VoidCallback? onTap;

  /// Ví dụ PopupMenuButton dấu ba chấm.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

        //
        // Điện thoại nhỏ hoặc người dùng tăng cỡ chữ
        //
        final isCompact = constraints.maxWidth < 350 || textScale > 1.05;

        //
        // Ảnh cố tình cao hơn chiều rộng
        // để card nhìn cân và hiện đại hơn.
        //
        final imageWidth = isCompact ? 90.0 : 98.0;
        final imageHeight = isCompact ? 122.0 : 132.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x09000000),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(17),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //
                    // =====================================================
                    // MAIN CONTENT
                    // =====================================================
                    //
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //
                        // IMAGE
                        //
                        _PostImage(
                          url: post.thumbnailUrl,
                          type: post.postType,
                          width: imageWidth,
                          height: imageHeight,
                        ),

                        const SizedBox(width: 11),

                        //
                        // TEXT CONTENT
                        //
                        Expanded(
                          child: _PostContent(
                            post: post,
                            trailing: trailing,
                            isCompact: isCompact,
                          ),
                        ),
                      ],
                    ),

                    //
                    // =====================================================
                    // STATUS
                    // =====================================================
                    //
                    if (showStatus) ...[
                      const SizedBox(height: 9),
                      _PostStatus(status: post.status),
                    ],

                    //
                    // =====================================================
                    // REJECTION REASON
                    // =====================================================
                    //
                    if (post.isRejected &&
                        post.rejectionReason?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      _RejectedBox(reason: post.rejectionReason!.trim()),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

//
// ==========================================================================
// MAIN CONTENT
// ==========================================================================
//

class _PostContent extends StatelessWidget {
  const _PostContent({
    required this.post,
    required this.trailing,
    required this.isCompact,
  });

  final RoommatePost post;
  final Widget? trailing;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //
        // TITLE + MENU
        //
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 13.4 : 14.2,
                  height: 1.22,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
            ),

            if (trailing != null) ...[
              const SizedBox(width: 3),

              SizedBox(width: 30, height: 30, child: Center(child: trailing!)),
            ],
          ],
        ),

        //
        // PRICE
        //
        const SizedBox(height: 7),

        Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 17,
              color: _greenDark,
            ),

            const SizedBox(width: 6),

            Expanded(
              child: Text(
                '${formatVnd(post.budgetPerPerson)} đ/người/tháng',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 12.2 : 13,
                  height: 1.15,
                  color: _greenDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),

        //
        // ADDRESS
        //
        const SizedBox(height: 8),

        _InfoLine(
          icon: Icons.location_on_outlined,
          text: _buildAddress(post),
          fontSize: isCompact ? 10.4 : 10.8,
        ),

        //
        // PEOPLE + DATE
        //
        const SizedBox(height: 7),

        Row(
          children: [
            Expanded(
              child: _InfoLine(
                icon: Icons.group_outlined,
                text: 'Cần ${post.desiredRoommates} người',
                fontSize: isCompact ? 10.2 : 10.7,
              ),
            ),

            const SizedBox(width: 6),

            Container(width: 1, height: 17, color: const Color(0xFFDDE5E2)),

            const SizedBox(width: 7),

            Expanded(
              child: _InfoLine(
                icon: Icons.calendar_today_outlined,
                text: _formatDate(post.moveInDate),
                fontSize: isCompact ? 9.8 : 10.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

//
// ==========================================================================
// IMAGE
// ==========================================================================
//

class _PostImage extends StatelessWidget {
  const _PostImage({
    required this.url,
    required this.type,
    required this.width,
    required this.height,
  });

  final String? url;
  final String type;

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasRoom = type == 'HAVE_ROOM_FIND_MATE' || type == 'HAVE_ROOM';

    final label = hasRoom ? 'Đã có phòng' : 'Cùng tìm phòng';

    final chipColor = hasRoom
        ? const Color(0xFF007F67)
        : const Color(0xFF177F94);

    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            //
            // IMAGE
            //
            if (url?.trim().isNotEmpty == true)
              CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 160),
                placeholder: (_, _) => const ColoredBox(
                  color: Color(0xFFE7EFED),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => const _ImageFallback(broken: true),
              )
            else
              const _ImageFallback(),

            //
            // GRADIENT NHẸ PHÍA DƯỚI
            //
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 44,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            //
            // CHIP MỜ TRÊN ẢNH
            //
            Positioned(
              left: 6,
              right: 6,
              bottom: 7,
              child: Container(
                height: 27,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: chipColor,
                    fontSize: 9,
                    height: 1,
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
}

//
// ==========================================================================
// IMAGE FALLBACK
// ==========================================================================
//

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.broken = false});

  final bool broken;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE4F3EF),
      child: Center(
        child: Icon(
          broken ? Icons.broken_image_outlined : Icons.groups_rounded,
          size: broken ? 28 : 36,
          color: const Color(0xFF72A99C),
        ),
      ),
    );
  }
}

//
// ==========================================================================
// INFO LINE
// ==========================================================================
//

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    required this.fontSize,
  });

  final IconData icon;
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14.5, color: _textSecondary),

        const SizedBox(width: 5),

        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.2,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

//
// ==========================================================================
// STATUS
// ==========================================================================
//

class _PostStatus extends StatelessWidget {
  const _PostStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      width: double.infinity,
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.foreground),

          const SizedBox(width: 6),

          Text(
            config.label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 10.5,
              height: 1,
              fontWeight: FontWeight.w700,
              color: config.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

typedef _StatusConfig = ({
  String label,
  Color foreground,
  Color background,
  IconData icon,
});

_StatusConfig _statusConfig(String status) {
  return switch (status) {
    'ACTIVE' => (
      label: 'Đang hiển thị',
      foreground: const Color(0xFF007D65),
      background: const Color(0xFFE6F6F1),
      icon: Icons.visibility_outlined,
    ),

    'PENDING_REVIEW' => (
      label: 'Chờ duyệt',
      foreground: const Color(0xFFC47A00),
      background: const Color(0xFFFFF3DE),
      icon: Icons.schedule_rounded,
    ),

    'REJECTED' => (
      label: 'Bị từ chối',
      foreground: const Color(0xFFD84B4B),
      background: const Color(0xFFFFEEEE),
      icon: Icons.error_outline_rounded,
    ),

    'CLOSED' => (
      label: 'Đã đóng',
      foreground: const Color(0xFF64736F),
      background: const Color(0xFFF0F3F2),
      icon: Icons.lock_outline_rounded,
    ),

    _ => (
      label: status,
      foreground: const Color(0xFF64736F),
      background: const Color(0xFFF0F3F2),
      icon: Icons.info_outline_rounded,
    ),
  };
}

//
// ==========================================================================
// REJECTION BOX
// ==========================================================================
//

class _RejectedBox extends StatelessWidget {
  const _RejectedBox({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD7D7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: Color(0xFFE5484D),
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Text(
              'Lý do: $reason',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.3,
                color: Color(0xFFD84449),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//
// ==========================================================================
// HELPERS
// ==========================================================================
//

String _buildAddress(RoommatePost post) {
  final parts = <String>[];

  final ward = post.ward?.trim();

  final district = post.district.trim();

  final province = post.province.trim();

  if (ward?.isNotEmpty == true) {
    parts.add(ward!);
  }

  if (district.isNotEmpty) {
    parts.add(district);
  }

  if (province.isNotEmpty) {
    parts.add(province);
  }

  return parts.join(', ');
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');

  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
