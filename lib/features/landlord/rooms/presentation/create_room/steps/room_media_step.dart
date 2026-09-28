import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/create_room_draft.dart';
import '../widgets/create_room_step_layout.dart';

class RoomMediaStep extends StatefulWidget {
  const RoomMediaStep({
    required this.draft,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final CreateRoomDraft draft;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<RoomMediaStep> createState() => _RoomMediaStepState();
}

class _RoomMediaStepState extends State<RoomMediaStep> {
  final _picker = ImagePicker();

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85, limit: 10);

    if (files.isNotEmpty) {
      widget.draft.addImages(files);
      setState(() {});
    }
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );

    if (file != null) {
      widget.draft.addVideo(file);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return CreateRoomStepLayout(
      step: 3,
      title: 'Hình ảnh & video',
      onBack: widget.onBack,
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
            'Hình ảnh rõ nét, chân thực để thu hút người thuê.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 14),
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
              itemBuilder: (_, index) {
                return Stack(
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
                          onPressed: () {
                            draft.removeImage(index);
                            setState(() {});
                          },
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
                );
              },
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Thêm ảnh'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_call_outlined),
                  label: Text(
                    draft.videos.isEmpty ? 'Thêm video' : 'Đổi video',
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
                onPressed: () => _addSpace(context),
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
                leading: const CircleAvatar(
                  child: Icon(Icons.meeting_room_outlined),
                ),
                title: Text(
                  space.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(space.description),
                trailing: IconButton(
                  onPressed: () {
                    draft.removeSpace(index);
                    setState(() {});
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _addSpace(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<RoomSpaceDraft>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm không gian'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên không gian',
                  hintText: 'Ví dụ: Ban công',
                ),
              ),
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
                    description: descriptionController.text.trim(),
                  ),
                );
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();

    if (result != null) {
      widget.draft.addSpace(result);
      setState(() {});
    }
  }
}
