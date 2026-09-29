import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../auth/presentation/providers/auth_provider.dart';

import 'providers/favorites_provider.dart';

import 'widgets/favorite_room_card.dart';



const _green = Color(0xFF00A884);

const _greenDark = Color(0xFF008C72);

const _background = Color(0xFFF5F9F7);

const _textPrimary = Color(0xFF17211F);

const _textSecondary = Color(0xFF667773);

const _border = Color(0xFFE2EAE8);



class FavoritesScreen extends ConsumerStatefulWidget {

  const FavoritesScreen({super.key});



  @override

  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();

}



class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {

  bool _editMode = false;

  bool _removing = false;

  final Set<String> _selectedIds = <String>{};



  @override

  Widget build(BuildContext context) {

    final authState = ref.watch(authControllerProvider);

    final session = authState.asData?.value;



    return Scaffold(

      backgroundColor: _background,

      appBar: AppBar(

        elevation: 0,

        scrolledUnderElevation: 0,

        backgroundColor: _background,

        surfaceTintColor: Colors.transparent,

        titleSpacing: 16,

        title: _HeaderTitle(

          count: session == null

              ? null

              : ref.watch(favoritesProvider).asData?.value.length,

        ),

        actions: [

          if (session != null)

            ref

                .watch(favoritesProvider)

                .maybeWhen(

                  data: (rooms) => rooms.isEmpty

                      ? const SizedBox.shrink()

                      : OutlinedButton(

                          onPressed: _removing

                              ? null

                              : () {

                                  setState(() {

                                    _editMode = !_editMode;

                                    if (!_editMode) {

                                      _selectedIds.clear();

                                    }

                                  });

                                },

                          style: OutlinedButton.styleFrom(

                            side: const BorderSide(color: _greenDark),

                            shape: const StadiumBorder(),

                            padding: const EdgeInsets.symmetric(

                              horizontal: 16,

                              vertical: 9,

                            ),

                          ),

                          child: Text(

                            _editMode ? 'Xong' : 'Chỉnh sửa',

                            style: const TextStyle(

                              color: _greenDark,

                              fontWeight: FontWeight.w800,

                            ),

                          ),

                        ),

                  orElse: () => const SizedBox.shrink(),

                ),

          const SizedBox(width: 6),

        ],

      ),

      body: authState.isLoading

          ? const _FavoritesLoading()

          : session == null

          ? const _LoginRequired()

          : _FavoritesContent(

              editMode: _editMode,

              selectedIds: _selectedIds,

              removing: _removing,

              onToggleSelected: _toggleSelected,

              onRemoveOne: _removeOne,

            ),

      bottomNavigationBar:

          session != null && _editMode && _selectedIds.isNotEmpty

          ? _BulkRemoveBar(

              count: _selectedIds.length,

              loading: _removing,

              onRemove: _removeSelected,

            )

          : null,

    );

  }



  void _toggleSelected(String roomId) {

    setState(() {

      if (!_selectedIds.add(roomId)) {

        _selectedIds.remove(roomId);

      }

    });

  }



  Future<void> _removeOne(String roomId) async {

    try {

      await ref.read(favoritesProvider.notifier).remove(roomId);



      if (!mounted) return;



      ScaffoldMessenger.of(context)

        ..hideCurrentSnackBar()

        ..showSnackBar(

          const SnackBar(

            behavior: SnackBarBehavior.floating,

            content: Text('Đã bỏ phòng khỏi yêu thích.'),

          ),

        );

    } catch (_) {

      if (!mounted) return;



      ScaffoldMessenger.of(context)

        ..hideCurrentSnackBar()

        ..showSnackBar(

          const SnackBar(

            behavior: SnackBarBehavior.floating,

            content: Text('Không thể bỏ yêu thích. Hãy thử lại.'),

          ),

        );

    }

  }



