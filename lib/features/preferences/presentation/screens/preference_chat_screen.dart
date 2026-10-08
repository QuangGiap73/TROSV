import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../rooms/domain/entities/room_match.dart';
import '../../../rooms/presentation/providers/room_match_provider.dart';
import '../../domain/entities/tenant_preference.dart';
import '../../domain/entities/university_location.dart';
import '../providers/preference_chat_provider.dart';
import '../providers/preference_provider.dart';

const _primary = Color(0xFF00A98F);
const _primaryDark = Color(0xFF007E6B);
const _ink = Color(0xFF17211F);
const _muted = Color(0xFF6D7B77);
const _background = Color(0xFFF4F8F7);
const _line = Color(0xFFE0E9E6);

class PreferenceChatScreen extends ConsumerStatefulWidget {
  const PreferenceChatScreen({super.key});

  @override
  ConsumerState<PreferenceChatScreen> createState() =>
      _PreferenceChatScreenState();
}

class _PreferenceChatScreenState extends ConsumerState<PreferenceChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _save(PreferenceDraft draft) async {
    final success = await ref
        .read(tenantPreferenceProvider.notifier)
        .save(draft.toPreference());
    if (!mounted) return;
    if (!success) {
      final error = ref.read(tenantPreferenceProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Không thể lưu nhu cầu.')),
      );
      return;
    }
    ref.invalidate(roomMatchesProvider);
    ref.read(preferenceChatProvider.notifier).showRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final preference = ref.watch(tenantPreferenceProvider);
    final chat = ref.watch(preferenceChatProvider);

    ref.listen(preferenceChatProvider, (_, _) => _scrollToLatest());
    ref.listen<AsyncValue<TenantPreference?>>(tenantPreferenceProvider, (
      _,
      next,
    ) {
      next.whenData(
        (value) => ref.read(preferenceChatProvider.notifier).hydrate(value),
      );
    });

    if (preference.hasValue && !chat.hydrated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(preferenceChatProvider.notifier).hydrate(preference.value);
        }
      });
    }

    if (!chat.hydrated && preference.isLoading) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (!chat.hydrated && preference.hasError) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(title: const Text('Trợ lý tìm trọ')),
        body: _ErrorView(
          onRetry: () => ref.invalidate(tenantPreferenceProvider),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
        titleSpacing: 2,
        title: const Row(
          children: [
            _AssistantAvatar(size: 38),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý tìm trọ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Đang hỗ trợ bạn',
                  style: TextStyle(fontSize: 10.5, color: _primaryDark),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm lại',
            onPressed: () {
              ref.read(preferenceChatProvider.notifier).restart();
              _scrollToLatest();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
              children: [
                const _DayLabel(),
                const SizedBox(height: 18),
                const _AssistantBubble(
                  text:
                      'Chào bạn! Mình sẽ hỏi vài câu ngắn để tìm những phòng phù hợp nhất nhé.',
                ),
                const SizedBox(height: 12),
                ..._history(chat),
                if (chat.step == PreferenceChatStep.recommendations)
                  const _RecommendationsInChat(),
              ],
            ),
          ),
          _ComposerPanel(
            state: chat,
            saving: preference.isLoading,
            onSave: () => _save(chat.draft),
          ),
        ],
      ),
    );
  }

  List<Widget> _history(PreferenceChatState state) {
    final draft = state.draft;
    final current = state.step.index;
    final result = <Widget>[];

    void add(PreferenceChatStep step, String question, String answer) {
      if (current < step.index) return;
      result.add(_AssistantBubble(text: question));
      if (current > step.index) {
        result.add(const SizedBox(height: 8));
        result.add(
          _UserBubble(
            text: answer,
            onEdit: () => ref.read(preferenceChatProvider.notifier).edit(step),
          ),
        );
        result.add(const SizedBox(height: 14));
      }
    }

    add(
      PreferenceChatStep.location,
      'Bạn muốn tìm phòng gần trường nào?',
      draft.university == null
          ? 'Chưa chọn khu vực'
          : '${draft.university}\n${draft.district ?? ''}',
    );
    add(
      PreferenceChatStep.budget,
      'Ngân sách tối đa mỗi tháng của bạn là bao nhiêu?',
      '${formatVnd(draft.budgetMax)}/tháng',
    );
    add(
      PreferenceChatStep.radius,
      'Bạn muốn tìm trong bán kính bao xa?',
      'Trong ${_radius(draft.radiusKm)} km',
    );
    add(
      PreferenceChatStep.roomType,
      'Bạn ưu tiên loại phòng nào?',
      _roomTypeLabel(draft.roomType),
    );
    add(
      PreferenceChatStep.people,
      'Phòng dành cho bao nhiêu người ở?',
      '${draft.maxPeople} người',
    );
    add(
      PreferenceChatStep.amenities,
      'Bạn cần những tiện ích nào? Có thể chọn nhiều.',
      draft.amenities.isEmpty
          ? 'Không yêu cầu tiện ích cụ thể'
          : '${draft.amenities.length} tiện ích đã chọn',
    );
    add(
      PreferenceChatStep.extras,
      'Bạn có yêu cầu thêm về không gian phòng không?',
      [
            if (draft.bathroomPrivate) 'WC khép kín',
            if (draft.hasBalcony) 'Có ban công',
          ].isEmpty
          ? 'Không có yêu cầu thêm'
          : [
              if (draft.bathroomPrivate) 'WC khép kín',
              if (draft.hasBalcony) 'Có ban công',
            ].join(' • '),
    );
    add(
      PreferenceChatStep.alerts,
      'Bạn có muốn nhận thông báo khi xuất hiện phòng mới phù hợp không?',
      draft.alertsEnabled
          ? 'Có, hãy thông báo cho tôi'
          : 'Không nhận thông báo',
    );

    if (current >= PreferenceChatStep.review.index) {
      result.add(
        const _AssistantBubble(
          text:
              'Mình đã tổng hợp nhu cầu của bạn. Kiểm tra lại trước khi tìm phòng nhé.',
        ),
      );
      result.add(const SizedBox(height: 10));
      result.add(_PreferenceSummary(draft: draft));
      result.add(const SizedBox(height: 14));
    }
    if (current >= PreferenceChatStep.recommendations.index) {
      result.add(
        const _AssistantBubble(
          text: 'Đây là những phòng phù hợp nhất mà mình tìm được cho bạn:',
        ),
      );
      result.add(const SizedBox(height: 10));
    }
    return result;
  }
}

