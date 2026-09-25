import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/room_match.dart';
import 'room_card.dart';

class RoomMatchCard extends StatelessWidget {
  const RoomMatchCard({
    required this.match,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoritePressed,
    super.key,
  });

  final RoomMatch match;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;

  Color _scoreColor() {
    if (match.matchScore >= 80) {
      return const Color(0xFF008E78);
    }

    if (match.matchScore >= 60) {
      return const Color(0xFFE58A00);
    }

    return const Color(0xFFDF5D52);
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: .09),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: scoreColor.withValues(alpha: .25)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scoreColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${match.matchScore}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mức độ phù hợp',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chi phí dự kiến: '
                      '${formatVnd(match.estimatedMonthlyCost)}/tháng',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        RoomCard(
          room: match.room,
          isFavorite: isFavorite,
          onTap: onTap,
          onFavoritePressed: onFavoritePressed,
        ),
        Card(
          margin: const EdgeInsets.only(top: 6),
          elevation: 0,
          color: Colors.white,
          child: ExpansionTile(
            title: const Text(
              'Vì sao phòng này phù hợp?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (match.reasons.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Backend chưa cung cấp lý do phù hợp.'),
                ),
              ...match.reasons.map(
                (reason) => _ReasonRow(
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF008E78),
                  text: reason,
                ),
              ),
              if (match.tradeoffs.isNotEmpty) ...[
                const Divider(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Điểm cần cân nhắc',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                ...match.tradeoffs.map(
                  (tradeoff) => _ReasonRow(
                    icon: Icons.info_outline,
                    color: const Color(0xFFE58A00),
                    text: tradeoff,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}
