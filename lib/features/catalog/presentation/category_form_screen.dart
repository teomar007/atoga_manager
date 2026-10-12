import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/translation_service.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/utils/uuid.dart';
import '../data/catalog_repository.dart';
import '../domain/catalog_models.dart';
import 'catalog_providers.dart';
import 'category_icons.dart';

/// نموذج إنشاء/تعديل تصنيف: الاسم بالعربية والفرنسية، الترتيب، وأيقونة (لا صورة).
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
  late String _iconName = _validIcon(widget.category?.iconName);
  bool _saving = false;
  Timer? _frDebounce;
  bool _frManual = false;
  bool _settingFr = false;
  bool _translating = false;

  bool get _isEdit => widget.category != null;

  /// يضمن أن الاسم المخزَّن ضمن قائمتنا، وإلا يعود للافتراضي.
  static String _validIcon(String? name) {
    if (name == null || name.isEmpty) {
      return 'shopping_basket';
    }
    // اسم قديم شائع → الاسم الجديد في قائمتنا.
    if (name == 'cleaning') {
      return 'cleaning_services';
    }
    for (final CategoryIconOption option in kCategoryIcons) {
      if (option.name == name) {
        return name;
      }
    }
    return 'shopping_basket';
  }

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
      final Map<String, dynamic> values = <String, dynamic>{
        'name_ar': _nameAr.text.trim(),
        'name_fr': _nameFr.text.trim().isEmpty ? null : _nameFr.text.trim(),
        'display_order': int.tryParse(_order.text.trim()) ?? 0,
        // أيقونة بدل الصورة: نُخزّن اسم الأيقونة ونمسح أي صورة قديمة.
        'icon_name': _iconName,
        'icon_url': null,
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
            _IconPicker(
              selected: _iconName,
              onSelected: (String name) => setState(() => _iconName = name),
            ),
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

/// منتقي الأيقونات: معاينة + بحث بالاسم + شبكة أيقونات قابلة للتغيير.
class _IconPicker extends StatefulWidget {
  const _IconPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<_IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<_IconPicker> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<CategoryIconOption> get _filtered {
    final String q = _query.text.trim().toLowerCase();
    if (q.isEmpty) {
      return kCategoryIcons;
    }
    return kCategoryIcons
        .where((CategoryIconOption o) =>
            o.name.contains(q) ||
            o.labelAr.contains(q) ||
            o.labelFr.toLowerCase().contains(q) ||
            o.keywords.toLowerCase().contains(q))
        .toList();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    final String q = value.trim().toLowerCase();
    for (final CategoryIconOption option in kCategoryIcons) {
      if (option.name == q) {
        widget.onSelected(option.name);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<CategoryIconOption> filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(t('أيقونة التصنيف'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(categoryIconFor(widget.selected), size: 32, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: _query,
                autocorrect: false,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: t('اسم الأيقونة'),
                  hintText: 'ex: local_drink',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: _onQueryChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          t('اكتب اسم الأيقونة أو اختر من القائمة'),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              t('لا توجد أيقونات مطابقة'),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final CategoryIconOption option in filtered)
                _IconTile(
                  option: option,
                  selected: option.name == widget.selected,
                  onTap: () {
                    widget.onSelected(option.name);
                    FocusScope.of(context).unfocus();
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.option, required this.selected, required this.onTap});

  final CategoryIconOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Tooltip(
      message: '${option.labelAr} • ${option.labelFr}\n${option.name}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(
            option.icon,
            size: 26,
            color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
