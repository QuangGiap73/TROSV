import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/create_room_draft.dart';
import '../widgets/create_room_step_layout.dart';

class RoomMediaStep extends StatefulWidget {
  const RoomMediaStep({
    required this.draft,
    required this.onBack,
    required this.onNext,
    required this.isSaving,
    super.key,
  });

  final CreateRoomDraft draft;
  final VoidCallback onBack, onNext;
  final bool isSaving;

  @override
  State<RoomMediaStep> createState() => _RoomMediaStepState();
}

class _RoomMediaStepState extends State<RoomMediaStep> {
  final _picker = ImagePicker();
  bool _pickingVideo = false;
  CreateRoomDraft get draft => widget.draft;

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85, limit: 10);
    if (files.isNotEmpty) setState(() => draft.addImages(files));
  }

  Future<void> _pickVideo() async {
    if (_pickingVideo) return;
    setState(() => _pickingVideo = true);
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      setState(() => draft.addVideo(file));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã thêm video ${file.name}.')));
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'photo_access_denied'
                ? 'Ứng dụng chưa được cấp quyền truy cập video.'
                : 'Không thể chọn video. Vui lòng thử lại.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đọc video đã chọn.')),
      );
    } finally {
      if (mounted) setState(() => _pickingVideo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreateRoomStepLayout(
      step: 3,
      title: 'Hình ảnh, video & không gian',
      onBack: widget.onBack,
      isLoading: widget.isSaving,
      onNext: () {
        if (!draft.hasMedia) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hãy chọn ít nhất một ảnh phòng.')),
          );
          return;
        }
        widget.onNext();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ảnh sẽ được upload trực tiếp lên storage và xác nhận với phòng nháp.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 14),
          if (draft.existingImages.isNotEmpty) ...[
            const Text(
              'Ảnh hiện tại',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: draft.existingImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: 1.4,
              ),
              itemBuilder: (_, index) {
                final media = draft.existingImages[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        media.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFE8F0EE),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 5,
                      top: 5,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 15,
                          color: Colors.white,
                          onPressed: () =>
                              setState(() => draft.removeExistingMedia(media)),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ),
                    if (media.isPrimary)
                      const Positioned(
                        left: 7,
                        bottom: 7,
                        child: Chip(
                          label: Text('Ảnh đại diện'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          if (draft.images.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: draft.images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: 1.4,
              ),
              itemBuilder: (_, index) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(draft.images[index].path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 5,
                    top: 5,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 15,
                        color: Colors.white,
                        onPressed: () =>
                            setState(() => draft.removeImage(index)),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                  if (index == 0)
                    const Positioned(
                      left: 7,
                      bottom: 7,
                      child: Chip(
                        label: Text('Ảnh đại diện'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          if (draft.existingVideos.isNotEmpty || draft.videos.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Video phòng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...draft.existingVideos.map(
              (media) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _VideoFileCard(
                  title: 'Video hiện tại',
                  subtitle: media.url,
                  uploaded: true,
                  onRemove: widget.isSaving
                      ? null
                      : () => setState(() => draft.removeExistingMedia(media)),
                ),
              ),
            ),
            if (draft.videos case [final video])
              _VideoFileCard(
                title: video.name,
                subtitle: 'Video mới · ${_fileExtension(video.name)}',
                file: video,
                onRemove: widget.isSaving
                    ? null
                    : () => setState(draft.removeVideo),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.isSaving ? null : _pickImages,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Thêm ảnh'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.isSaving || _pickingVideo
                      ? null
                      : _pickVideo,
                  icon: _pickingVideo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.video_call_outlined),
                  label: Text(
                    draft.videos.isEmpty && draft.existingVideos.isEmpty
                        ? 'Thêm video'
                        : 'Đổi video',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Không gian phòng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: widget.isSaving ? null : _addSpace,
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(draft.spaces.length, (index) {
            final space = draft.spaces[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    space.privacyType == 'PRIVATE'
                        ? Icons.lock_outline
                        : Icons.groups_outlined,
                  ),
                ),
                title: Text(
                  space.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${space.description}\n'
                  '${space.privacyType == 'PRIVATE' ? 'Riêng tư' : 'Dùng chung'}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      tooltip: 'Quyền sử dụng',
                      onSelected: (value) => setState(() {
                        space.privacyType = value;
                        draft.changed();
                      }),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'PRIVATE',
                          child: Text('Riêng tư'),
                        ),
                        PopupMenuItem(
                          value: 'SHARED',
                          child: Text('Dùng chung'),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => setState(() => draft.removeSpace(index)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _addSpace() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    var privacyType = 'PRIVATE';
    final result = await showDialog<RoomSpaceDraft>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm không gian'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên không gian',
                  hintText: 'VD: Ban công',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: privacyType,
                decoration: const InputDecoration(labelText: 'Quyền sử dụng'),
                items: const [
                  DropdownMenuItem(value: 'PRIVATE', child: Text('Riêng tư')),
                  DropdownMenuItem(value: 'SHARED', child: Text('Dùng chung')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => privacyType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(
                  context,
                  RoomSpaceDraft(
                    type: 'OTHER',
                    title: titleController.text.trim(),
                    privacyType: privacyType,
                    description: descriptionController.text.trim(),
                  ),
                );
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
    if (result != null) setState(() => draft.addSpace(result));
  }
}

class _VideoFileCard extends StatelessWidget {
  const _VideoFileCard({
    required this.title,
    required this.subtitle,
    required this.onRemove,
    this.file,
    this.uploaded = false,
  });

  final String title;
  final String subtitle;
  final XFile? file;
  final bool uploaded;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FAF7),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFBCE7DD)),
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFDAF3ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.play_circle_fill_rounded,
            size: 32,
            color: Color(0xFF009B7D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF687773), fontSize: 12),
              ),
              if (file != null)
                FutureBuilder<int>(
                  future: file!.length(),
                  builder: (_, snapshot) => Text(
                    snapshot.hasData
                        ? _formatFileSize(snapshot.data!)
                        : 'Đang đọc dung lượng...',
                    style: const TextStyle(
                      color: Color(0xFF00866D),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (uploaded)
                const Text(
                  'Đã tải lên',
                  style: TextStyle(
                    color: Color(0xFF00866D),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Xóa video',
          onPressed: onRemove,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
          ),
        ),
      ],
    ),
  );
}

String _fileExtension(String filename) {
  final separator = filename.lastIndexOf('.');
  if (separator < 0 || separator == filename.length - 1) return 'VIDEO';
  return filename.substring(separator + 1).toUpperCase();
}

String _formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '$bytes B';
}