  Future<void> _removeSelected() async {

    final accepted = await showModalBottomSheet<bool>(

      context: context,

      useSafeArea: true,

      backgroundColor: Colors.transparent,

      builder: (context) => _ConfirmRemoveSheet(count: _selectedIds.length),

    );



    if (accepted != true) return;



    setState(() => _removing = true);



    try {

      for (final roomId in _selectedIds.toList()) {

        await ref.read(favoritesProvider.notifier).remove(roomId);

      }



      if (!mounted) return;



      setState(() {

        _selectedIds.clear();

        _editMode = false;

      });



      ScaffoldMessenger.of(context)

        ..hideCurrentSnackBar()

        ..showSnackBar(

          const SnackBar(

            behavior: SnackBarBehavior.floating,

            content: Text('Đã cập nhật danh sách yêu thích.'),

          ),

        );

    } catch (_) {

      if (!mounted) return;



      ScaffoldMessenger.of(context)

        ..hideCurrentSnackBar()

        ..showSnackBar(

          const SnackBar(

            behavior: SnackBarBehavior.floating,

            content: Text('Không thể cập nhật yêu thích. Hãy thử lại.'),

          ),

        );

    } finally {

      if (mounted) {

        setState(() => _removing = false);

      }

    }

  }

}



class _HeaderTitle extends StatelessWidget {

  const _HeaderTitle({required this.count});



  final int? count;



  @override

  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(

          'Yêu thích',

          style: TextStyle(

            fontSize: 22,

            height: 1.1,

            fontWeight: FontWeight.w900,

            color: _textPrimary,

          ),

        ),

        if (count != null) ...[

          const SizedBox(height: 3),

          Text(

            '$count phòng đã lưu',

            style: const TextStyle(

              fontSize: 11.5,

              fontWeight: FontWeight.w500,

              color: _textSecondary,

            ),

          ),

        ],

      ],

    );

  }

}



class _FavoritesContent extends ConsumerWidget {

  const _FavoritesContent({

    required this.editMode,

    required this.selectedIds,

    required this.removing,

    required this.onToggleSelected,

    required this.onRemoveOne,

  });



  final bool editMode;

  final Set<String> selectedIds;

  final bool removing;

  final ValueChanged<String> onToggleSelected;

  final ValueChanged<String> onRemoveOne;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final favorites = ref.watch(favoritesProvider);



    return favorites.when(

      loading: () => const _FavoritesLoading(),

      error: (_, _) =>

          _FavoritesError(onRetry: () => ref.invalidate(favoritesProvider)),

      data: (rooms) {

        if (rooms.isEmpty) {

          return const _FavoritesEmpty();

        }



        return RefreshIndicator(

          color: _green,

          onRefresh: () => ref.read(favoritesProvider.notifier).reload(),

          child: ListView.separated(

            physics: const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(14, 6, 14, 30),

            itemCount: rooms.length,

            separatorBuilder: (_, _) => const SizedBox(height: 11),

            itemBuilder: (context, index) {

              final room = rooms[index];

              final selected = selectedIds.contains(room.id);



              return Stack(

                children: [

                  AnimatedOpacity(

                    opacity: editMode && !selected ? 0.90 : 1,

                    duration: const Duration(milliseconds: 150),

                    child: FavoriteRoomCard(

                      room: room,

                      onTap: editMode

                          ? () => onToggleSelected(room.id)

                          : () => context.push('/rooms/${room.id}'),

                      onRemove: removing || editMode

                          ? () {}

                          : () => onRemoveOne(room.id),

                    ),

                  ),

                  if (editMode)

                    Positioned(

                      left: 10,

                      top: 10,

                      child: Material(

                        color: Colors.transparent,

                        child: InkWell(

                          onTap: () => onToggleSelected(room.id),

                          customBorder: const CircleBorder(),

                          child: Container(

                            width: 30,

                            height: 30,

                            decoration: BoxDecoration(

                              color: selected ? _green : Colors.white,

                              shape: BoxShape.circle,

                              border: Border.all(

                                color: selected

                                    ? _green

                                    : const Color(0xFFCBD9D5),

                              ),

                              boxShadow: const [

                                BoxShadow(

                                  color: Color(0x16000000),

                                  blurRadius: 6,

                                ),

                              ],

                            ),

                            child: selected

                                ? const Icon(

                                    Icons.check_rounded,

                                    size: 18,

                                    color: Colors.white,

                                  )

                                : null,

                          ),

                        ),

                      ),

                    ),

                ],

              );

            },

          ),

        );

      },

    );

  }

}



class _LoginRequired extends StatelessWidget {

  const _LoginRequired();



  @override

