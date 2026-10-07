import 'package:flutter_test/flutter_test.dart';
import 'package:trosv_app/features/rooms/domain/entities/room_detail.dart';

void main() {
  Map<String, dynamic> roomJson({Map<String, dynamic>? overrides}) => {
    'id': 'room-1',
    'title': 'Phòng mẫu',
    'room_type': 'ROOM_SINGLE',
    'area_m2': 25,
    'max_people': 2,
    'price_monthly': 3500000,
    'deposit_amount': 3500000,
    'status': 'PUBLISHED',
    ...?overrides,
  };

  test('ưu tiên chi phí dự kiến do API trả về', () {
    final room = RoomDetail.fromJson(
      roomJson(overrides: {'estimated_monthly_cost': 4100000}),
    );

    expect(room.estimatedMonthlyCost, 4100000);
  });

  test('tính dự kiến từ tiền thuê và các phí cố định khi API chưa trả', () {
    final room = RoomDetail.fromJson(
      roomJson(
        overrides: {
          'cost': {
            'electricity_price': 4300,
            'water_price': 35000,
            'internet_fee': 100000,
            'parking_fee': 20000,
            'service_fee': 30000,
            'cleaning_fee': 30000,
            'other_fee': 0,
          },
        },
      ),
    );

    expect(room.estimatedMonthlyCost, 3680000);
  });
}
