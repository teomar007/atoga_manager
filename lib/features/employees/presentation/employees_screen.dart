import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../data/employees_repository.dart';
import '../domain/employee_models.dart';
import 'employee_create_screen.dart';
import 'employee_stats_screen.dart';
import 'employees_providers.dart';

/// الموظفون: إدارة الحسابات + إحصاءات الأداء.
class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  int _tab = 0; // 0 الموظفون، 1 أداء الموظفين
  bool _busy = false;
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(employeesListProvider);
    ref.invalidate(employeeStatsProvider);
    try {
      await Future.wait<void>(<Future<void>>[
        ref.read(employeesListProvider.future).then((_) {}),
        ref.read(employeeStatsProvider.future).then((_) {}),
      ]);
    } on Object {
      // تُعرض حالة الخطأ من المزوّد.
    }
  }

  Future<void> _add() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const EmployeeCreateScreen()),
    );
    if (saved == true) {
      ref.invalidate(employeesListProvider);
      ref.invalidate(employeeStatsProvider);
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
      _snack(t('تعذّرت العملية: %s').replaceFirst('%s', _friendly(error)), error: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _friendly(Object error) {
    final String raw = error.toString();
    if (raw.contains('forbidden')) {
      return t('غير مصرّح.');
    }
    if (raw.contains('primary_admin_immutable')) {
      return t('الحساب الرئيسي محمي.');
    }
    return raw.replaceFirst('Exception: ', '');
  }

  Future<void> _toggleActive(StaffMember m) {
    return _run(
      () => ref.read(employeesRepositoryProvider).setEmployeeActive(userId: m.id, active: !m.isActive),
      m.isActive ? t('تم تجميد الحساب.') : t('تم تفعيل الحساب.'),
    );
  }

  Future<void> _confirmDelete(StaffMember m) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(t('حذف الحساب')),
        content: Text(t('سيُحذف حساب «%s» نهائياً مع ملفه ودوره. متابعة؟').replaceFirst('%s', m.displayName)),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('إلغاء'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('حذف نهائي')),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    await _run(() => ref.read(employeesRepositoryProvider).deleteEmployee(m.id), t('تم حذف الحساب.'));
  }

  Future<void> _openEdit(StaffMember m) async {
    final _EmployeeEdit? result = await showDialog<_EmployeeEdit>(
      context: context,
      builder: (BuildContext context) => _EditEmployeeDialog(member: m),
    );
    if (result == null) {
      return;
    }
    await _run(
      () => ref.read(employeesRepositoryProvider).updateEmployee(
            userId: m.id,
            username: result.username,
            fullName: result.fullName,
            phone: result.phone,
            role: result.role,
          ),
      t('تم حفظ التعديلات.'),
    );
  }

  Future<void> _openPassword(StaffMember m) async {
    final String? password = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _PasswordDialog(member: m),
    );
    if (password == null) {
      return;
    }
    await _run(
      () => ref.read(employeesRepositoryProvider).changePassword(userId: m.id, newPassword: password),
      t('تم تغيير كلمة المرور.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<StaffMember>> staff = ref.watch(employeesListProvider);
    final AsyncValue<List<EmployeeStats>> stats = ref.watch(employeeStatsProvider);

    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: <ButtonSegment<int>>[
                          ButtonSegment<int>(value: 0, label: Text(t('الموظفون'))),
                          ButtonSegment<int>(value: 1, label: Text(t('أداء الموظفين'))),
                        ],
                        selected: <int>{_tab},
                        onSelectionChanged: (Set<int> selection) => setState(() => _tab = selection.first),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_tab == 0)
                    IconButton.filledTonal(
                      tooltip: t('إضافة موظف'),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      onPressed: _busy ? null : _add,
                    ),
                ],
              ),
            ),
            if (_tab == 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: t('ابحث باسم الموظف أو اسم المستخدم'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
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
                child: _tab == 0 ? _staffList(staff) : _statsList(stats),
              ),
            ),
          ],
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x22000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _staffList(AsyncValue<List<StaffMember>> value) {
    return value.when(
      data: (List<StaffMember> items) {
        if (items.isEmpty) {
          return _empty(t('لا يوجد موظفون'), t('اضغط + لإضافة أول سائق أو معبئ أو موظف'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final StaffMember m = items[index];
            return _StaffTile(
              member: m,
              busy: _busy,
              onToggle: () => _toggleActive(m),
              onEdit: () => _openEdit(m),
              onPassword: () => _openPassword(m),
              onDelete: () => _confirmDelete(m),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _empty(t('تعذّر تحميل الموظفين'), '$error'),
    );
  }

  Widget _statsList(AsyncValue<List<EmployeeStats>> value) {
    return value.when(
      data: (List<EmployeeStats> items) {
        final String q = _search.text.trim().toLowerCase();
        final List<EmployeeStats> filtered = q.isEmpty
            ? items
            : items
                .where((EmployeeStats s) =>
                    s.displayName.toLowerCase().contains(q) ||
                    s.username.toLowerCase().contains(q) ||
                    s.email.toLowerCase().contains(q))
                .toList();
        if (items.isEmpty) {
          return _empty(t('لا توجد بيانات أداء'), t('ستظهر هنا بعد إنشاء موظف وتوزيع الطلبات'));
        }
        if (filtered.isEmpty) {
          return _empty(t('لا نتائج'), t('لا يوجد موظف مطابق لبحثك'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) => _StatsCard(
            stats: filtered[index],
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => EmployeeStatsScreen(stats: filtered[index])),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _empty(t('تعذّر تحميل المؤشرات'), '$error'),
    );
  }

  Widget _empty(String title, String hint) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        const SizedBox(height: 120),
        Icon(Icons.groups_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(hint, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
      ],
    );
  }
}

IconData employeeRoleIcon(String role) {
  switch (role) {
    case 'driver':
      return Icons.delivery_dining_rounded;
    case 'packager':
      return Icons.inventory_2_outlined;
    case 'driver_packager':
      return Icons.badge_outlined;
    default:
      return Icons.person_outline_rounded;
  }
}

Color employeeRoleColor(BuildContext context, String role) {
  switch (role) {
    case 'driver':
      return AppColors.info;
    case 'packager':
      return AppColors.success;
    case 'driver_packager':
      return const Color(0xFF7C3AED);
    default:
      return Theme.of(context).colorScheme.primary;
  }
}

/// بطاقة إحصاء كبيرة وواضحة.
class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.color, required this.icon});

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats, required this.onTap});

  final EmployeeStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = employeeRoleColor(context, stats.role);
    final int pct = stats.successPercent;
    final Color rateColor = pct >= 80 ? AppColors.success : (pct >= 50 ? AppColors.warning : AppColors.danger);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(employeeRoleIcon(stats.role), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                stats.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (!stats.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: Text(t('مجمّد'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.danger)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text(t(stats.roleLabel), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                            ),
                            if (stats.username.isNotEmpty) ...<Widget>[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '@${stats.username}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  _StatBox(label: t('مستلمة'), value: '${stats.received}', color: AppColors.info, icon: Icons.inbox_rounded),
                  const SizedBox(width: 8),
                  _StatBox(label: t('ناجحة'), value: '${stats.delivered}', color: AppColors.success, icon: Icons.check_circle_rounded),
                  const SizedBox(width: 8),
                  _StatBox(label: t('مرتجعة'), value: '${stats.returned}', color: AppColors.danger, icon: Icons.assignment_return_rounded),
                  const SizedBox(width: 8),
                  _StatBox(label: t('جارية'), value: '${stats.inProgress}', color: AppColors.warning, icon: Icons.local_shipping_rounded),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Text(t('نسبة النجاح'), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: rateColor)),
                  const SizedBox(width: 8),
                  Text('(${stats.delivered} ÷ ${stats.completed})', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                  const Spacer(),
                  Text('$pct%', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: rateColor)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: stats.completed == 0 ? 0 : stats.successRate.clamp(0, 1),
                  minHeight: 9,
                  backgroundColor: rateColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${t('متوسط التوصيل')} ${stats.avgDeliveryMin} ${t('دقيقة')} • ${t('الالتزام بالوقت')} ${stats.onTimePercent}% • ${t('أُنجز آخر 7 أيام')} ${stats.deliveredLast7}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _EmpAction { toggle, edit, password, delete }

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.member,
    required this.busy,
    required this.onToggle,
    required this.onEdit,
    required this.onPassword,
    required this.onDelete,
  });

  final StaffMember member;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onPassword;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = employeeRoleColor(context, member.role);
    final String secondary = <String>[
      if (member.username != null) '@${member.username}',
      if (member.phone != null) member.phone!,
    ].join(' • ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(employeeRoleIcon(member.role), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          member.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (!member.isActive) _frozenBadge(),
                    ],
                  ),
                  if (secondary.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(t(member.roleLabel), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ),
            PopupMenuButton<_EmpAction>(
              enabled: !busy,
              tooltip: t('خيارات'),
              onSelected: (_EmpAction action) {
                switch (action) {
                  case _EmpAction.toggle:
                    onToggle();
                  case _EmpAction.edit:
                    onEdit();
                  case _EmpAction.password:
                    onPassword();
                  case _EmpAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<_EmpAction>>[
                PopupMenuItem<_EmpAction>(
                  value: _EmpAction.toggle,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(member.isActive ? Icons.ac_unit_rounded : Icons.play_circle_outline_rounded),
                    title: Text(member.isActive ? t('تجميد الحساب') : t('تفعيل الحساب')),
                  ),
                ),
                PopupMenuItem<_EmpAction>(
                  value: _EmpAction.edit,
                  child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.edit_outlined), title: Text(t('تعديل البيانات'))),
                ),
                PopupMenuItem<_EmpAction>(
                  value: _EmpAction.password,
                  child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.lock_reset_rounded), title: Text(t('تغيير كلمة المرور'))),
                ),
                PopupMenuItem<_EmpAction>(
                  value: _EmpAction.delete,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    title: Text(t('حذف الحساب'), style: const TextStyle(color: AppColors.danger)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _frozenBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: Text(t('مجمّد'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.danger)),
    );
  }
}

/// بيانات نموذج تعديل الموظف.
class _EmployeeEdit {
  const _EmployeeEdit({required this.username, required this.fullName, required this.phone, required this.role});

  final String username;
  final String fullName;
  final String phone;
  final String role;
}

class _EditEmployeeDialog extends StatefulWidget {
  const _EditEmployeeDialog({required this.member});

  final StaffMember member;

  @override
  State<_EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<_EditEmployeeDialog> {
  late final TextEditingController _username = TextEditingController(text: widget.member.username ?? '');
  late final TextEditingController _fullName = TextEditingController(text: widget.member.fullName);
  late final TextEditingController _phone = TextEditingController(text: widget.member.phone ?? '');
  late String _role = widget.member.role;
  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.pop(
      context,
      _EmployeeEdit(
        username: _username.text.trim(),
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
        role: _role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t('تعديل بيانات الموظف')),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _username,
                decoration: InputDecoration(labelText: t('اسم المستخدم')),
                validator: (String? value) {
                  final String v = value?.trim() ?? '';
                  if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{2,29}$').hasMatch(v)) {
                    return t('من 3 إلى 30 حرفاً (حروف/أرقام/نقطة/شرطة)');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(controller: _fullName, decoration: InputDecoration(labelText: t('الاسم الكامل'))),
              const SizedBox(height: 10),
              TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: t('رقم الهاتف'))),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: InputDecoration(labelText: t('المهام')),
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'driver', child: Text(t('سائق توصيل'))),
                  DropdownMenuItem<String>(value: 'packager', child: Text(t('معبئ طلبات'))),
                  DropdownMenuItem<String>(value: 'driver_packager', child: Text(t('موظف (سائق ومعبئ)'))),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() => _role = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t('إلغاء'))),
        FilledButton(onPressed: _save, child: Text(t('حفظ'))),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.member});

  final StaffMember member;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _save() {
    final String p = _password.text.trim();
    if (p.length < 6) {
      setState(() => _error = t('كلمة المرور 6 أحرف على الأقل.'));
      return;
    }
    if (p != _confirm.text.trim()) {
      setState(() => _error = t('كلمتا المرور غير متطابقتين.'));
      return;
    }
    Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t('تغيير كلمة المرور')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(t('الحساب: %s').replaceFirst('%s', widget.member.displayName), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: t('كلمة المرور الجديدة'),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(controller: _confirm, obscureText: _obscure, decoration: InputDecoration(labelText: t('تأكيد كلمة المرور'))),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t('إلغاء'))),
        FilledButton(onPressed: _save, child: Text(t('حفظ'))),
      ],
    );
  }
}
