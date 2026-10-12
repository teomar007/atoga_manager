import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/employees_repository.dart';
import '../../../core/l10n/app_l10n.dart';

/// إنشاء حساب موظف (سائق أو معبئ) عبر دالة `admin-create-staff`.
class EmployeeCreateScreen extends ConsumerStatefulWidget {
  const EmployeeCreateScreen({super.key});

  @override
  ConsumerState<EmployeeCreateScreen> createState() => _EmployeeCreateScreenState();
}

class _EmployeeCreateScreenState extends ConsumerState<EmployeeCreateScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  String _role = 'driver';
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _fullName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(employeesRepositoryProvider).createStaff(
            username: _username.text.trim(),
            password: _password.text.trim(),
            role: _role,
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            fullName: _fullName.text.trim().isEmpty ? null : _fullName.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('تعذّر إنشاء الحساب: %s').replaceFirst('%s', '$error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t('إضافة موظف'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.info_outline_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(t('يُنشأ الحساب لدخول تطبيق التوصيل (سائق/معبئ)، ويُحجب عن تطبيق الإدارة.')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _username,
              keyboardType: TextInputType.text,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const <String>[AutofillHints.username],
              decoration: InputDecoration(
                labelText: t('اسم المستخدم *'),
                hintText: 'ex: driver01',
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              validator: (String? value) {
                final String username = (value ?? '').trim().toLowerCase();
                if (username.isEmpty) {
                  return t('أدخل اسم المستخدم');
                }
                // يطابق قواعد الخادم: حروف/أرقام/نقطة/شرطة، 3-30 حرفاً.
                if (!RegExp(r'^[a-z0-9][a-z0-9._-]{2,29}$').hasMatch(username)) {
                  return t('اسم المستخدم: 3-30 حرفاً (حروف/أرقام/نقطة/شرطة) فقط.');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: t('كلمة المرور *'),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscure ? t('إظهار') : t('إخفاء'),
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (String? value) {
                final String password = value?.trim() ?? '';
                if (password.length < 6) {
                  return t('كلمة المرور 6 أحرف على الأقل');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullName,
              decoration: InputDecoration(
                labelText: t('الاسم الكامل (اختياري)'),
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: t('رقم الهاتف (اختياري)'),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 18),
            Text(t('الدور'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'driver',
                    label: Text(t('سائق توصيل')),
                    icon: const Icon(Icons.delivery_dining_rounded),
                  ),
                  ButtonSegment<String>(
                    value: 'packager',
                    label: Text(t('معبئ طلبات')),
                    icon: const Icon(Icons.inventory_2_outlined),
                  ),
                  ButtonSegment<String>(
                    value: 'driver_packager',
                    label: Text(t('موظف')),
                    icon: const Icon(Icons.badge_outlined),
                  ),
                ],
                selected: <String>{_role},
                onSelectionChanged: (Set<String> selection) => setState(() => _role = selection.first),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t('«موظف» = يستطيع العمل كسائق توصيل ومعبئ طلبات معاً.'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t('إنشاء الحساب')),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                t('صلاحية الإنشاء مقصورة على المدير العام'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
