import 'package:flutter/material.dart';

class LandlordAppointmentsScreen extends StatelessWidget {
  const LandlordAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch hẹn xem phòng')),
      body: const Center(
        child: Text(
          'Lịch hẹn của chủ trọ sẽ được hiển thị tại đây.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
