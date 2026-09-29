import 'package:dio/dio.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_data_source.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  const AppointmentRepositoryImpl(this._remote);
  final AppointmentRemoteDataSource _remote;
  @override
  Future<Appointment> create({
    required String roomId,
    required String tenantName,
    required String tenantPhone,
    required DateTime bookingDate,
    required String timeSlot,
    String? tenantZalo,
    String? note,
    required String idempotencyKey,
  }) => _execute(
    () => _remote.create({
      'room_id': roomId,
      'tenant_name': tenantName.trim(),
      'tenant_phone': tenantPhone.trim(),
      'tenant_zalo': _nullIfEmpty(tenantZalo),
      'booking_date': _date(bookingDate),
      'time_slot': timeSlot.trim(),
      'note': _nullIfEmpty(note),
    }, idempotencyKey: idempotencyKey),
  );
  @override
  Future<List<Appointment>> getMine() => _execute(_remote.getMine);
  @override
  Future<List<Appointment>> getLandlordAppointments() =>
      _execute(_remote.getLandlordAppointments);
  @override
  Future<Appointment> cancel(String appointmentId) =>
      _execute(() => _remote.cancel(appointmentId));
  @override
  Future<Appointment> reschedule(
    String appointmentId, {
    required DateTime bookingDate,
    required String timeSlot,
  }) => _execute(
    () => _remote.reschedule(appointmentId, {
      'booking_date': _date(bookingDate),
      'time_slot': timeSlot.trim(),
    }),
  );
  @override
  Future<Appointment> updateStatus(
    String appointmentId, {
    required String status,
    String? note,
  }) => _execute(
    () => _remote.updateStatus(appointmentId, {
      'status': status,
      'note': _nullIfEmpty(note),
    }),
  );
  Future<T> _execute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (error) {
      throw AppointmentFailure(_dioMessage(error));
    } on FormatException catch (error) {
      throw AppointmentFailure(error.message);
    } on TypeError {
      throw const AppointmentFailure(
        'Dữ liệu lịch hẹn từ máy chủ không hợp lệ.',
      );
    }
  }
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String? _nullIfEmpty(String? value) =>
    value == null || value.trim().isEmpty ? null : value.trim();
String _dioMessage(DioException error) {
  final body = error.response?.data;
  if (body is Map<String, dynamic>) {
    final apiError = body['error'];
    if (apiError is Map<String, dynamic> && apiError['message'] is String) {
      return apiError['message'] as String;
    }
    if (body['message'] is String) {
      return body['message'] as String;
    }
    final detail = body['detail'];
    if (detail is List &&
        detail.isNotEmpty &&
        detail.first is Map &&
        (detail.first as Map)['msg'] is String) {
      return (detail.first as Map)['msg'] as String;
    }
  }
  return switch (error.response?.statusCode) {
    401 => 'Bạn cần đăng nhập lại.',
    403 => 'Bạn không có quyền thực hiện thao tác này.',
    404 => 'Không tìm thấy lịch hẹn.',
    409 => 'Khung giờ này đã được đặt hoặc lịch hẹn bị trùng.',
    _ => 'Không thể kết nối dịch vụ lịch hẹn.',
  };
}
