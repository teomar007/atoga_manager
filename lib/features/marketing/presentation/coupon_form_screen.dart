import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/marketing_repository.dart';
import '../domain/marketing_models.dart';
import '../../../core/l10n/app_l10n.dart';
import 'marketing_providers.dart';

final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

/// نموذج كوبون متقدم: نوع الخصم، الشروط، الصلاحية، والاستخدام.
class CouponFormScreen extends ConsumerStatefulWidget {
  const CouponFormScreen({super.key, this.coupon});

  final MarketingCoupon? coupon;

  @override
  ConsumerState<CouponFormScreen> createState() => _CouponFormScreenState();
}

class _CouponFormScreenState extends ConsumerState<CouponFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _code = TextEditingController(text: widget.coupon?.code ?? '');
  late final TextEditingController _title = TextEditingController(text: widget.coupon?.title ?? '');
  late final TextEditingController _value =
      TextEditingController(text: (widget.coupon?.discountValue ?? 0) > 0 ? '${widget.coupon!.discountValue}' : '');
  late final TextEditingController _minOrder =
      TextEditingController(text: (widget.coupon?.minOrder ?? 0) > 0 ? '${widget.coupon!.minOrder}' : '');
  late final TextEditingController _maxDiscount =
      TextEditingController(text: (widget.coupon?.maxDiscount ?? 0) > 0 ? '${widget.coupon!.maxDiscount}' : '');
  late final TextEditingController _usage = TextEditingController(text: widget.coupon?.usageLimitPerUser?.toString() ?? '');
  late String _type = widget.coupon?.discountType ?? 'percent';
  late DateTime? _startsAt = widget.coupon?.startsAt;
  late DateTime? _expiresAt = widget.coupon?.expiresAt;
  late bool _welcome = widget.coupon?.isWelcome ?? false;
  bool _saving = false;

  bool get _isEdit => widget.coupon != null;
  bool get _isFreeShipping => _type == 'free_shipping';
  bool get _isPercent => _type == 'percent';

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _value.dispose();
    _minOrder.dispose();
    _maxDiscount.dispose();
    _usage.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startsAt ?? DateTime.now()) : (_expiresAt ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
    if (picked != null) {
      setState(() => isStart ? _startsAt = picked : _expiresAt = picked);
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
      final double value = _isFreeShipping ? 0 : (double.tryParse(_value.text.trim()) ?? 0);
      final Map<String, dynamic> values = <String, dynamic>{
        'code': _code.text.trim().toUpperCase(),
        'title': _title.text.trim().isEmpty ? null : _title.text.trim(),
        'starts_at': _startsAt?.toUtc().toIso8601String(),
        'expires_at': _expiresAt?.toUtc().toIso8601String(),
        'discount_type': _type,
        'discount_value': value,
        'min_order': double.tryParse(_minOrder.text.trim()) ?? 0,
        'max_discount': _isPercent ? (double.tryParse(_maxDiscount.text.trim())) : null,
        'free_shipping': _isFreeShipping,
        'usage_limit_per_user': int.tryParse(_usage.text.trim()),
        'is_welcome': _welcome,
      };
      if (_isEdit) {
        await repo.updateCoupon(widget.coupon!.id, values);
      } else {
        await repo.createCoupon(<String, dynamic>{'is_active': true, ...values});
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
      appBar: AppBar(title: Text(_isEdit ? t('تعديل الكوبون') : t('كوبون جديد'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(labelText: t('الكود *'), prefixIcon: const Icon(Icons.tag_rounded)),
                    validator: (String? value) {
                      final String v = (value ?? '').trim();
                      return v.isEmpty ? t('أدخل الكود') : (v.length < 3 ? t('كود قصير جداً') : null);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _title,
                    decoration: InputDecoration(labelText: t('العنوان (اختياري)')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(labelText: t('نوع الخصم *'), prefixIcon: const Icon(Icons.percent_rounded)),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'percent', child: Text(t('نسبة من قيمة الطلب'))),
                DropdownMenuItem<String>(value: 'fixed', child: Text(t('مبلغ ثابت'))),
                DropdownMenuItem<String>(value: 'free_shipping', child: Text(t('توصيل مجاني'))),
              ],
              onChanged: (String? value) => setState(() => _type = value ?? 'percent'),
            ),
            const SizedBox(height: 12),
            if (!_isFreeShipping)
              TextFormField(
                controller: _value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _isPercent ? t('النسبة (%) *') : t('قيمة الخصم (دج) *'),
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
                validator: (String? value) => double.tryParse((value ?? '').trim()) == null ? t('قيمة مطلوبة') : null,
              )
            else
              Text(t('التوصيل مجاني تلقائياً عند تحقق شرط الحد الأدنى')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minOrder,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: t('الحد الأدنى للطلب (دج)'),
                hintText: t('مثال: 3000 = توصيل مجاني فوق 3000 دج'),
                prefixIcon: const Icon(Icons.low_priority_rounded),
              ),
            ),
            if (_isPercent) ...<Widget>[
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxDiscount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: t('سقف الخصم (دج، اختياري)'), prefixIcon: const Icon(Icons.sell_rounded)),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: _DateField(label: t('بداية الصلاحية'), value: _startsAt, onTap: () => _pickDate(isStart: true))),
                const SizedBox(width: 10),
                Expanded(child: _DateField(label: t('نهاية الصلاحية'), value: _expiresAt, onTap: () => _pickDate(isStart: false))),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usage,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t('الاستخدام لكل مستخدم'),
                hintText: t('1 = مرة واحدة فقط (كوبون ترحيبي)'),
                prefixIcon: const Icon(Icons.repeat_rounded),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _welcome,
              title: Text(t('كوبون ترحيبي (استخدام واحد)')),
              subtitle: Text(t('يُمنح للمستخدمين الجدد')),
              onChanged: (bool value) => setState(() => _welcome = value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text(t('حفظ')),
            ),
            const SizedBox(height: 8),
            Text(
              t('ملاحظة: تطبيق الزبون الحالي يعرض الكوبونات فقط؛ تفعيل الحساب التلقائي يُضاف في تحديثه القادم.'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: value == null ? null : Icon(Icons.clear_rounded, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
        ),
        child: Text(
          value == null ? t('غير محدد') : _dateFormat.format(value!),
          style: TextStyle(color: value == null ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4) : null),
        ),
      ),
    );
  }
}
