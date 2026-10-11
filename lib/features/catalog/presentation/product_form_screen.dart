import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/translation_service.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/widgets/image_pick_field.dart';
import '../../../core/utils/uuid.dart';
import '../data/catalog_repository.dart';
import '../domain/catalog_models.dart';
import 'catalog_providers.dart';

/// نموذج إنشاء/تعديل منتج: الاسم بالعربية والفرنسية، السعر، سعر العرض،
/// التصنيف، الوحدة، والصورة (معرض/كاميرا → Supabase Storage).
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product, required this.categories});

  final CatalogProduct? product;
  final List<CatalogCategory> categories;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final String _id = widget.product?.id ?? uuidV4();
  late final TextEditingController _nameAr = TextEditingController(text: widget.product?.name ?? '');
  late final TextEditingController _nameFr = TextEditingController(text: widget.product?.nameFr ?? '');
  late final TextEditingController _price =
      TextEditingController(text: widget.product == null ? '' : '${widget.product!.price}');
  late final TextEditingController _oldPrice =
      TextEditingController(text: widget.product?.oldPrice?.toString() ?? '');
  late final TextEditingController _unit = TextEditingController(text: widget.product?.unit ?? '');
  late String _categoryId = widget.product?.categoryId ?? '';
  XFile? _image;
  bool _saving = false;
  Timer? _frDebounce;
  bool _frManual = false;
  bool _settingFr = false;
  bool _translating = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameFr.addListener(_markFrManual);
  }

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
    _price.dispose();
    _oldPrice.dispose();
    _unit.dispose();
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
      final double price = double.parse(_price.text.trim());
      final double? oldPrice = double.tryParse(_oldPrice.text.trim());
      final bool isPromo = oldPrice != null && oldPrice > price && price > 0;

      String? imageUrl = widget.product?.imageUrl;
      if (_image != null) {
        imageUrl = await repo.uploadImage(file: _image!, bucket: 'product-images', path: _id);
      }

      final Map<String, dynamic> values = <String, dynamic>{
        'name': _nameAr.text.trim(),
        'name_fr': _nameFr.text.trim().isEmpty ? null : _nameFr.text.trim(),
        'price': price,
        'old_price': oldPrice,
        'is_promo': isPromo,
        'image_url': imageUrl,
        'unit': _unit.text.trim().isEmpty ? null : _unit.text.trim(),
        'category_id': _categoryId.isEmpty ? null : _categoryId,
      };

      if (_isEdit) {
        await repo.updateProduct(widget.product!.id, values);
      } else {
        await repo.createProduct(<String, dynamic>{'id': _id, 'is_active': true, ...values});
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
      appBar: AppBar(title: Text(_isEdit ? t('تعديل المنتج') : t('منتج جديد'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            ImagePickField(file: _image, networkUrl: widget.product?.imageUrl, onPicked: (XFile? file) => setState(() => _image = file)),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameAr,
              onChanged: (_) => _scheduleTranslate(),
              decoration: InputDecoration(labelText: t('الاسم (عربي) *'), prefixIcon: const Icon(Icons.shopping_basket_outlined)),
              validator: (String? value) => (value ?? '').trim().isEmpty ? t('أدخل اسم المنتج') : null,
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
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: t('السعر (دج) *'), prefixIcon: const Icon(Icons.attach_money_rounded)),
                    validator: (String? value) {
                      final double? v = double.tryParse((value ?? '').trim());
                      return (v == null || v <= 0) ? t('سعر صالح مطلوب') : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _oldPrice,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: t('سعر العرض* (اختياري)'), prefixIcon: const Icon(Icons.sell_outlined)),
                    validator: (String? value) {
                      final String v = (value ?? '').trim();
                      if (v.isEmpty) {
                        return null;
                      }
                      final double? d = double.tryParse(v);
                      return (d == null || d <= 0) ? t('قيمة غير صالحة') : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: InputDecoration(labelText: t('التصنيف'), prefixIcon: const Icon(Icons.category_outlined)),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: '', child: Text(t('بدون تصنيف'))),
                for (final CatalogCategory category in widget.categories)
                  DropdownMenuItem<String>(value: category.id, child: Text(category.displayName)),
              ],
              onChanged: (String? value) => setState(() => _categoryId = value ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unit,
              decoration: InputDecoration(labelText: t('الوحدة (علبة/كيس/لتر...)')),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text(t('حفظ')),
            ),
            const SizedBox(height: 8),
            Text(
              t('* سعر العرض: يظهر السعر الحالي مع السعر القديم مشطوباً وشارة خصم في تطبيق الزبون.'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
