import 'package:flutter/material.dart';

class LandlordDashboardScreen extends StatelessWidget {
  const LandlordDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý TrọSV'),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Thông báo',
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Tổng quan chủ trọ',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('Quản lý phòng và lịch hẹn của bạn.'),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(
                child: _StatisticCard(
                  icon: Icons.home_work_outlined,
                  value: '0',
                  label: 'Tổng phòng',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatisticCard(
                  icon: Icons.pending_actions_outlined,
                  value: '0',
                  label: 'Chờ duyệt',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _StatisticCard(
                  icon: Icons.check_circle_outline,
                  value: '0',
                  label: 'Đang hiển thị',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatisticCard(
                  icon: Icons.calendar_month_outlined,
                  value: '0',
                  label: 'Lịch hẹn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // Sau này mở wizard đăng phòng.
            },
            icon: const Icon(Icons.add_home_outlined),
            label: const Text('Đăng phòng mới'),
          ),
        ],
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
