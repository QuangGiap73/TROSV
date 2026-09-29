import '../entities/appointment.dart';

abstract interface class AppointmentRepository {
  Future<Appointment> create({
    required String roomId,
    required String tenantName,
    required String tenantPhone,
    required DateTime bookingDate,
    required String timeSlot,
    String? tenantZalo,
    String? note,
    required String idempotencyKey,
  });
  Future<List<Appointment>> getMine();
  Future<List<Appointment>> getLandlordAppointments();
  Future<Appointment> cancel(String appointmentId);
  Future<Appointment> reschedule(
    String appointmentId, {
    required DateTime bookingDate,
    required String timeSlot,
  });
  Future<Appointment> updateStatus(
    String appointmentId, {
    required String status,
    String? note,
  });
}

class AppointmentFailure implements Exception {
  const AppointmentFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
