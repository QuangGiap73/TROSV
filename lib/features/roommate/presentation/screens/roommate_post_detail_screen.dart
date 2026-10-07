import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../rooms/presentation/widgets/network_video_player.dart';
import '../../domain/entities/roommate_post.dart';
import '../providers/roommate_provider.dart';

const _green = Color(0xFF009B7D);
const _greenDark = Color(0xFF007D68);
const _ink = Color(0xFF17211F);
const _muted = Color(0xFF6D7B77);
const _border = Color(0xFFE1EAE7);

class RoommatePostDetailScreen extends ConsumerWidget {
  const RoommatePostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(roommatePostDetailProvider(postId));
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/roommate/mine');
              }
            },
          ),
          title: const Text(
            'Chi tiết bài đăng',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Chia sẻ',
              onPressed: () {},
              icon: const Icon(Icons.share_outlined),
            ),
            IconButton(
              tooltip: 'Lưu tin',
              onPressed: () {},
              icon: const Icon(Icons.favorite_border_rounded),
            ),
          ],
          bottom: const TabBar(
            labelColor: _greenDark,
            unselectedLabelColor: _muted,
            indicatorColor: _green,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Thông tin'),
              Tab(text: 'Ảnh/Video'),
              Tab(text: 'Lối sống'),
              Tab(text: 'Chi phí'),
            ],
          ),
        ),
        body: detail.when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(roommatePostDetailProvider(postId)),
          ),
          data: (post) => TabBarView(
            children: [
              _InformationTab(post: post),
              _ImagesTab(post: post),
              _LifestyleTab(post: post),
              _CostsTab(post: post),
            ],
          ),
        ),
        bottomNavigationBar: detail.maybeWhen(
          data: (post) => _BottomActions(post: post),
          orElse: () => null,
        ),
      ),
    );
  }
}

class _InformationTab extends StatelessWidget {
  const _InformationTab({required this.post});
  final RoommatePost post;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      children: [
        _HeroImage(post: post),
        const SizedBox(height: 12),
        _TypeBadge(type: post.postType),
        const SizedBox(height: 8),
        Text(
          post.title,
          style: const TextStyle(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${formatVnd(post.budgetPerPerson)}/người/tháng',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _greenDark,
          ),
        ),
        const SizedBox(height: 8),
        _InlineInfo(icon: Icons.location_on_outlined, text: _address(post)),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: _InlineInfo(
                icon: Icons.people_outline,
                text: 'Cần ${post.desiredRoommates} người',
              ),
            ),
            _InlineInfo(
              icon: Icons.visibility_outlined,
              text: '${post.viewsCount} lượt xem',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AuthorCard(post: post),
        if (post.compatibilityScore != null) ...[
          const SizedBox(height: 12),
          _CompatibilityCard(post: post),
        ],
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Mô tả',
          child: Text(
            post.description,
            style: const TextStyle(fontSize: 13, height: 1.55, color: _ink),
          ),
        ),
      ],
    );
  }
}

class _ImagesTab extends StatelessWidget {
  const _ImagesTab({required this.post});
  final RoommatePost post;

