import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/utils/uuid.dart';
import '../../catalog/domain/catalog_models.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../data/marketing_repository.dart';
import '../domain/marketing_models.dart';
import 'marketing_providers.dart';

/// ألوان جاهزة للبانر (الافتراضي = لون العلامة).
const List<String> _kPresetColors = <String>[
  '#107275',
  '#0B5759',
  '#2E9A9C',
  '#FFB300',
  '#E53935',
  '#15A05A',
  '#2F80ED',
  '#7C3AED',
  '#1B2424',
];

Color _hexToColor(String hex) {
  final String raw = hex.trim().replaceFirst('#', '');
  final int? v = raw.length == 6 ? int.tryParse(raw, radix: 16) : null;
  return v == null ? AppColors.primary : Color(0xFF000000 | v);
}

/// نموذج إنشاء/تعديل بانر ترويجي (صورة أو لون) مع تحريك الصورة داخل الإطار.
class BannerFormScreen extends ConsumerStatefulWidget {
  const BannerFormScreen({super.key, this.banner});

  final MarketingBanner? banner;

  @override
  ConsumerState<BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends ConsumerState<BannerFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final String _id = widget.banner?.id ?? uuidV4();
  late final TextEditingController _title = TextEditingController(text: widget.banner?.title ?? '');
  late final TextEditingController _titleFr = TextEditingController(text: widget.banner?.titleFr ?? '');
  late final TextEditingController _subtitle = TextEditingController(text: widget.banner?.subtitle ?? '');
  late final TextEditingController _subtitleFr = TextEditingController(text: widget.banner?.subtitleFr ?? '');
  late final TextEditingController _discount = TextEditingController(text: widget.banner?.discountLabel ?? '');
  late final TextEditingController _order = TextEditingController(text: '${widget.banner?.sortOrder ?? 0}');
  late String _categoryId = widget.banner?.targetCategoryId ?? '';

  late int _bgType = ((widget.banner?.imageUrl ?? '').trim().isEmpty) ? 1 : 0; // 0 صورة، 1 لون
  late String _color = (widget.banner?.backgroundColor ?? '').trim().isEmpty ? '#107275' : widget.banner!.backgroundColor!.trim();
  late Alignment _align = Alignment(
    (widget.banner?.imageAlignX ?? 0).clamp(-1, 1),
    (widget.banner?.imageAlignY ?? 0).clamp(-1, 1),
  );
  late double _scale = (widget.banner?.imageScale ?? 1) <= 0 ? 1 : (widget.banner?.imageScale ?? 1);

  XFile? _image;
  Uint8List? _bytes;
  bool _saving = false;

  bool get _isEdit => widget.banner != null;

