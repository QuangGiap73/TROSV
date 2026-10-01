import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/roommate_post.dart';
import 'roommate_status_badge.dart';

class RoommatePostCard extends StatelessWidget {
  const RoommatePostCard({
    required this.post,
    this.showStatus = false,
    this.onTap,
    this.trailing,
    super.key,
  });

  final RoommatePost post;
  final bool showStatus;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE1EAE7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PostImage(url: post.thumbnailUrl),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _PostTypeBadge(type: post.postType),
                        const Spacer(),
                        if (showStatus)
                          RoommateStatusBadge(status: post.status),
                        trailing ?? const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${formatVnd(post.budgetPerPerson)}/người/tháng',
                      style: const TextStyle(
                        color: Color(0xFF008F72),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _InfoLine(
                      icon: Icons.location_on_outlined,
                      text: [
                        if (post.ward != null) post.ward,
                        post.district,
                        post.province,
                      ].join(', '),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoLine(
                            icon: Icons.group_outlined,
                            text: 'Cần ${post.desiredRoommates} người',
                          ),
                        ),
                        Expanded(
                          child: _InfoLine(
                            icon: Icons.calendar_today_outlined,
                            text: _formatDate(post.moveInDate),
                          ),
                        ),
                      ],
                    ),
                    if (post.isRejected && post.rejectionReason != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        'Lý do: ${post.rejectionReason}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE5484D),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
        width: 105,
        height: 120,
        child: url == null
            ? const ColoredBox(
                color: Color(0xFFE4F4F0),
                child: Icon(
                  Icons.groups_rounded,
                  size: 37,
                  color: Color(0xFF75A89C),
                ),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return const ColoredBox(
                    color: Color(0xFFE4F4F0),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF75A89C),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _PostTypeBadge extends StatelessWidget {
  const _PostTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final hasRoom = type == 'HAVE_ROOM_FIND_MATE' || type == 'HAVE_ROOM';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasRoom ? const Color(0xFFE0F5EB) : const Color(0xFFE3F4F7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        hasRoom ? 'Đã có phòng' : 'Cùng tìm phòng',
        style: TextStyle(
          fontSize: 9,
          color: hasRoom ? const Color(0xFF008F72) : const Color(0xFF17849A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF687571)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF687571)),
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
