import 'package:flutter_test/flutter_test.dart';
import 'package:trosv_app/features/rooms/domain/entities/room_report.dart';

void main() {
  test('RoomReportRequest gửi đúng enum và bỏ mô tả rỗng', () {
    const request = RoomReportRequest(
      type: RoomReportType.wrongPrice,
      description: '   ',
    );

    expect(request.toJson(), {'type': 'WRONG_PRICE'});
  });

  test('RoomReport parse đúng response từ API', () {
    final report = RoomReport.fromJson({
      'id': 'report-id',
      'reporter_id': 'reporter-id',
      'room_id': 'room-id',
      'type': 'FRAUD',
      'description': 'Thông tin đáng ngờ',
      'status': 'OPEN',
      'resolved_by': null,
      'resolved_at': null,
      'created_at': '2026-10-05T10:30:00Z',
    });

    expect(report.id, 'report-id');
    expect(report.roomId, 'room-id');
    expect(report.type, 'FRAUD');
    expect(report.status, 'OPEN');
    expect(report.createdAt.toUtc(), DateTime.utc(2026, 10, 5, 10, 30));
  });
}