class _ComposerPanel extends ConsumerWidget {
  const _ComposerPanel({
    required this.state,
    required this.saving,
    required this.onSave,
  });

  final PreferenceChatState state;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(preferenceChatProvider.notifier);
    final child = switch (state.step) {
      PreferenceChatStep.location => _LocationComposer(controller: controller),
      PreferenceChatStep.budget => _ChoiceWrap<int>(
        values: const [2000000, 3000000, 4000000, 5000000, 6000000, 8000000],
        label: (value) => _moneyShort(value),
        onSelected: controller.selectBudget,
      ),
      PreferenceChatStep.radius => _ChoiceWrap<double>(
        values: const [1, 3, 5, 10, 20],
        label: (value) => '${_radius(value)} km',
        onSelected: controller.selectRadius,
      ),
      PreferenceChatStep.roomType => _RoomTypeComposer(controller: controller),
      PreferenceChatStep.people => _ChoiceWrap<int>(
        values: const [1, 2, 3, 4],
        label: (value) => '$value người',
        onSelected: controller.selectPeople,
      ),
      PreferenceChatStep.amenities => _AmenitiesComposer(
        selected: state.draft.amenities,
        controller: controller,
      ),
      PreferenceChatStep.extras => _ExtrasComposer(
        draft: state.draft,
        controller: controller,
      ),
      PreferenceChatStep.alerts => _AlertComposer(controller: controller),
      PreferenceChatStep.review => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.auto_awesome_rounded),
          label: Text(
            saving ? 'Đang tìm phòng...' : 'Lưu và tìm phòng phù hợp',
          ),
        ),
      ),
      PreferenceChatStep.recommendations => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => controller.edit(PreferenceChatStep.location),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Điều chỉnh'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => context.push('/rooms/matches'),
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Xem tất cả'),
            ),
          ),
        ],
      ),
    };

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _line)),
          boxShadow: [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 16,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          child: ConstrainedBox(
            key: ValueKey(state.step),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .38,
            ),
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }
}

class _LocationComposer extends ConsumerWidget {
  const _LocationComposer({required this.controller});
  final PreferenceChatController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universities = ref.watch(universitiesProvider);
    return universities.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => OutlinedButton.icon(
        onPressed: () => ref.invalidate(universitiesProvider),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Tải lại danh sách trường'),
      ),
      data: (items) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () async {
            final selected = await showModalBottomSheet<UniversityLocation>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.white,
              builder: (_) => _UniversitySheet(items: items),
            );
            if (selected != null) controller.selectUniversity(selected);
          },
          icon: const Icon(Icons.school_outlined),
          label: const Text('Chọn trường hoặc khu vực'),
        ),
      ),
    );
  }
}

