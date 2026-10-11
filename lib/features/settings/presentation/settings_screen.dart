import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../delivery_zones/data/delivery_zones_repository.dart';
import '../../delivery_zones/domain/delivery_zone_models.dart';
import '../../delivery_zones/presentation/delivery_zones_providers.dart';
import '../data/support_links_repository.dart';
import 'locale_controller.dart';

/// صفحة الإعدادات: اختيار لغة عرض التطبيق (عربي/فرنسي) وحفظها في الحساب.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String lang = ref.watch(localeControllerProvider);
    final ThemeData theme = Theme.of(context);

    void select(String code) {
      final String? userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
      ref.read(localeControllerProvider.notifier).setLanguage(code, userId: userId);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(t('اللغة'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          t('اختر لغة عرض التطبيق. يُحفظ اختيارك في حسابك ويُطبَّق تلقائياً عند الدخول.'),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: <Widget>[
              _LanguageTile(
                label: t('العربية'),
                icon: Icons.language_rounded,
                selected: lang == 'ar',
                onTap: () => select('ar'),
              ),
              const Divider(height: 1),
              _LanguageTile(
                label: 'Français',
                icon: Icons.language_rounded,
                selected: lang == 'fr',
                onTap: () => select('fr'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _SupportLinksSection(),
        const SizedBox(height: 20),
        const _DeliveryZonesSection(),
      ],
    );
  }
}

/// قسم إعدادات الدعم والتواصل المعروضة في تطبيق الزبون.
class _SupportLinksSection extends ConsumerStatefulWidget {
  const _SupportLinksSection();

  @override
  ConsumerState<_SupportLinksSection> createState() => _SupportLinksSectionState();
}

class _SupportLinksSectionState extends ConsumerState<_SupportLinksSection> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _whatsapp = TextEditingController();
  final TextEditingController _facebook = TextEditingController();
  final TextEditingController _instagram = TextEditingController();
  final TextEditingController _tiktok = TextEditingController();
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phone.dispose();
    _whatsapp.dispose();
    _facebook.dispose();
    _instagram.dispose();
    _tiktok.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final Map<String, String> values = await ref.read(supportLinksRepositoryProvider).fetchAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _phone.text = values['contact_phone'] ?? '';
        _whatsapp.text = values['whatsapp_number'] ?? '';
        _facebook.text = values['facebook'] ?? '';
        _instagram.text = values['instagram'] ?? '';
        _tiktok.text = values['tiktok'] ?? '';
        _loading = false;
      });
    } on Object {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(supportLinksRepositoryProvider).saveAll(<String, String>{
        'contact_phone': _phone.text,
        'whatsapp_number': _whatsapp.text,
        'facebook': _facebook.text,
        'instagram': _instagram.text,
        'tiktok': _tiktok.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('تم حفظ إعدادات التواصل. يظهر التحديث فوراً في تطبيق الزبون.'))),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('تعذّر الحفظ')}: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _field(TextEditingController controller, String label, String hint, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: controller,
        keyboardType: type,
        enabled: !_loading,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.headset_mic_outlined, color: theme.colorScheme.primary),
        title: Text(t('الدعم والتواصل في تطبيق الزبون'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Text(
          t('تُقرأ هذه القيم من تطبيق الزبون في قسمي «اتصل بنا» و«تواصل اجتماعي».'),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: <Widget>[
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          _field(_phone, t('رقم الهاتف — زر «اتصل بنا»'), t('مثال: +213551234567'), TextInputType.phone),
          _field(_whatsapp, t('رقم واتساب'), t('مثال: 0555123456 أو +213555123456'), TextInputType.phone),
          _field(_facebook, t('رابط فيسبوك'), 'https://facebook.com/', TextInputType.url),
          _field(_instagram, t('رابط إنستغرام'), 'https://instagram.com/', TextInputType.url),
          _field(_tiktok, t('رابط تيك توك'), 'https://tiktok.com/', TextInputType.url),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_busy || _loading) ? null : _save,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(t('حفظ إعدادات التواصل')),
            ),
          ),
        ],
      ),
    );
  }
}

/// قسم مناطق التوصيل (قائمة منسدلة قابلة للفتح والإغلاق).
class _DeliveryZonesSection extends ConsumerStatefulWidget {
  const _DeliveryZonesSection();

  @override
  ConsumerState<_DeliveryZonesSection> createState() => _DeliveryZonesSectionState();
}

