import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_l10n.dart';
/// معاينة صورة (مختارة محلياً أو من رابط) + أزرار اختيار من المعرض أو الكاميرا.
///
/// يعرض الصورة المختارة من البايتات مباشرةً ليعمل على الويب والأجهزة.
class ImagePickField extends StatefulWidget {
  const ImagePickField({super.key, this.file, this.networkUrl, required this.onPicked, this.height = 180});

  /// الصورة المختارة حديثاً (لها الأولوية في العرض).
  final XFile? file;

  /// رابط الصورة المحفوظة مسبقاً (تُعرض إن لم تُختر صورة جديدة).
  final String? networkUrl;

  final ValueChanged<XFile?> onPicked;
  final double height;

  @override
  State<ImagePickField> createState() => _ImagePickFieldState();
}

class _ImagePickFieldState extends State<ImagePickField> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  @override
  void didUpdateWidget(covariant ImagePickField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file?.path != widget.file?.path) {
      _loadBytes();
    }
  }

  Future<void> _loadBytes() async {
    final XFile? file = widget.file;
    if (file == null) {
      if (mounted) {
        setState(() {
          _bytes = null;
        });
      }
      return;
    }
    try {
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted || widget.file?.path != file.path) {
        return;
      }
      setState(() {
        _bytes = bytes;
      });
    } on Object {
      if (mounted) {
        setState(() {
          _bytes = null;
        });
      }
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1440,
        imageQuality: 85,
      );
      if (file != null) {
        widget.onPicked(file);
      }
    } on Object {
      // أُغلِق المنتقي دون نتيجة أو فشل مصدر الصورة: بلا أثر.
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      child: Center(
        child: Icon(Icons.add_photo_alternate_outlined, size: 46, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
      ),
    );

    final Widget preview;
    if (widget.file != null) {
      preview = _bytes == null
          ? const Center(child: CircularProgressIndicator())
          : Image.memory(_bytes!, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder);
    } else if ((widget.networkUrl ?? '').trim().isNotEmpty) {
      preview = Image.network(widget.networkUrl!.trim(), fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder);
    } else {
      preview = placeholder;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(height: widget.height, child: preview),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(t('من المعرض')),
                onPressed: () => _pick(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(t('الكاميرا')),
                onPressed: () => _pick(ImageSource.camera),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