  @override
  Widget build(BuildContext context) {
    if (post.mediaUrls.isEmpty) {
      return const _EmptyTab(
        icon: Icons.photo_library_outlined,
        text: 'Bài đăng chưa có hình ảnh hoặc video.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (post.imageUrls.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: post.imageUrls.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (_, index) => ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                post.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFFE7EFED),
                  child: Icon(Icons.broken_image_outlined, color: _muted),
                ),
              ),
            ),
          ),
        if (post.imageUrls.isNotEmpty && post.videoUrls.isNotEmpty)
          const SizedBox(height: 14),
        for (var index = 0; index < post.videoUrls.length; index++) ...[
          NetworkVideoPlayer(
            key: ValueKey(post.videoUrls[index]),
            url: post.videoUrls[index],
          ),
          if (index < post.videoUrls.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _LifestyleTab extends StatelessWidget {
  const _LifestyleTab({required this.post});
  final RoommatePost post;

  @override
  Widget build(BuildContext context) {
    final traits = post.lifestyleTraits;
    final rows = <(IconData, String, String)>[
      (Icons.schedule_rounded, 'Giờ về dự kiến', _trait(traits, 'curfew')),
      (
        Icons.cleaning_services_outlined,
        'Mức độ sạch sẽ',
        _trait(traits, 'cleanliness'),
      ),
      (
        Icons.smoking_rooms_outlined,
        'Hút thuốc',
        _boolTrait(traits, 'smoking', yes: 'Có', no: 'Không'),
      ),
      (
        Icons.soup_kitchen_outlined,
        'Nấu ăn',
        _boolTrait(traits, 'cooking', yes: 'Thường', no: 'Ít'),
      ),
      (
        Icons.pets_outlined,
        'Nuôi thú cưng',
        _boolTrait(traits, 'pets', yes: 'Có', no: 'Không'),
      ),
      (
        Icons.groups_outlined,
        'Bạn bè đến chơi',
        _boolTrait(traits, 'guests', yes: 'Thoải mái', no: 'Hạn chế'),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _SectionCard(
          title: 'Thói quen và lối sống',
          child: Column(
            children: rows
                .map(
                  (row) =>
                      _DetailRow(icon: row.$1, label: row.$2, value: row.$3),
                )
                .toList(growable: false),
          ),
        ),
        if (post.lifestyleTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Đặc điểm nổi bật',
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: post.lifestyleTags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      side: BorderSide.none,
                      backgroundColor: const Color(0xFFEAF8F5),
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        color: _greenDark,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ],
    );
  }
}

class _CostsTab extends StatelessWidget {
  const _CostsTab({required this.post});
  final RoommatePost post;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(14),
    children: [
      _SectionCard(
        title: 'Chi phí',
        child: Column(
          children: [
            _MoneyRow(
              label: 'Chi phí/người',
              value: post.budgetPerPerson,
              suffix: '/tháng',
            ),
            _MoneyRow(
              label: 'Tổng tiền phòng',
              value: post.totalRoomPrice,
              suffix: '/tháng',
            ),
            _MoneyRow(label: 'Tiền cọc/người', value: post.depositPerPerson),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        title: 'Thông tin chính',
        child: Column(
          children: [
            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Loại bài đăng',
              value: _postType(post.postType),
            ),
            _DetailRow(
              icon: Icons.people_outline,
              label: 'Số người hiện có',
              value: '${post.currentMembers} người',
            ),
            _DetailRow(
              icon: Icons.person_add_alt_outlined,
              label: 'Cần thêm',
              value: '${post.desiredRoommates} người',
            ),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Ngày chuyển vào',
              value: _date(post.moveInDate),
            ),
            _DetailRow(
              icon: Icons.wc_outlined,
              label: 'Giới tính mong muốn',
              value: _gender(post.genderPreference),
            ),
            _DetailRow(
              icon: Icons.school_outlined,
              label: 'Trường/Nơi làm việc',
              value: post.universityOrWork ?? 'Chưa cập nhật',
            ),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Địa chỉ',
              value: _address(post),
              last: true,
            ),
          ],
        ),
      ),
    ],
  );
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.post});
  final RoommatePost post;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: AspectRatio(
      aspectRatio: 1.75,
      child: post.thumbnailUrl == null
          ? const ColoredBox(
              color: Color(0xFFE4F4F0),
              child: Icon(Icons.groups_rounded, size: 55, color: _green),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  post.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Color(0xFFE4F4F0),
                    child: Icon(Icons.broken_image_outlined, color: _muted),
                  ),
                ),
                if (post.mediaUrls.length > 1)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '1/${post.mediaUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({required this.post});
  final RoommatePost post;
  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Thông tin người đăng',
    child: Row(
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: const Color(0xFFE0F5EF),
          backgroundImage: post.author.avatarUrl == null
              ? null
              : NetworkImage(post.author.avatarUrl!),
          child: post.author.avatarUrl == null
              ? Text(
                  post.author.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _greenDark,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                post.universityOrWork ?? 'Thành viên TrọSV',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () {},
          child: const Text('Xem trang cá nhân'),
        ),
      ],
    ),
  );
}