class _DeliveryZonesSectionState extends ConsumerState<_DeliveryZonesSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
      ref.invalidate(deliveryZonesProvider);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('تعذّرت العملية')}: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openForm([DeliveryZone? zone]) async {
    final _ZoneInput? input = await showDialog<_ZoneInput>(
      context: context,
      builder: (BuildContext context) => _ZoneDialog(zone: zone),
    );
    if (input == null) {
      return;
    }
    final DeliveryZonesRepository repo = ref.read(deliveryZonesRepositoryProvider);
    if (zone == null) {
      await _run(() => repo.create(name: input.name, deliveryFee: input.fee), t('تم حفظ المنطقة.'));
    } else {
      await _run(() => repo.update(zone.id, name: input.name, deliveryFee: input.fee), t('تم حفظ المنطقة.'));
    }
  }

  Future<void> _confirmDelete(DeliveryZone zone) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(t('حذف المنطقة')),
        content: Text(t('سيُحذف «%s» نهائياً. متابعة؟').replaceFirst('%s', zone.name)),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('إلغاء'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('حذف')),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    await _run(() => ref.read(deliveryZonesRepositoryProvider).delete(zone.id), t('تم حذف المنطقة.'));
  }

  Future<void> _toggleActive(DeliveryZone zone) {
    return _run(
      () => ref.read(deliveryZonesRepositoryProvider).setActive(zone.id, !zone.isActive),
      zone.isActive ? t('تم إخفاء المنطقة.') : t('تم إظهار المنطقة.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<DeliveryZone>> zones = ref.watch(deliveryZonesProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.map_outlined, color: theme.colorScheme.primary),
        title: Text(t('مناطق التوصيل'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Text(
          t('تُعرض للزبون في قائمة اختيار منطقة التوصيل، وتُحدَّث تلقائياً في تطبيقه.'),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: <Widget>[
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          _zonesList(zones),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _openForm(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(t('إضافة منطقة')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zonesList(AsyncValue<List<DeliveryZone>> zones) {
    return zones.when(
      data: (List<DeliveryZone> items) {
        if (items.isEmpty) {
          return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(t('لا توجد مناطق توصيل')));
        }
        return Column(
          children: <Widget>[
            for (final DeliveryZone zone in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: <Widget>[
                    Flexible(child: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (!zone.isActive) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(t('مخفية'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.orange)),
                      ),
                    ],
                  ],
                ),
                subtitle: Text('${zone.deliveryFee.toStringAsFixed(0)} $currency'),
                leading: Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary),
                onTap: _busy ? null : () => _openForm(zone),
                trailing: zone.usageCount == 0
                    ? IconButton(
                        tooltip: t('حذف'),
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: _busy ? null : () => _confirmDelete(zone),
                      )
                    : IconButton(
                        tooltip: zone.isActive ? t('إخفاء') : t('إظهار'),
                        icon: Icon(zone.isActive ? Icons.visibility_off_outlined : Icons.visibility_rounded, color: Colors.blueGrey),
                        onPressed: _busy ? null : () => _toggleActive(zone),
                      ),
              ),
            const Divider(height: 1),
          ],
        );
      },
      loading: () => const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stack) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('${t('تعذّر تحميل مناطق التوصيل')}: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

class _ZoneInput {
  const _ZoneInput({required this.name, required this.fee});
  final String name;
  final double fee;
}

class _ZoneDialog extends StatefulWidget {
  const _ZoneDialog({this.zone});

  final DeliveryZone? zone;

  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.zone?.name ?? '');
  late final TextEditingController _fee = TextEditingController(text: widget.zone == null ? '' : '${widget.zone!.deliveryFee}');

  @override
  void dispose() {
    _name.dispose();
    _fee.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.pop(
      context,
      _ZoneInput(name: _name.text.trim(), fee: double.tryParse(_fee.text.trim().replaceAll(',', '.')) ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.zone == null ? t('منطقة توصيل جديدة') : t('تعديل منطقة التوصيل')),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: t('اسم المنطقة *')),
              validator: (String? value) => (value ?? '').trim().isEmpty ? t('أدخل اسم المنطقة') : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _fee,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: t('سعر التوصيل (دج) *')),
              validator: (String? value) {
                final double? v = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                return (v == null || v < 0) ? t('قيمة غير صالحة') : null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t('إلغاء'))),
        FilledButton(onPressed: _save, child: Text(t('حفظ'))),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: selected ? primary : null),
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
      trailing: selected ? Icon(Icons.check_circle_rounded, color: primary) : null,
    );
  }
}
