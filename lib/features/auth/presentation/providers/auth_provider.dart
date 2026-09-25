import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/session_expiry_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/send_otp_result.dart';
import '../../domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource(ref.watch(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
  );
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthSession?> build() {
    ref.listen(sessionExpiryProvider, (previous, next) {
      if (previous != null && next > previous) {
        state = const AsyncData(null);
      }
    });
    return _repository.restoreSession();
  }

  Future<bool> login({required String phone, required String password}) async {
    state = const AsyncLoading();
    try {
      final session = await _repository.login(phone: phone, password: password);
      state = AsyncData(session);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<SendOtpResult?> sendOtp(String phone) async {
    final previous = state;
    state = const AsyncLoading();
    try {
      final result = await _repository.sendOtp(phone);
      state = previous.hasValue
          ? AsyncData(previous.value)
          : const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String otp,
    required String password,
    required String role,
  }) async {
    state = const AsyncLoading();
    try {
      final session = await _repository.register(
        name: name,
        phone: phone,
        email: email,
        otp: otp,
        password: password,
        role: role,
      );
      state = AsyncData(session);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> switchActiveMode(String activeMode) async {
    final currentSession = state.asData?.value;

    if (currentSession == null) {
      return false;
    }

    if (!currentSession.user.roles.contains(activeMode)) {
      state = AsyncError(
        StateError('Tài khoản không được cấp vai trò này.'),
        StackTrace.current,
      );

      return false;
    }

    state = const AsyncLoading();

    try {
      final session = await _repository.switchActiveMode(activeMode);

      state = AsyncData(session);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> refreshProfile() async {
    final previous = state.asData?.value;
    if (previous == null) return false;

    state = const AsyncLoading();
    try {
      final session = await _repository.getMyProfile();
      state = AsyncData(session);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String zaloPhone,
    required String avatarUrl,
  }) async {
    final previous = state.asData?.value;
    if (previous == null) return false;

    state = const AsyncLoading();
    try {
      final session = await _repository.updateMyProfile(
        name: name,
        zaloPhone: zaloPhone,
        avatarUrl: avatarUrl,
      );
      state = AsyncData(session);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String filename,
  }) {
    return _repository.uploadProfileImage(bytes: bytes, filename: filename);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }

  Future<void> logout() async {
    await _repository.clearSession();
    state = const AsyncData(null);
  }
}
