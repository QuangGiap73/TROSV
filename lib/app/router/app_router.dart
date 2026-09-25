import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/role_landing_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/landlord/appointments/presentation/landlord_appointments_screen.dart';
import '../../features/landlord/dashboard/presentation/landlord_dashboard_screen.dart';
import '../../features/landlord/profile/presentation/landlord_profile_screen.dart';
import '../../features/landlord/rooms/presentation/landlord_rooms_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/personal_info_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/rooms/presentation/screens/room_detail_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../shell/app_shell.dart';
import '../shell/landlord_shell.dart';
import '../../features/preferences/presentation/screens/preference_screen.dart';
import '../../features/rooms/presentation/screens/room_match_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (_, _) => const RoleLandingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (_, _) => const FavoritesScreen(),
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
      GoRoute(
        path: '/rooms/matches',
        builder: (_, _) => const RoomMatchScreen(),
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
        builder: (_, _) => const PreferenceScreen(),
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
    ],
  );
});
