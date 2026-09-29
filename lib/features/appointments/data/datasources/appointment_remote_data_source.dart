import 'package:dio/dio.dart';
import '../../domain/entities/appointment.dart';

class AppointmentRemoteDataSource {
  const AppointmentRemoteDataSource(this._dio);
  final Dio _dio;
  Future<Appointment> create(
    Map<String, dynamic> payload, {
    required String idempotencyKey,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/appointments',
      data: payload,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return Appointment.fromJson(_mapData(response));
  }

  Future<List<Appointment>> getMine() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/appointments/my',
    );
    return _listData(
      response,
    ).map(Appointment.fromJson).toList(growable: false);
  }

  Future<List<Appointment>> getLandlordAppointments() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/landlord/appointments',
    );
    return _listData(
      response,
    ).map(Appointment.fromJson).toList(growable: false);
  }

  Future<Appointment> cancel(String id) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/appointments/$id/cancel',
    );
    return Appointment.fromJson(_mapData(response));
  }

  Future<Appointment> reschedule(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/appointments/$id/reschedule',
      data: payload,
    );
    return Appointment.fromJson(_mapData(response));
  }

  Future<Appointment> updateStatus(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/landlord/appointments/$id/status',
      data: payload,
    );
    return Appointment.fromJson(_mapData(response));
  }
}

Map<String, dynamic> _mapData(Response<Map<String, dynamic>> response) {
  final envelope = response.data;
  final data = envelope?['data'];
  if (envelope?['success'] != true || data is! Map<String, dynamic>) {
    throw const FormatException('Dữ liệu lịch hẹn không đúng định dạng.');
  }
  return data;
}

List<Map<String, dynamic>> _listData(Response<Map<String, dynamic>> response) {
  final envelope = response.data;
  final data = envelope?['data'];
  if (envelope?['success'] != true || data is! List) {
    throw const FormatException('Danh sách lịch hẹn không đúng định dạng.');
  }
  return data.whereType<Map<String, dynamic>>().toList(growable: false);
}