  Widget build(BuildContext context) {

    return _StateLayout(

      icon: Icons.favorite_border_rounded,

      title: 'Đăng nhập để xem phòng đã lưu',

      message:

          'Lưu những phòng bạn quan tâm để dễ dàng xem lại và so sánh sau.',

      action: FilledButton.icon(

        onPressed: () => context.push('/login'),

        style: FilledButton.styleFrom(

          backgroundColor: _green,

          minimumSize: const Size(190, 48),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(14),

          ),

        ),

        icon: const Icon(Icons.login_rounded),

        label: const Text(

          'Đăng nhập',

          style: TextStyle(fontWeight: FontWeight.w800),

        ),

      ),

    );

  }

}



class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8F9F4),
                Color(0xFFF4FCFA),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFD8EEE8),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/empty_favorites.png',
                width: 122,
                height: 105,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 12),
              const Text(
                'Bạn chưa lưu phòng nào',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lưu những phòng phù hợp để\n'
                'dễ dàng xem lại sau.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 19),
              SizedBox(
                width: 245,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => context.go('/search'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _greenDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  icon: const Icon(
                    Icons.search_rounded,
                    size: 21,
                  ),
                  label: const Text(
                    'Khám phá phòng trọ',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _FavoritesError extends StatelessWidget {

  const _FavoritesError({required this.onRetry});



  final VoidCallback onRetry;



  @override

  Widget build(BuildContext context) {

    return _StateLayout(

      icon: Icons.cloud_off_outlined,

      title: 'Không thể tải phòng đã lưu',

      message: 'Có lỗi khi tải danh sách yêu thích. Hãy thử lại sau.',

      iconColor: Colors.redAccent,

      action: OutlinedButton.icon(

        onPressed: onRetry,

        icon: const Icon(Icons.refresh_rounded),

        label: const Text('Thử lại'),

      ),

    );

  }

}



class _StateLayout extends StatelessWidget {

  const _StateLayout({

    required this.icon,

    required this.title,

    required this.message,

    required this.action,

    this.iconColor = _greenDark,

  });



  final IconData icon;

  final String title;

  final String message;

  final Widget action;

  final Color iconColor;



  @override

  Widget build(BuildContext context) {

    return Center(

      child: SingleChildScrollView(

        padding: const EdgeInsets.all(24),

        child: Container(

          width: double.infinity,

          padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),

          decoration: BoxDecoration(

            gradient: const LinearGradient(

              begin: Alignment.topLeft,

              end: Alignment.bottomRight,

              colors: [Color(0xFFE9F9F4), Color(0xFFF5FCFA)],

            ),

            borderRadius: BorderRadius.circular(24),

            border: Border.all(color: const Color(0xFFD8EEE8)),

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Container(

                width: 86,

                height: 86,

                alignment: Alignment.center,

                decoration: BoxDecoration(

                  color: Colors.white,

                  shape: BoxShape.circle,

                  boxShadow: const [

                    BoxShadow(color: Color(0x0A000000), blurRadius: 12),

                  ],

                ),

                child: Icon(icon, size: 42, color: iconColor),

              ),

              const SizedBox(height: 17),

              Text(

                title,

                textAlign: TextAlign.center,

                style: const TextStyle(

                  fontSize: 19,

                  fontWeight: FontWeight.w900,

                  color: _textPrimary,

                ),

              ),

              const SizedBox(height: 7),

              Text(

                message,

                textAlign: TextAlign.center,

                style: const TextStyle(

                  fontSize: 12.5,

                  height: 1.45,

                  color: _textSecondary,

                ),

              ),

              const SizedBox(height: 19),

              action,

            ],

          ),

        ),

      ),

    );

  }

}



class _FavoritesLoading extends StatelessWidget {

  const _FavoritesLoading();



  @override

  Widget build(BuildContext context) {

    return ListView.separated(

      padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),

      itemCount: 4,

      separatorBuilder: (_, _) => const SizedBox(height: 11),

      itemBuilder: (_, _) => const _FavoriteSkeleton(),

    );

  }

}



class _FavoriteSkeleton extends StatelessWidget {

  const _FavoriteSkeleton();



  @override

  Widget build(BuildContext context) {

    return Container(

      height: 145,

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: _border),

      ),

      child: Row(

        children: [

          Container(

            width: 116,

            decoration: BoxDecoration(

              color: const Color(0xFFE7EFEC),

              borderRadius: BorderRadius.circular(13),

            ),

          ),

          const SizedBox(width: 11),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                _line(170, 14),

                const SizedBox(height: 9),

                _line(115, 13),

                const SizedBox(height: 12),

                _line(145, 10),

                const SizedBox(height: 9),

                _line(120, 10),

                const Spacer(),

                Row(

                  children: [

                    _pill(55),

                    const SizedBox(width: 6),

                    _pill(65),

                    const SizedBox(width: 6),

                    _pill(58),

                  ],

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Widget _line(double width, double height) {

    return Container(

      width: width,

      height: height,

      decoration: BoxDecoration(

        color: const Color(0xFFE7EFEC),

        borderRadius: BorderRadius.circular(8),

      ),

    );

  }



  Widget _pill(double width) {

    return Container(

      width: width,

      height: 24,

      decoration: BoxDecoration(

        color: const Color(0xFFE7EFEC),

        borderRadius: BorderRadius.circular(20),

      ),

    );

  }

}



class _BulkRemoveBar extends StatelessWidget {

  const _BulkRemoveBar({

    required this.count,

    required this.loading,

    required this.onRemove,

  });



  final int count;

  final bool loading;

  final VoidCallback onRemove;



  @override

  Widget build(BuildContext context) {

    return SafeArea(

      top: false,

      child: Container(

        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),

        decoration: const BoxDecoration(

          color: Colors.white,

          border: Border(top: BorderSide(color: _border)),

          boxShadow: [

            BoxShadow(

              color: Color(0x0A000000),

              blurRadius: 12,

              offset: Offset(0, -3),

            ),

          ],

        ),

        child: FilledButton.icon(

          onPressed: loading ? null : onRemove,

          style: FilledButton.styleFrom(

            backgroundColor: Colors.redAccent,

            foregroundColor: Colors.white,

            minimumSize: const Size.fromHeight(50),

            shape: RoundedRectangleBorder(

              borderRadius: BorderRadius.circular(14),

            ),

          ),

          icon: loading

              ? const SizedBox.square(

                  dimension: 18,

                  child: CircularProgressIndicator(

                    strokeWidth: 2,

                    color: Colors.white,

                  ),

                )

              : const Icon(Icons.favorite_border_rounded),

          label: Text(

            loading ? 'Đang cập nhật...' : 'Bỏ lưu $count phòng',

            style: const TextStyle(fontWeight: FontWeight.w800),

          ),

        ),

      ),

    );

  }

}



class _ConfirmRemoveSheet extends StatelessWidget {

  const _ConfirmRemoveSheet({required this.count});



  final int count;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),

      decoration: const BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      child: Column(

        mainAxisSize: MainAxisSize.min,

        children: [

          Container(

            width: 42,

            height: 5,

            decoration: BoxDecoration(

              color: const Color(0xFFDCE5E2),

              borderRadius: BorderRadius.circular(20),

            ),

          ),

          const SizedBox(height: 20),

          Container(

            width: 64,

            height: 64,

            alignment: Alignment.center,

            decoration: const BoxDecoration(

              color: Color(0xFFFFEEEE),

              shape: BoxShape.circle,

            ),

            child: const Icon(

              Icons.favorite_border_rounded,

              color: Colors.redAccent,

              size: 33,

            ),

          ),

          const SizedBox(height: 14),

          const Text(

            'Bỏ các phòng đã chọn?',

            style: TextStyle(

              fontSize: 19,

              fontWeight: FontWeight.w900,

              color: _textPrimary,

            ),

          ),

          const SizedBox(height: 7),

          Text(

            'Bạn đang chọn $count phòng. Các phòng này sẽ được xóa khỏi danh sách yêu thích.',

            textAlign: TextAlign.center,

            style: const TextStyle(

              fontSize: 12.5,

              height: 1.45,

              color: _textSecondary,

            ),

          ),

          const SizedBox(height: 20),

          Row(

            children: [

              Expanded(

                child: OutlinedButton(

                  onPressed: () => Navigator.pop(context, false),

                  style: OutlinedButton.styleFrom(

                    padding: const EdgeInsets.symmetric(vertical: 13),

                  ),

                  child: const Text('Quay lại'),

                ),

              ),

              const SizedBox(width: 9),

              Expanded(

                child: FilledButton(

                  onPressed: () => Navigator.pop(context, true),

                  style: FilledButton.styleFrom(

                    backgroundColor: Colors.redAccent,

                    padding: const EdgeInsets.symmetric(vertical: 13),

                  ),

                  child: const Text('Bỏ lưu'),

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }

}
