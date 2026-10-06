import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/appointment_remote_data_source.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';

final appointmentRemoteDataSourceProvider = Provider(
  (ref) => AppointmentRemoteDataSource(ref.watch(dioProvider)),
);
final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (ref) =>
      AppointmentRepositoryImpl(ref.watch(appointmentRemoteDataSourceProvider)),
);
final myAppointmentsProvider = FutureProvider.autoDispose<List<Appointment>>(
  (ref) {
    final userId = ref.watch(
      authControllerProvider.select((state) => state.asData?.value?.user.id),
    );
    if (userId == null) return const <Appointment>[];
    return ref.watch(appointmentRepositoryProvider).getMine();
  },
);
final landlordAppointmentsProvider =
    FutureProvider.autoDispose<List<Appointment>>(
      (ref) {
        final userId = ref.watch(
          authControllerProvider.select(
            (state) => state.asData?.value?.user.id,
          ),
        );
        if (userId == null) return const <Appointment>[];
        return ref
            .watch(appointmentRepositoryProvider)
            .getLandlordAppointments();
      },
    );
final appointmentActionProvider =
    AsyncNotifierProvider<AppointmentActionController, void>(
      AppointmentActionController.new,
    );

class AppointmentActionController extends AsyncNotifier<void> {
  AppointmentRepository get _repository =>
      ref.read(appointmentRepositoryProvider);
  @override
  FutureOr<void> build() {
    ref.watch(
      authControllerProvider.select((state) => state.asData?.value?.user.id),
    );
  }

  Future<Appointment?> create({
    required String roomId,
    required String tenantName,
    required String tenantPhone,
    required DateTime bookingDate,
    required String timeSlot,
    String? tenantZalo,
    String? note,
  }) => _run(
    () => _repository.create(
      roomId: roomId,
      tenantName: tenantName,
      tenantPhone: tenantPhone,
      bookingDate: bookingDate,
      timeSlot: timeSlot,
      tenantZalo: tenantZalo,
      note: note,
      idempotencyKey: '$roomId-${DateTime.now().microsecondsSinceEpoch}',
    ),
  );
  Future<Appointment?> cancel(String id) => _run(() => _repository.cancel(id));
  Future<Appointment?> reschedule(
    String id, {
    required DateTime bookingDate,
    required String timeSlot,
  }) => _run(
    () => _repository.reschedule(
      id,
      bookingDate: bookingDate,
      timeSlot: timeSlot,
    ),
  );
  Future<Appointment?> updateStatus(
    String id, {
    required String status,
    String? note,
  }) => _run(() => _repository.updateStatus(id, status: status, note: note));

  Future<Appointment?> _run(Future<Appointment> Function() operation) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      final result = await operation();
      state = const AsyncData(null);
      ref.invalidate(myAppointmentsProvider);
      ref.invalidate(landlordAppointmentsProvider);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}
