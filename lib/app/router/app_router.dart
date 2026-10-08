import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/role_landing_screen.dart';
import '../../features/appointments/presentation/screens/create_appointment_screen.dart';
import '../../features/appointments/presentation/screens/appointment_detail_screen.dart';
import '../../features/appointments/presentation/screens/tenant_appointments_screen.dart';
import '../../features/appointments/domain/entities/appointment.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/landlord/appointments/presentation/landlord_appointments_screen.dart';
import '../../features/landlord/appointments/presentation/landlord_appointment_detail_screen.dart';
import '../../features/landlord/dashboard/presentation/landlord_dashboard_screen.dart';
import '../../features/landlord/profile/presentation/landlord_profile_screen.dart';
import '../../features/landlord/rooms/presentation/screens/landlord_rooms_screen.dart';
import '../../features/landlord/rooms/presentation/screens/landlord_room_detail_screen.dart';
import '../../features/landlord/rooms/presentation/screens/landlord_room_overview_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/preferences/presentation/screens/preference_chat_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/location_settings_screen.dart';
import '../../features/profile/presentation/personal_info_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/rooms/presentation/screens/room_detail_screen.dart';
import '../../features/rooms/presentation/screens/room_map_screen.dart';
import '../../features/rooms/presentation/screens/room_match_screen.dart';
import '../../features/rooms/domain/entities/room_search_query.dart';
import '../../features/rooms/domain/entities/room_map_args.dart';
import '../../features/roommate/presentation/screens/roommate_posts_screen.dart';
import '../../features/roommate/presentation/screens/create_roommate_post_screen.dart';
import '../../features/roommate/presentation/screens/my_roommate_posts_screen.dart';
import '../../features/roommate/presentation/screens/roommate_post_detail_screen.dart';
import '../../features/roommate/presentation/screens/roommate_create_success_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/landlord/rooms/presentation/create_room/landlord_create_room_screen.dart';
import '../shell/app_shell.dart';
import '../shell/landlord_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (_, _) => const RoleLandingScreen()),
      // Tenant shell
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (_, state) {
                  final query = state.uri.queryParameters;
                  final latitude = double.tryParse(query['lat'] ?? '');
                  final longitude = double.tryParse(query['lng'] ?? '');
                  final radius = int.tryParse(query['radius'] ?? '');
                  return SearchScreen(
                    title: query['title'] ?? 'Tìm trọ',
                    mapFocusLabel: query['focus'],
                    initialQuery: RoomSearchQuery(
                      latitude: latitude,
                      longitude: longitude,
                      radiusMeters: radius,
                      sort: latitude != null && longitude != null
                          ? 'DISTANCE'
                          : 'RELEVANCE',
                      page: 1,
                      limit: latitude != null && longitude != null ? 20 : 50,
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/map', builder: (_, _) => const RoomMapScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/roommate',
                builder: (_, _) => const RoommatePostsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
      GoRoute(
        path: '/roommate/create',
        builder: (_, _) => const CreateRoommatePostScreen(),
      ),
      GoRoute(
        path: '/roommate/create/success',
        builder: (_, _) => const RoommateCreateSuccessScreen(),
      ),
      GoRoute(
        path: '/roommate/mine',
        builder: (_, _) => const MyRoommatePostsScreen(),
      ),
      GoRoute(
        path: '/roommate/posts/:postId',
        builder: (_, state) {
          final postId = state.pathParameters['postId'];
          if (postId == null || postId.isEmpty) {
            throw StateError('Thiếu mã bài đăng ở ghép.');
          }
          return RoommatePostDetailScreen(postId: postId);
        },
      ),
      // Landlord shell
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            LandlordShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/landlord',
                builder: (_, _) => const LandlordDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/landlord/rooms',
                builder: (_, _) => const LandlordRoomsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/landlord/appointments',
                builder: (_, _) => const LandlordAppointmentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/landlord/profile',
                builder: (_, _) => const LandlordProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Màn đăng phòng mở full-screen, không giữ bottom navigation.
      GoRoute(
        path: '/landlord/rooms/create',
        builder: (_, _) => const LandlordCreateRoomScreen(),
      ),
      GoRoute(
        path: '/landlord/rooms/:roomId/edit',
        builder: (_, state) {
          final roomId = state.pathParameters['roomId'];
          if (roomId == null || roomId.isEmpty) {
            throw StateError('Thiếu mã phòng.');
          }
          return LandlordCreateRoomScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/landlord/rooms/:roomId',
        builder: (_, state) {
          final roomId = state.pathParameters['roomId'];
          if (roomId == null || roomId.isEmpty) {
            throw StateError('Thiếu mã phòng.');
          }
          return LandlordRoomOverviewScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/landlord/rooms/:roomId/detail',
        builder: (_, state) {
          final roomId = state.pathParameters['roomId'];
          if (roomId == null || roomId.isEmpty) {
            throw StateError('Thiếu mã phòng.');
          }
          return LandlordRoomDetailScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/landlord/appointments/:appointmentId',
        builder: (_, state) {
          final appointment = state.extra;
          if (appointment is! Appointment) {
            throw StateError(
              'Thiếu dữ liệu lịch hẹn. Hãy mở lịch từ danh sách.',
            );
          }
          return LandlordAppointmentDetailScreen(appointment: appointment);
        },
      ),
      GoRoute(
        path: '/appointments/create',
        builder: (_, state) {
          final roomId = state.uri.queryParameters['roomId'];
          if (roomId == null || roomId.isEmpty) {
            throw StateError('Thiếu mã phòng.');
          }
          return CreateAppointmentScreen(
            roomId: roomId,
            roomTitle: state.uri.queryParameters['roomTitle'],
          );
        },
      ),
      GoRoute(
        path: '/profile/appointments',
        builder: (_, _) => const TenantAppointmentsScreen(),
      ),
      GoRoute(
        path: '/profile/appointments/:appointmentId',
        builder: (_, state) {
          final appointment = state.extra;
          if (appointment is! Appointment) {
            throw StateError(
              'Thiếu dữ liệu lịch hẹn. Hãy mở lịch từ danh sách.',
            );
          }
          return AppointmentDetailScreen(appointment: appointment);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/rooms/matches',
        builder: (_, _) => const RoomMatchScreen(),
      ),
      GoRoute(
        path: '/rooms/map',
        builder: (_, state) {
          final extra = state.extra;
          return RoomMapScreen(
            initialQuery: extra is RoomMapArgs
                ? extra.query
                : extra is RoomSearchQuery
                ? extra
                : null,
            initialFocusLabel: extra is RoomMapArgs ? extra.focusLabel : null,
          );
        },
      ),
      GoRoute(
        path: '/rooms/:roomId',
        builder: (_, state) {
          final roomId = state.pathParameters['roomId'];
          if (roomId == null || roomId.isEmpty) {
            throw StateError('Thiếu mã phòng.');
          }
          return RoomDetailScreen(roomId: roomId);
        },
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/profile/personal-info',
        builder: (_, _) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/preferences',
        builder: (_, _) => const PreferenceChatScreen(),
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/profile/location-settings',
        builder: (_, _) => const LocationSettingsScreen(),
      ),
    ],
  );
});