class _CompatibilityCard extends StatelessWidget {
  const _CompatibilityCard({required this.post});
  final RoommatePost post;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE9F8F4),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        SizedBox.square(
          dimension: 58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: post.compatibilityScore! / 100,
                strokeWidth: 7,
                backgroundColor: const Color(0xFFCFE9E3),
                color: _green,
              ),
              Text(
                '${post.compatibilityScore}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _greenDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Độ phù hợp',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              for (final item in post.compatibilityHighlights.take(3))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: _green),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(item, style: const TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const Divider(height: 20, color: _border),
        child,
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;

        // Những field này thường có nội dung dài.
        final isLongField =
            label == 'Loại bài đăng' ||
            label == 'Trường/Nơi làm việc' ||
            label == 'Địa chỉ';

        // Máy hẹp hoặc cỡ chữ hệ thống lớn
        // thì field dài chuyển sang dạng label trên - value dưới.
        final useStackedLayout =
            isLongField && (constraints.maxWidth < 310 || textScale > 1.05);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: useStackedLayout ? _buildStacked() : _buildHorizontal(),
            ),

            if (!last)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0F3F2)),
          ],
        );
      },
    );
  }

  /// Layout dùng cho dữ liệu ngắn:
  ///
  /// Số người hiện có      1 người
  /// Ngày chuyển vào       14/10/2026
  Widget _buildHorizontal() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 20, child: Icon(icon, size: 18, color: _muted)),

        const SizedBox(width: 9),

        Expanded(
          flex: 5,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, height: 1.2, color: _muted),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          flex: 6,
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11.8,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17211F),
            ),
          ),
        ),
      ],
    );
  }

  /// Layout dùng cho nội dung dài:
  ///
  /// 🎓 Trường/Nơi làm việc
  ///    Đại học Quốc gia Hà Nội
  Widget _buildStacked() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: _muted),
          ),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  color: _muted,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17211F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.value, this.suffix = ''});
  final String label, suffix;
  final int? value;
  @override
  Widget build(BuildContext context) => _DetailRow(
    icon: Icons.payments_outlined,
    label: label,
    value: value == null ? 'Chưa cập nhật' : '${formatVnd(value!)}$suffix',
  );
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: _muted),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
      ),
    ],
  );
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F7F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _postType(type),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _greenDark,
        ),
      ),
    ),
  );
}

class _BottomActions extends ConsumerWidget {
  const _BottomActions({required this.post});
  final RoommatePost post;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_border_rounded),
              label: const Text('Lưu tin'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: _ink,
                side: const BorderSide(color: _border),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: post.isOwner
                  ? null
                  : () => _showContactSheet(context, ref, post.id),
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Xem thông tin liên hệ'),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showContactSheet(
  BuildContext context,
  WidgetRef ref,
  String postId,
) async {
  ref.invalidate(roommateContactProvider(postId));
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ContactSheet(postId: postId),
  );
}

class _ContactSheet extends ConsumerWidget {
  const _ContactSheet({required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = ref.watch(roommateContactProvider(postId));
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
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
          const SizedBox(height: 18),
          contact.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 38),
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 42,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 10),
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(roommateContactProvider(postId)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
            data: (value) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin liên hệ',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(value.authorName, style: const TextStyle(color: _muted)),
                const SizedBox(height: 16),
                if (value.hasPhone)
                  _ContactTile(
                    icon: Icons.phone_outlined,
                    title: 'Số điện thoại',
                    value: value.phone!,
                    color: _green,
                    onTap: () => _launchContact(
                      context,
                      Uri(scheme: 'tel', path: value.phone),
                      'Không thể mở ứng dụng gọi điện.',
                    ),
                  ),
                if (value.hasPhone && value.hasZalo) const SizedBox(height: 10),
                if (value.hasZalo)
                  _ContactTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Zalo',
                    value: value.zaloPhone!,
                    color: const Color(0xFF0877D1),
                    onTap: () => _launchContact(
                      context,
                      Uri.https('zalo.me', '/${_digits(value.zaloPhone!)}'),
                      'Không thể mở Zalo trên thiết bị này.',
                    ),
                  ),
                if (!value.hasPhone && !value.hasZalo)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Người đăng chưa cập nhật thông tin liên hệ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: .08),
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .13),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: color, size: 20),
          ],
        ),
      ),
    ),
  );
}

Future<void> _launchContact(
  BuildContext context,
  Uri uri,
  String failureMessage,
) async {
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}

String _digits(String value) => value.replaceAll(RegExp(r'[^0-9+]'), '');

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 55, color: const Color(0xFF9AADA8)),
        const SizedBox(height: 10),
        Text(text, style: const TextStyle(color: _muted)),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

String _address(RoommatePost post) => [
  if (post.addressHint?.isNotEmpty == true) post.addressHint,
  if (post.ward?.isNotEmpty == true) post.ward,
  post.district,
  post.province,
].join(', ');

String _postType(String value) =>
    value == 'HAVE_ROOM' || value == 'HAVE_ROOM_FIND_MATE'
    ? 'Đã có phòng, tìm người ở ghép'
    : 'Tìm người cùng tìm phòng';
String _gender(String value) => switch (value) {
  'MALE' => 'Nam',
  'FEMALE' => 'Nữ',
  _ => 'Không yêu cầu',
};
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _trait(Map<String, dynamic> traits, String key) {
  final value = traits[key];
  return value is String && value.trim().isNotEmpty ? value : 'Chưa cập nhật';
}

String _boolTrait(
  Map<String, dynamic> traits,
  String key, {
  required String yes,
  required String no,
}) {
  final value = traits[key];
  return value is bool ? (value ? yes : no) : 'Chưa cập nhật';
}