  @override
  void dispose() {
    _title.dispose();
    _titleFr.dispose();
    _subtitle.dispose();
    _subtitleFr.dispose();
    _discount.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final XFile? file = await ImagePicker().pickImage(source: source, maxWidth: 2000, imageQuality: 90);
      if (file == null) {
        return;
      }
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _image = file;
        _bytes = bytes;
        _bgType = 0;
      });
    } on Object {
      // أُغلِق المنتقي أو فشل المصدر.
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final MarketingRepository repo = ref.read(marketingRepositoryProvider);
      String? imageUrl = widget.banner?.imageUrl;
      if (_bgType == 1) {
        imageUrl = null; // خلفية لون: لا صورة.
      } else if (_image != null) {
        imageUrl = await repo.uploadImage(file: _image!, bucket: 'banners', path: _id);
      }
      final Map<String, dynamic> values = <String, dynamic>{
        'title': _title.text.trim(),
        'title_fr': _titleFr.text.trim().isEmpty ? null : _titleFr.text.trim(),
        'subtitle': _subtitle.text.trim().isEmpty ? null : _subtitle.text.trim(),
        'subtitle_fr': _subtitleFr.text.trim().isEmpty ? null : _subtitleFr.text.trim(),
        'discount_label': _discount.text.trim().isEmpty ? null : _discount.text.trim(),
        'image_url': imageUrl,
        'background_color': _color,
        'image_align_x': double.parse(_align.x.toStringAsFixed(3)),
        'image_align_y': double.parse(_align.y.toStringAsFixed(3)),
        'image_scale': double.parse(_scale.toStringAsFixed(2)),
        'sort_order': int.tryParse(_order.text.trim()) ?? 0,
        'target_category_id': _categoryId.isEmpty ? null : _categoryId,
      };
      if (_isEdit) {
        await repo.updateBanner(widget.banner!.id, values);
      } else {
        await repo.createBanner(id: _id, values: <String, dynamic>{'is_active': true, ...values});
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t('فشل الحفظ')}: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<CatalogCategory> categories = ref.watch(catalogCategoriesProvider).valueOrNull ?? const <CatalogCategory>[];
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? t('تعديل البانر') : t('بانر جديد'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(t('نوع خلفية البانر'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: <ButtonSegment<int>>[
                ButtonSegment<int>(value: 0, label: Text(t('صورة')), icon: const Icon(Icons.image_outlined)),
                ButtonSegment<int>(value: 1, label: Text(t('لون')), icon: const Icon(Icons.palette_outlined)),
              ],
              selected: <int>{_bgType},
              onSelectionChanged: (Set<int> s) => setState(() => _bgType = s.first),
            ),
            const SizedBox(height: 14),
            if (_bgType == 0) ..._imageSection(theme) else ..._colorSection(theme),
            const SizedBox(height: 18),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: t('العنوان (عربي) *'), prefixIcon: const Icon(Icons.title_rounded)),
              validator: (String? value) => (value ?? '').trim().isEmpty ? t('أدخل عنوان البانر') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _titleFr, decoration: InputDecoration(labelText: t('العنوان (فرنسي)'))),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: TextFormField(controller: _subtitle, decoration: InputDecoration(labelText: t('النص الفرعي (عربي)')))), 
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _subtitleFr, decoration: InputDecoration(labelText: t('النص الفرعي (فرنسي)')))), 
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: TextFormField(controller: _discount, decoration: InputDecoration(labelText: t('شارة الخصم (مثال: -20%)')))),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _order, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t('ترتيب العرض')))),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: InputDecoration(labelText: t('التصنيف المستهدف (اختياري)'), prefixIcon: const Icon(Icons.category_outlined)),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: '', child: Text(t('بدون تصنيف'))),
                for (final CatalogCategory category in categories)
                  DropdownMenuItem<String>(value: category.id, child: Text(category.displayName)),
              ],
              onChanged: (String? value) => setState(() => _categoryId = value ?? ''),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text(t('حفظ')),
            ),
            if (_bgType == 0) ...[
              const SizedBox(height: 10),
              Text(t('نصيحة: اسحب الصورة داخل الإطار لتحريكها، واستعمل الشريط للتكبير.'), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _imageSection(ThemeData theme) {
    return <Widget>[
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: <Widget>[
            Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t('الأبعاد الموصى بها: 1080×430 بكسل (نسبة العرض:الارتفاع ≈ 2.5:1). سيُقتصّ ما يزيد حسب إطار البانر.'),
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _BannerCropper(
        bytes: _bytes,
        networkUrl: _image == null ? widget.banner?.imageUrl : null,
        align: _align,
        scale: _scale,
        onAlign: (Alignment a) => setState(() => _align = a),
        onScale: (double s) => setState(() => _scale = s),
        onGallery: () => _pick(ImageSource.gallery),
        onCamera: () => _pick(ImageSource.camera),
      ),
    ];
  }

  List<Widget> _colorSection(ThemeData theme) {
    return <Widget>[
      Text(t('اختر لون خلفية البانر'), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          for (final String c in _kPresetColors)
            GestureDetector(
              onTap: () => setState(() => _color = c),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _hexToColor(c),
                  shape: BoxShape.circle,
                  border: Border.all(color: _color.toUpperCase() == c.toUpperCase() ? Colors.white : Colors.transparent, width: 3),
                  boxShadow: <BoxShadow>[BoxShadow(color: _hexToColor(c).withValues(alpha: 0.5), blurRadius: 6)],
                ),
                child: _color.toUpperCase() == c.toUpperCase() ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
              ),
            ),
        ],
      ),
      const SizedBox(height: 14),
      Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _hexToColor(_color), borderRadius: BorderRadius.circular(12)),
        child: Text(t('معاينة لون الخلفية'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
    ];
  }
}

/// إطار البانر التفاعلي: يعرض الصورة بـ BoxFit.cover مع تحريك (سحب) وتكبير.
class _BannerCropper extends StatelessWidget {
  const _BannerCropper({
    required this.bytes,
    required this.networkUrl,
    required this.align,
    required this.scale,
    required this.onAlign,
    required this.onScale,
    required this.onGallery,
    required this.onCamera,
  });

  final Uint8List? bytes;
  final String? networkUrl;
  final Alignment align;
  final double scale;
  final ValueChanged<Alignment> onAlign;
  final ValueChanged<double> onScale;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  bool get _hasImage => bytes != null || (networkUrl ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.add_photo_alternate_outlined, size: 42, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
            const SizedBox(height: 6),
            Text(t('اختر صورة البانر'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );

    final Widget image = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover, alignment: align, errorBuilder: (_, _, _) => placeholder)
        : (networkUrl ?? '').trim().isNotEmpty
            ? Image.network(networkUrl!, fit: BoxFit.cover, alignment: align, errorBuilder: (_, _, _) => placeholder)
            : placeholder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 2.6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double w = constraints.maxWidth;
                final double h = constraints.maxHeight;
                return GestureDetector(
                  onPanUpdate: _hasImage
                      ? (DragUpdateDetails d) {
                          onAlign(Alignment(
                            (align.x - d.delta.dx / w * 2).clamp(-1.0, 1.0),
                            (align.y - d.delta.dy / h * 2).clamp(-1.0, 1.0),
                          ));
                        }
                      : null,
                  child: Transform.scale(scale: scale, child: image),
                );
              },
            ),
          ),
        ),
        if (_hasImage) ...[
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              const Icon(Icons.zoom_out_rounded, size: 18),
              Expanded(
                child: Slider(
                  value: scale.clamp(1.0, 2.5),
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  label: '×${scale.toStringAsFixed(1)}',
                  onChanged: onScale,
                ),
              ),
              const Icon(Icons.zoom_in_rounded, size: 18),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(_hasImage ? t('تغيير الصورة') : t('من المعرض')),
                onPressed: onGallery,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(t('الكاميرا')),
                onPressed: onCamera,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
