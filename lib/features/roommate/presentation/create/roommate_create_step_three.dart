import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/models/roommate_create_draft.dart';
import '../providers/roommate_create_provider.dart';
import 'widgets/roommate_create_bottom_bar.dart';

class RoommateCreateStepThree extends ConsumerStatefulWidget {
  const RoommateCreateStepThree({super.key});
  @override
  ConsumerState<RoommateCreateStepThree> createState() =>
      _RoommateCreateStepThreeState();
}

class _RoommateCreateStepThreeState
    extends ConsumerState<RoommateCreateStepThree> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  final _picker = ImagePicker();
  bool _pickingMedia = false;

  static const _tags = [
    'Không hút thuốc',
    'Ngủ sớm',
    'Thân thiện',
    'Yên tĩnh',
    'Gọn gàng',
    'Nuôi thú cưng',
  ];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(roommateCreateDraftProvider);
    _title = TextEditingController(text: draft.title);
    _description = TextEditingController(text: draft.description);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _saveText() {
    final draft = ref.read(roommateCreateDraftProvider);
    ref
        .read(roommateCreateDraftProvider.notifier)
        .update(
          draft.copyWith(
            title: _title.text.trim(),
            description: _description.text.trim(),
          ),
        );
  }

  Future<void> _pickImages() async {
    if (_pickingMedia) return;
    final draft = ref.read(roommateCreateDraftProvider);
    final remaining = 6 - draft.imageFiles.length;
    if (remaining <= 0) {
      _message('Bạn chỉ có thể thêm tối đa 6 ảnh.');
      return;
    }
    setState(() => _pickingMedia = true);
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: 85,
        limit: remaining,
      );
      if (files.isNotEmpty) {
        ref.read(roommateCreateDraftProvider.notifier).addImages(files);
      }
    } on PlatformException {
      _message('Ứng dụng chưa được cấp quyền truy cập ảnh.');
    } catch (_) {
      _message('Không thể chọn ảnh. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _pickingMedia = false);
    }
  }

  Future<void> _pickVideo() async {
    if (_pickingMedia) return;
    setState(() => _pickingMedia = true);
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file != null) {
        ref.read(roommateCreateDraftProvider.notifier).setVideo(file);
      }
    } on PlatformException {
      _message('Ứng dụng chưa được cấp quyền truy cập video.');
    } catch (_) {
      _message('Không thể chọn video. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _pickingMedia = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    _saveText();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final id = await ref.read(submitRoommatePostProvider.notifier).submit();
    if (!mounted) return;
    if (id == null) {
      final error = ref.read(submitRoommatePostProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Không thể đăng tin.')),
      );
      return;
    }
    ref.read(roommateCreateDraftProvider.notifier).reset();
    context.go('/roommate/create/success');
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(roommateCreateDraftProvider);
    final submitting = ref.watch(submitRoommatePostProvider).isLoading;
    final controller = ref.read(roommateCreateDraftProvider.notifier);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Thói quen & lối sống',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bước 3/3: Giúp mọi người hiểu bạn hơn',
                  style: TextStyle(color: Color(0xFF71807C)),
                ),
                const SizedBox(height: 18),
                _select<String>(
                  'Giờ về dự kiến',
                  draft.curfew,
                  const ['21:00', '22:00', '23:00', 'Giờ giấc tự do'],
                  (v) => controller.update(draft.copyWith(curfew: v)),
                ),
                _select<String>(
                  'Mức độ sạch sẽ',
                  draft.cleanliness,
                  const [
                    'Rất gọn gàng',
                    'Gọn gàng',
                    'Bình thường',
                    'Thoải mái',
                  ],
                  (v) => controller.update(draft.copyWith(cleanliness: v)),
                ),
                _switch(
                  'Hút thuốc',
                  draft.smoking,
                  (v) => controller.update(draft.copyWith(smoking: v)),
                ),
                _switch(
                  'Thường xuyên nấu ăn',
                  draft.cooking,
                  (v) => controller.update(draft.copyWith(cooking: v)),
                ),
                _switch(
                  'Nuôi thú cưng',
                  draft.pets,
                  (v) => controller.update(draft.copyWith(pets: v)),
                ),
                _switch(
                  'Thoải mái khi bạn bè đến chơi',
                  draft.guests,
                  (v) => controller.update(draft.copyWith(guests: v)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tags nổi bật (tối đa 12)',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _tags
                      .map(
                        (tag) => FilterChip(
                          label: Text('#$tag'),
                          selected: draft.lifestyleTags.contains(tag),
                          showCheckmark: false,
                          selectedColor: const Color(0xFF009B7D),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: draft.lifestyleTags.contains(tag)
                                ? const Color(0xFF009B7D)
                                : const Color(0xFFCAD8D4),
                          ),
                          labelStyle: TextStyle(
                            color: draft.lifestyleTags.contains(tag)
                                ? Colors.white
                                : const Color(0xFF33413E),
                            fontWeight: draft.lifestyleTags.contains(tag)
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          onSelected: (_) => controller.toggleTag(tag),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                _MediaPickerSection(
                  draft: draft,
                  disabled: submitting || _pickingMedia,
                  onPickImages: _pickImages,
                  onPickVideo: _pickVideo,
                  onRemoveImage: (index) => controller.removeImage(index),
                  onRemoveVideo: () => controller.setVideo(null),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _title,
                  maxLength: 180,
                  validator: (v) => (v?.trim().length ?? 0) < 10
                      ? 'Tiêu đề cần ít nhất 10 ký tự.'
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề',
                    hintText: 'Tìm bạn nữ ở ghép gần Phenikaa',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 3000,
                  validator: (v) => (v?.trim().length ?? 0) < 20
                      ? 'Mô tả cần ít nhất 20 ký tự.'
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    hintText:
                        'Mô tả phòng, vị trí và tiêu chí bạn cùng phòng...',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          RoommateCreateBottomBar(
            primaryLabel: 'Đăng tin',
            loading: submitting,
            onBack: () {
              _saveText();
              controller.previousStep();
            },
            onPrimary: _submit,
          ),
        ],
      ),
    );
  }

  Widget _select<T>(
    String label,
    T value,
    List<T> values,
    ValueChanged<T> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) =>
      Card(
        elevation: 0,
        color: Colors.white,
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF00A889),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
}

class _MediaPickerSection extends StatelessWidget {
  const _MediaPickerSection({
    required this.draft,
    required this.disabled,
    required this.onPickImages,
    required this.onPickVideo,
    required this.onRemoveImage,
    required this.onRemoveVideo,
  });

  final RoommateCreateDraft draft;
  final bool disabled;
  final VoidCallback onPickImages, onPickVideo, onRemoveVideo;
  final ValueChanged<int> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final images = draft.imageFiles;
    final videos = draft.videoFiles;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E3E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình ảnh & video',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Thêm tối đa 6 ảnh và 1 video để bài đăng dễ được quan tâm hơn.',
            style: TextStyle(fontSize: 12, color: Color(0xFF71807C)),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (_, index) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(images[index].path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: InkWell(
                      onTap: disabled ? null : () => onRemoveImage(index),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 15, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (videos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF7),
                borderRadius: BorderRadius.circular(11),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Color(0xFF009B7D),
                  size: 34,
                ),
                title: Text(
                  videos.first.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Video đã chọn'),
                trailing: IconButton(
                  tooltip: 'Xóa video',
                  onPressed: disabled ? null : onRemoveVideo,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: disabled || images.length >= 6
                      ? null
                      : onPickImages,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text('Thêm ảnh (${images.length}/6)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: disabled ? null : onPickVideo,
                  icon: const Icon(Icons.video_call_outlined),
                  label: Text(videos.isEmpty ? 'Thêm video' : 'Đổi video'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
