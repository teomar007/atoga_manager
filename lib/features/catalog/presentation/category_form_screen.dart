import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/translation_service.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/utils/uuid.dart';
import '../../../core/widgets/image_pick_field.dart';
import '../data/catalog_repository.dart';
import '../domain/catalog_models.dart';
import 'catalog_providers.dart';

/// نموذج إنشاء/تعديل تصنيف: الاسم بالعربية والفرنسية، الترتيب، والصورة.
class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.category});

  final CatalogCategory? category;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final String _id = widget.category?.id ?? uuidV4();
  late final TextEditingController _nameAr = TextEditingController(text: widget.category?.nameAr ?? '');
  late final TextEditingController _nameFr = TextEditingController(text: widget.category?.nameFr ?? '');
  late final TextEditingController _order =
      TextEditingController(text: '${widget.category?.displayOrder ?? 0}');
  XFile? _image;
  bool _saving = false;
  Timer? _frDebounce;
  bool _frManual = false;
  bool _settingFr = false;
  bool _translating = false;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameFr.addListener(_markFrManual);
  }

  /// أي تعديل يدوي على الحقل الفرنسي يوقف الترجمة التلقائية (يبقى الحقل مفتوحاً).
  void _markFrManual() {
    if (!_settingFr) {
      _frManual = true;
    }
  }

  void _scheduleTranslate() {
    _frDebounce?.cancel();
    _frDebounce = Timer(const Duration(milliseconds: 700), _translate);
  }

  Future<void> _translate() async {
    if (_frManual) {
      return;
    }
    final String text = _nameAr.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _translating = true);
    final String? translated = await ref.read(translationServiceProvider).toFrench(text);
    if (!mounted) {
      return;
    }
    setState(() {
      _translating = false;
      if (!_frManual && translated != null) {
        _settingFr = true;
        _nameFr.text = translated;
        _settingFr = false;
      }
    });
  }

  @override
  void dispose() {
    _frDebounce?.cancel();
    _nameFr.removeListener(_markFrManual);
    _nameAr.dispose();
    _nameFr.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final CatalogRepository repo = ref.read(catalogRepositoryProvider);
      String? iconUrl = widget.category?.iconUrl;
      if (_image != null) {
        iconUrl = await repo.uploadImage(file: _image!, bucket: 'category-icons', path: _id);
      }
      final Map<String, dynamic> values = <String, dynamic>{
        'name_ar': _nameAr.text.trim(),
        'name_fr': _nameFr.text.trim().isEmpty ? null : _nameFr.text.trim(),
        'display_order': int.tryParse(_order.text.trim()) ?? 0,
        'icon_url': iconUrl,
      };
      if (_isEdit) {
        await repo.updateCategory(widget.category!.id, values);
      } else {
        await repo.createCategory(id: _id, values: <String, dynamic>{'is_active': true, ...values});
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? t('تعديل التصنيف') : t('تصنيف جديد'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            ImagePickField(file: _image, networkUrl: widget.category?.iconUrl, onPicked: (XFile? file) => setState(() => _image = file)),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameAr,
              onChanged: (_) => _scheduleTranslate(),
              decoration: InputDecoration(labelText: t('الاسم (عربي) *'), prefixIcon: const Icon(Icons.category_outlined)),
              validator: (String? value) => (value ?? '').trim().isEmpty ? t('أدخل اسم التصنيف') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameFr,
              decoration: InputDecoration(
                labelText: t('الاسم (فرنسي)'),
                helperText: t('يُترجم تلقائياً من العربية (قابل للتعديل)'),
                suffixIcon: _translating
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t('ترتيب العرض'), prefixIcon: const Icon(Icons.format_list_numbered_rounded)),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text(t('حفظ')),
            ),
          ],
        ),
      ),
    );
  }
}
