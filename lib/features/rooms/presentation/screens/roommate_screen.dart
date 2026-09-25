import 'package:flutter/material.dart';

class RoommateScreen extends StatelessWidget {
  const RoommateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F8F7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFE2F6F1),
                  child: Icon(
                    Icons.group_outlined,
                    size: 42,
                    color: Color(0xFF008E79),
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Tìm người ở ghép',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'Chức năng đăng và tìm tin ở ghép đang được phát triển.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF687571), height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
