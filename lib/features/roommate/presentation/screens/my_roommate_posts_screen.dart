import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/roommate_post.dart';
import '../providers/roommate_provider.dart';
import '../widgets/roommate_post_card.dart';

class MyRoommatePostsScreen extends ConsumerWidget {
  const MyRoommatePostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(filteredMyRoommatePostsProvider);
    final selected = ref.watch(myRoommatePostFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Tin của tôi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => context.push('/roommate/create'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00A889),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Đăng tin'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filter(ref, selected, MyRoommatePostFilter.all, 'Tất cả'),
                  _filter(
                    ref,
                    selected,
                    MyRoommatePostFilter.pending,
                    'Chờ duyệt',
                  ),
                  _filter(
                    ref,
                    selected,
                    MyRoommatePostFilter.active,
                    'Đang đăng',
                  ),
                  _filter(
                    ref,
                    selected,
                    MyRoommatePostFilter.rejected,
                    'Bị từ chối',
                  ),
                  _filter(
                    ref,
                    selected,
                    MyRoommatePostFilter.closed,
                    'Đã đóng',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: posts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: FilledButton.icon(
                  onPressed: () => ref.invalidate(myRoommatePostsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại'),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _MyPostsEmpty(
                    filtered: selected != MyRoommatePostFilter.all,
                    onCreate: () => context.push('/roommate/create'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(myRoommatePostsProvider);
                    await ref.read(myRoommatePostsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final post = items[index];
                      return RoommatePostCard(
                        post: post,
                        showStatus: true,
                        onTap: () => context.push('/roommate/posts/${post.id}'),
                        trailing: PopupMenuButton<_PostAction>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          onSelected: (action) =>
                              _handleAction(context, ref, post, action),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: _PostAction.view,
                              child: _MenuItem(
                                icon: Icons.visibility_outlined,
                                label: 'Xem chi tiết',
                              ),
                            ),
                            if (post.isActive)
                              const PopupMenuItem(
                                value: _PostAction.members,
                                child: _MenuItem(
                                  icon: Icons.group_add_outlined,
                                  label: 'Cập nhật số người',
                                ),
                              ),
                            if (post.isActive)
                              const PopupMenuItem(
                                value: _PostAction.close,
                                child: _MenuItem(
                                  icon: Icons.task_alt_rounded,
                                  label: 'Đã tìm đủ người',
                                  color: Color(0xFF008F72),
                                ),
                              ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: _PostAction.delete,
                              child: _MenuItem(
                                icon: Icons.delete_outline_rounded,
                                label: 'Xóa bài đăng',
                                color: Color(0xFFE5484D),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filter(
    WidgetRef ref,
    MyRoommatePostFilter current,
    MyRoommatePostFilter value,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text(label),
        selected: current == value,
        showCheckmark: false,
        selectedColor: const Color(0xFF009B7D),
        labelStyle: TextStyle(
          color: current == value ? Colors.white : const Color(0xFF43514E),
          fontWeight: FontWeight.w700,
        ),
        onSelected: (_) =>
            ref.read(myRoommatePostFilterProvider.notifier).select(value),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    RoommatePost post,
    _PostAction action,
  ) async {
    switch (action) {
      case _PostAction.view:
        context.push('/roommate/posts/${post.id}');
      case _PostAction.members:
        await _showMemberSheet(context, ref, post);
      case _PostAction.close:
        await _confirmClose(context, ref, post);
      case _PostAction.delete:
        await _confirmDelete(context, ref, post);
    }
  }

  Future<void> _showMemberSheet(
    BuildContext context,
    WidgetRef ref,
    RoommatePost post,
  ) async {
    var current = post.currentMembers;
    var desired = post.desiredRoommates;
    final result = await showModalBottomSheet<(int, int)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cập nhật tình trạng tìm người',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bài vẫn tiếp tục hiển thị cho đến khi bạn chọn “Đã tìm đủ người”.',
                  style: TextStyle(color: Color(0xFF687571)),
                ),
                const SizedBox(height: 18),
                _MemberCounter(
                  label: 'Số người hiện có',
                  value: current,
                  maximum: 10,
                  onChanged: (value) => setSheetState(() => current = value),
                ),
                const SizedBox(height: 12),
                _MemberCounter(
                  label: 'Số người cần thêm',
                  value: desired,
                  maximum: 6,
                  onChanged: (value) => setSheetState(() => desired = value),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(sheetContext, (current, desired)),
                    child: const Text('Cập nhật'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final ok = await ref
        .read(roommatePostActionProvider.notifier)
        .updateMemberCounts(
          postId: post.id,
          currentMembers: result.$1,
          desiredRoommates: result.$2,
        );
    if (context.mounted) {
      _message(
        context,
        ok ? 'Đã cập nhật số người.' : _actionError(ref),
        error: !ok,
      );
    }
  }

  Future<void> _confirmClose(
    BuildContext context,
    WidgetRef ref,
    RoommatePost post,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.celebration_rounded,
          size: 48,
          color: Color(0xFF00A889),
        ),
        title: const Text('Bạn đã tìm đủ người ở ghép?'),
        content: const Text(
          'Sau khi xác nhận, bài đăng sẽ được đóng và không còn xuất hiện trên bảng tin ở ghép.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await ref
        .read(roommatePostActionProvider.notifier)
        .closePost(post.id);
    if (context.mounted) {
      _message(
        context,
        ok
            ? 'Đã đóng tin. Chúc bạn có trải nghiệm ở ghép thật vui!'
            : _actionError(ref),
        error: !ok,
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RoommatePost post,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bài đăng?'),
        content: const Text('Bài đăng sẽ bị xóa và không thể khôi phục.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE5484D),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa bài'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await ref
        .read(roommatePostActionProvider.notifier)
        .deletePost(post.id);
    if (context.mounted) {
      _message(
        context,
        ok ? 'Đã xóa bài đăng.' : _actionError(ref),
        error: !ok,
      );
    }
  }

  String _actionError(WidgetRef ref) {
    return ref.read(roommatePostActionProvider).error?.toString() ??
        'Không thể thực hiện thao tác.';
  }

  void _message(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? const Color(0xFFE5484D)
            : const Color(0xFF008F72),
      ),
    );
  }
}

enum _PostAction { view, members, close, delete }

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 11),
      Text(label, style: TextStyle(color: color)),
    ],
  );
}

class _MemberCounter extends StatelessWidget {
  const _MemberCounter({
    required this.label,
    required this.value,
    required this.maximum,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int maximum;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFDCE6E3)),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          onPressed: value < maximum ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    ),
  );
}

class _MyPostsEmpty extends StatelessWidget {
  const _MyPostsEmpty({required this.filtered, required this.onCreate});
  final bool filtered;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: Color(0xFF82AA9F),
            ),
            const SizedBox(height: 14),
            Text(
              filtered
                  ? 'Không có tin ở trạng thái này'
                  : 'Bạn chưa đăng tin nào',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'Hãy chọn trạng thái khác để kiểm tra.'
                  : 'Đăng tin để tìm người ở ghép phù hợp với bạn.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF687571)),
            ),
            if (!filtered) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Đăng tin ở ghép'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
