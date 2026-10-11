import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../data/customers_repository.dart';
import '../domain/customer_models.dart';
import 'customers_providers.dart';

/// قسم الزبائن: قائمة بأسماء الزبائن وإحصاءاتهم مع بحث وتجميد/تفعيل.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(customersProvider);
    try {
      await ref.read(customersProvider(_query).future);
    } on Object {
      // تُعرض حالة الخطأ من المزوّد.
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? AppColors.danger : null),
    );
  }

  Future<void> _toggleFrozen(CustomerRow customer) async {
    if (customer.isFrozen) {
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(t('تفعيل الحساب')),
          content: Text(t('سيُرفع التجميد عن «%s» ويستطيع الشراء مجدداً. متابعة؟').replaceFirst('%s', customer.displayName)),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('إلغاء'))),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t('تفعيل'))),
          ],
        ),
      );
      if (ok != true) {
        return;
      }
      await _run(
        () => ref.read(customersRepositoryProvider).setFrozen(userId: customer.userId, frozen: false),
        t('تم تفعيل حساب الزبون.'),
      );
      return;
    }

    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _FreezeReasonDialog(),
    );
    if (reason == null) {
      return;
    }
    await _run(
      () => ref.read(customersRepositoryProvider).setFrozen(userId: customer.userId, frozen: true, reason: reason),
      t('تم تجميد الحساب.'),
    );
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      _snack(success);
      await _refresh();
    } on Object catch (error) {
      final String raw = error.toString();
      _snack(raw.contains('forbidden') ? t('غير مصرّح.') : t('تعذّرت العملية: %s').replaceFirst('%s', raw), error: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CustomerRow>> customers = ref.watch(customersProvider(_query));
    final ThemeData theme = Theme.of(context);

    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: t('ابحث بالاسم أو رقم الهاتف أو المعرّف'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            _debounce?.cancel();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: customers.when(
                  data: (List<CustomerRow> items) {
                    if (items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: <Widget>[
                          const SizedBox(height: 120),
                          Icon(Icons.people_outline_rounded, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.35)),
                          const SizedBox(height: 14),
                          Text(_query.isEmpty ? t('لا يوجد زبائن') : t('لا نتائج مطابقة'), textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(_query.isEmpty ? t('سيظهر الزبائن هنا') : t('جرّب بحثاً آخر'), textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (BuildContext context, int index) => _CustomerTile(
                        customer: items[index],
                        busy: _busy,
                        onToggle: () => _toggleFrozen(items[index]),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (Object error, StackTrace stack) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      const SizedBox(height: 120),
                      Icon(Icons.error_outline_rounded, size: 56, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text('${t('تعذّر تحميل الزبائن')}\n$error', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(color: Color(0x22000000), child: Center(child: CircularProgressIndicator())),
          ),
      ],
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer, required this.busy, required this.onToggle});

  final CustomerRow customer;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color avatarColor = customer.isFrozen ? AppColors.danger : theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 22,
              backgroundColor: avatarColor.withValues(alpha: 0.14),
              child: Text(
                customer.displayName.isEmpty ? '?' : customer.displayName.substring(0, 1).toUpperCase(),
                style: TextStyle(color: avatarColor, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // السطر الأول: الاسم + رقم الهاتف
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          customer.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if ((customer.phone ?? '').isNotEmpty) ...<Widget>[
                        const SizedBox(width: 8),
                        Icon(Icons.phone_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 3),
                        Text(
                          customer.phone!,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3),
                        ),
                      ],
                      const SizedBox(width: 8),
                      if (customer.isFrozen)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                          child: Text(t('مجمّد'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.danger)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // السطر الثاني: إحصاءات الطلبات
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: <Widget>[
                      _StatChip(label: t('الطلبات'), value: customer.ordersTotal, color: AppColors.info),
                      _StatChip(label: t('مستلمة'), value: customer.ordersDelivered, color: AppColors.success),
                      _StatChip(label: t('ملغاة'), value: customer.ordersCancelled, color: AppColors.danger),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              enabled: !busy,
              tooltip: t('خيارات'),
              onSelected: (String value) {
                if (value == 'toggle') {
                  onToggle();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'toggle',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      customer.isFrozen ? Icons.play_circle_outline_rounded : Icons.ac_unit_rounded,
                      color: customer.isFrozen ? AppColors.success : AppColors.danger,
                    ),
                    title: Text(customer.isFrozen ? t('تفعيل الحساب') : t('تجميد الحساب')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// شريحة إحصاء صغيرة ملوّنة (عدد الطلبات/المسلّمة/الملغاة).
class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('$value', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FreezeReasonDialog extends StatefulWidget {
  const _FreezeReasonDialog();

  @override
  State<_FreezeReasonDialog> createState() => _FreezeReasonDialogState();
}

class _FreezeReasonDialogState extends State<_FreezeReasonDialog> {
  static const List<String> _presets = <String>[
    'عملية شراء وهمية',
    'عدم استلام الطلبات',
    'إساءة استخدام الخدمة',
  ];
  final TextEditingController _reason = TextEditingController(text: _presets.first);

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _reason.text.trim();
    if (value.isEmpty) {
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t('تجميد حساب الزبون')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(t('سيظهر هذا السبب للزبون عند دخوله، ويُمنع من الشراء.')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String preset in _presets)
                ActionChip(
                  label: Text(t(preset)),
                  onPressed: () => setState(() => _reason.text = preset),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            maxLines: 2,
            decoration: InputDecoration(labelText: t('سبب التجميد'), border: const OutlineInputBorder()),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t('إلغاء'))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: _submit,
          child: Text(t('تجميد')),
        ),
      ],
    );
  }
}
