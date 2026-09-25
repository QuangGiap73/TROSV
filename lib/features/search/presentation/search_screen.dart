import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm phòng')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const TextField(
            decoration: InputDecoration(
              hintText: 'Khu vực, tên đường hoặc tên phòng',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.tune),
            label: const Text('Bộ lọc tìm kiếm'),
          ),
          const SizedBox(height: 48),
          Icon(
            Icons.home_work_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Bắt đầu tìm phòng',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Kết quả API sẽ xuất hiện sau khi cấu hình địa chỉ server.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
