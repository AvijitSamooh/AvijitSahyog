import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';

class PendingAdminMedia {
  const PendingAdminMedia(this.file, this.purpose);
  final XFile file;
  final String purpose;
}

class AdminMediaSection extends StatefulWidget {
  const AdminMediaSection({
    super.key,
    required this.primaryPurpose,
    required this.title,
    this.api,
    this.entity,
    this.entityId,
    this.onPendingChanged,
    this.pickImage,
  });

  final ApiClient? api;
  final String? entity;
  final String? entityId;
  final String primaryPurpose;
  final String title;
  final ValueChanged<List<PendingAdminMedia>>? onPendingChanged;
  final Future<XFile?> Function()? pickImage;

  bool get attachedMode => api != null && entity != null && entityId != null;

  @override
  State<AdminMediaSection> createState() => _AdminMediaSectionState();
}

class _AdminMediaSectionState extends State<AdminMediaSection> {
  final _picker = ImagePicker();
  final List<PendingAdminMedia> _pending = [];
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.attachedMode) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await widget.api!.getAdminEntityMedia(widget.entity!, widget.entityId!);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick(String purpose) async {
    final file = await (widget.pickImage?.call() ?? _picker.pickImage(source: ImageSource.gallery, imageQuality: 90));
    if (file == null) return;
    if (!widget.attachedMode) {
      setState(() {
        if (purpose == widget.primaryPurpose) _pending.removeWhere((item) => item.purpose == purpose);
        _pending.add(PendingAdminMedia(file, purpose));
      });
      widget.onPendingChanged?.call(List.unmodifiable(_pending));
      return;
    }
    setState(() => _uploading = true);
    try {
      final uploaded = await widget.api!.uploadAdminImage(file.path);
      await widget.api!.attachAdminEntityMedia(widget.entity!, widget.entityId!, {
        'mediaId': uploaded['id'],
        'purpose': purpose,
        'isPrimary': purpose == widget.primaryPurpose,
        'displayOrder': _items.length,
      });
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();
    final l10n = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
      if (!widget.attachedMode && _pending.isNotEmpty)
        Wrap(children: _pending.map((item) => Chip(
          label: Text(item.purpose == widget.primaryPurpose ? l10n.adminPrimaryImageSelected : l10n.adminGalleryImageSelected),
          onDeleted: () { setState(() => _pending.remove(item)); widget.onPendingChanged?.call(List.unmodifiable(_pending)); },
        )).toList()),
      if (widget.attachedMode && _items.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _items.map((item) {
            final media = item['media'];
            return Chip(
              avatar: const Icon(Icons.image_outlined, size: 18),
              label: Text(item['purpose']?.toString() ?? 'IMAGE'),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
      Wrap(spacing: 8, children: [
        OutlinedButton.icon(onPressed: _uploading ? null : () => _pick(widget.primaryPurpose), icon: const Icon(Icons.image),
          label: Text(widget.attachedMode ? l10n.adminUploadPrimaryImage : l10n.adminSelectPrimaryImage)),
        OutlinedButton.icon(onPressed: _uploading ? null : () => _pick('GALLERY'), icon: const Icon(Icons.add_photo_alternate),
          label: Text(widget.attachedMode ? l10n.adminAddGalleryImage : l10n.adminSelectGalleryImage)),
      ]),
    ]);
  }
}