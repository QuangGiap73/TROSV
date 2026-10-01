import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoommateCreateSuccessScreen extends StatelessWidget {
  const RoommateCreateSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 176,
                height: 176,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F8F3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  size: 92,
                  color: Color(0xFF00A889),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Đăng tin thành công!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bài đăng của bạn đã được gửi duyệt.\nChúng tôi sẽ thông báo khi có kết quả.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, color: Color(0xFF697672)),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => context.go('/roommate/mine'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00A889),
                  ),
                  child: const Text('Xem tin của tôi'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Về trang chủ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