class _ChoiceWrap<T> extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.label,
    required this.onSelected,
  });
  final List<T> values;
  final String Function(T value) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: values
        .map(
          (value) => ActionChip(
            label: Text(label(value)),
            avatar: const Icon(Icons.check_circle_outline_rounded, size: 17),
            onPressed: () => onSelected(value),
          ),
        )
        .toList(growable: false),
  );
}

class _RoomTypeComposer extends StatelessWidget {
  const _RoomTypeComposer({required this.controller});
  final PreferenceChatController controller;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children:
        const <String?, String>{
              null: 'Tất cả',
              'ROOM_SINGLE': 'Phòng đơn',
              'ROOM_SHARED': 'Ở ghép',
              'STUDIO': 'Studio',
              'ONE_BEDROOM': 'Căn hộ 1PN',
              'WHOLE_HOUSE': 'Nguyên căn',
            }.entries
            .map(
              (entry) => ActionChip(
                label: Text(entry.value),
                onPressed: () => controller.selectRoomType(entry.key),
              ),
            )
            .toList(growable: false),
  );
}

class _AmenitiesComposer extends ConsumerWidget {
  const _AmenitiesComposer({required this.selected, required this.controller});
  final Set<String> selected;
  final PreferenceChatController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amenities = ref.watch(amenitiesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        amenities.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => OutlinedButton.icon(
            onPressed: () => ref.invalidate(amenitiesProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tải lại tiện ích'),
          ),
          data: (items) => Wrap(
            spacing: 7,
            runSpacing: 7,
            children: items
                .map(
                  (item) => FilterChip(
                    label: Text(item.name),
                    selected: selected.contains(item.code),
                    showCheckmark: true,
                    onSelected: (_) => controller.toggleAmenity(item.code),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: controller.confirmAmenities,
          child: Text(selected.isEmpty ? 'Bỏ qua' : 'Tiếp tục'),
        ),
      ],
    );
  }
}

class _ExtrasComposer extends StatelessWidget {
  const _ExtrasComposer({required this.draft, required this.controller});
  final PreferenceDraft draft;
  final PreferenceChatController controller;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ToggleTile(
        icon: Icons.bathtub_outlined,
        title: 'WC khép kín',
        selected: draft.bathroomPrivate,
        onTap: controller.toggleBathroom,
      ),
      const SizedBox(height: 8),
      _ToggleTile(
        icon: Icons.balcony_outlined,
        title: 'Có ban công / thoáng gió',
        selected: draft.hasBalcony,
        onTap: controller.toggleBalcony,
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: controller.confirmExtras,
          child: const Text('Tiếp tục'),
        ),
      ),
    ],
  );
}

class _AlertComposer extends StatelessWidget {
  const _AlertComposer({required this.controller});
  final PreferenceChatController controller;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => controller.setAlerts(false),
          child: const Text('Không cần'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 2,
        child: FilledButton.icon(
          onPressed: () => controller.setAlerts(true),
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Có, thông báo cho tôi'),
        ),
      ),
    ],
  );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFE2F7F1) : const Color(0xFFF6F9F8),
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: selected ? _primaryDark : _muted),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? _primary : _muted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      const _AssistantAvatar(size: 30),
      const SizedBox(width: 7),
      Flexible(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
          ),
          child: Text(text, style: const TextStyle(height: 1.42, color: _ink)),
        ),
      ),
    ],
  );
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text, required this.onEdit});
  final String text;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 290),
      padding: const EdgeInsets.fromLTRB(13, 9, 8, 9),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.edit_outlined, size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PreferenceSummary extends StatelessWidget {
  const _PreferenceSummary({required this.draft});
  final PreferenceDraft draft;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _line),
    ),
    child: Column(
      children: [
        _SummaryRow(
          icon: Icons.school_outlined,
          label: 'Khu vực',
          value: draft.university ?? 'Chưa chọn',
        ),
        _SummaryRow(
          icon: Icons.payments_outlined,
          label: 'Ngân sách',
          value: formatVnd(draft.budgetMax),
        ),
        _SummaryRow(
          icon: Icons.radar_rounded,
          label: 'Khoảng cách',
          value: '${_radius(draft.radiusKm)} km',
        ),
        _SummaryRow(
          icon: Icons.home_outlined,
          label: 'Loại phòng',
          value: _roomTypeLabel(draft.roomType),
          last: true,
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _primaryDark),
            const SizedBox(width: 9),
            Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      if (!last) const Divider(height: 1, color: _line),
    ],
  );
}

