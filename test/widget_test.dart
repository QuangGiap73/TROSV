import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trosv_app/app/app.dart';
import 'package:trosv_app/features/auth/domain/entities/auth_session.dart';
import 'package:trosv_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trosv_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:trosv_app/features/rooms/domain/entities/room_summary.dart';
import 'package:trosv_app/features/rooms/presentation/providers/room_providers.dart';

void main() {
  testWidgets('hiển thị trang chủ TrọSV', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(FakeAuthController.new),
          featuredRoomsProvider.overrideWith((ref) async => []),
          favoritesProvider.overrideWith(FakeFavoritesController.new),
        ],
        child: const TrosvApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Xin chào bạn 👋'), findsOneWidget);
    expect(find.text('Bạn muốn tìm phòng ở đâu?'), findsOneWidget);
    expect(find.text('Hà Nội'), findsOneWidget);
  });
}

class FakeAuthController extends AuthController {
  @override
  Future<AuthSession?> build() async => null;
}

class FakeFavoritesController extends FavoritesController {
  @override
  Future<List<RoomSummary>> build() async => [];
}