class _RecommendationsInChat extends ConsumerWidget {
  const _RecommendationsInChat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(roomMatchesProvider);
    return matches.when(
      loading: () => const _LoadingRecommendations(),
      error: (error, _) => _RecommendationError(
        message: error.toString(),
        onRetry: () => ref.invalidate(roomMatchesProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const _AssistantBubble(
            text:
                'Mình chưa tìm thấy phòng phù hợp. Bạn thử tăng ngân sách hoặc mở rộng bán kính nhé.',
          );
        }
        return Column(
          children: [
            for (final match in items.take(3)) ...[
              _ChatRoomCard(
                match: match,
                onTap: () => context.push('/rooms/${match.room.id}'),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _ChatRoomCard extends StatelessWidget {
  const _ChatRoomCard({required this.match, required this.onTap});
  final RoomMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 84,
                    child: match.room.imageUrl == null
                        ? const ColoredBox(
                            color: Color(0xFFE5F4F0),
                            child: Icon(
                              Icons.home_work_outlined,
                              color: _primary,
                            ),
                          )
                        : Image.network(
                            match.room.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: Color(0xFFE5F4F0),
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              match.room.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2F7F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${match.matchScore}%',
                              style: const TextStyle(
                                color: _primaryDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${formatVnd(match.estimatedMonthlyCost)}/tháng',
                        style: const TextStyle(
                          color: _primaryDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        match.room.fullAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: _muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: _line),
            _MatchExplanation(match: match),
          ],
        ),
      ),
    ),
  );
}

class _MatchExplanation extends StatelessWidget {
  const _MatchExplanation({required this.match});

  final RoomMatch match;

  @override
  Widget build(BuildContext context) {
    final reasons = match.reasons.take(2).toList(growable: false);
    final tradeoff = match.tradeoffs.isEmpty ? null : match.tradeoffs.first;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F9F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: _primaryDark),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Vì sao phòng này được gợi ý?',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (reasons.isEmpty)
            Text(
              'Phòng đạt ${match.matchScore}% so với nhu cầu bạn vừa thiết lập.',
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.35,
                color: _muted,
              ),
            )
          else
            for (final reason in reasons)
              _MatchReasonRow(
                icon: Icons.check_circle_rounded,
                color: _primary,
                text: reason,
              ),
          if (tradeoff != null) ...[
            const SizedBox(height: 3),
            _MatchReasonRow(
              icon: Icons.info_outline_rounded,
              color: Color(0xFFE58A00),
              text: tradeoff,
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchReasonRow extends StatelessWidget {
  const _MatchReasonRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 10.5, height: 1.35, color: _muted),
          ),
        ),
      ],
    ),
  );
}

class _LoadingRecommendations extends StatelessWidget {
  const _LoadingRecommendations();
  @override
  Widget build(BuildContext context) => Container(
    height: 116,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _line),
    ),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: _primary),
        SizedBox(height: 9),
        Text('Đang tìm phòng phù hợp...', style: TextStyle(color: _muted)),
      ],
    ),
  );
}

class _RecommendationError extends StatelessWidget {
  const _RecommendationError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _line),
    ),
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Thử lại'),
        ),
      ],
    ),
  );
}

class _UniversitySheet extends StatefulWidget {
  const _UniversitySheet({required this.items});
  final List<UniversityLocation> items;

  @override
  State<_UniversitySheet> createState() => _UniversitySheetState();
}

class _UniversitySheetState extends State<_UniversitySheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final normalized = query.toLowerCase();
    final items = widget.items
        .where((item) => item.label.toLowerCase().contains(normalized))
        .toList(growable: false);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .76,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: _line,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Bạn muốn ở gần trường nào?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: TextField(
              autofocus: true,
              onChanged: (value) => setState(() => query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Tìm tên trường hoặc quận...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF3F7F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 58),
              itemBuilder: (_, index) {
                final item = items[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE2F7F1),
                    child: Icon(Icons.school_outlined, color: _primaryDark),
                  ),
                  title: Text(item.name),
                  subtitle: Text('${item.district} • ${item.address}'),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
    child: Icon(
      Icons.home_work_outlined,
      color: Colors.white,
      size: size * .55,
    ),
  );
}

class _DayLabel extends StatelessWidget {
  const _DayLabel();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'Hôm nay',
      style: TextStyle(
        fontSize: 11,
        color: _muted,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Không tải được nhu cầu, thử lại'),
    ),
  );
}

String _moneyShort(int value) {
  final millions = value / 1000000;
  return '${millions == millions.roundToDouble() ? millions.toInt() : millions.toStringAsFixed(1)} triệu';
}

String _radius(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String _roomTypeLabel(String? value) => switch (value) {
  'ROOM_SINGLE' => 'Phòng đơn',
  'ROOM_SHARED' => 'Ở ghép',
  'STUDIO' => 'Studio',
  'ONE_BEDROOM' => 'Căn hộ 1 phòng ngủ',
  'WHOLE_HOUSE' => 'Nguyên căn',
  _ => 'Tất cả loại phòng',
};
