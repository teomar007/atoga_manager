import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../domain/employee_models.dart';
import 'employees_providers.dart';
import 'employees_screen.dart';

final NumberFormat _money = NumberFormat('#,##0');
final DateFormat _dayFormat = DateFormat('dd/MM/yyyy • HH:mm');

Color orderStatusColor(String status) {
  switch (status) {
    case 'delivered':
      return AppColors.success;
    case 'returned':
      return AppColors.danger;
    case 'cancelled':
      return Colors.grey;
    case 'on_the_way':
      return AppColors.info;
    default:
      return AppColors.warning;
  }
}

/// الصفحة التفصيلية لأداء موظف: كل الإحصاءات + آخر الطلبات.
class EmployeeStatsScreen extends ConsumerWidget {
  const EmployeeStatsScreen({super.key, required this.stats});

  final EmployeeStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Color color = employeeRoleColor(context, stats.role);
    final AsyncValue<List<EmployeeOrder>> orders = ref.watch(employeeOrdersProvider(stats.userId));
    final int pct = stats.successPercent;
    final Color rateColor = pct >= 80 ? AppColors.success : (pct >= 50 ? AppColors.warning : AppColors.danger);

    return Scaffold(
      appBar: AppBar(title: Text(stats.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(employeeRoleIcon(stats.role), color: color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(stats.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 8),
                            if (!stats.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: Text(t('مجمّد'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.danger)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text(t(stats.roleLabel), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                            ),
                            if (stats.username.isNotEmpty) ...<Widget>[
                              const SizedBox(width: 8),
                              Flexible(child: Text('@${stats.username}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.65)))),
                            ],
                          ],
                        ),
                        if (stats.email.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(stats.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(t('نسبة النجاح'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: rateColor)),
                      const SizedBox(width: 8),
                      Text('(${stats.delivered} ÷ ${stats.completed})', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                      const Spacer(),
                      Text('$pct%', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: rateColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: stats.completed == 0 ? 0 : stats.successRate.clamp(0, 1),
                      minHeight: 12,
                      backgroundColor: rateColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(t('المقياس = الطلبات الناجحة ÷ (الناجحة + الفاشلة). الطلبات الجارية لا تُحتسب.'), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _statsGrid(context),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              const Icon(Icons.receipt_long_rounded, size: 20),
              const SizedBox(width: 8),
              Text(t('آخر طلبات الموظف'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          orders.when(
            data: (List<EmployeeOrder> items) {
              if (items.isEmpty) {
                return Card(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(t('لا توجد طلبات بعد'), style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))))));
              }
              return Column(
                children: <Widget>[
                  for (final EmployeeOrder o in items) _OrderTile(order: o),
                ],
              );
            },
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (Object e, StackTrace s) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(t('تعذّر تحميل الطلبات: %s').replaceFirst('%s', '$e'), style: TextStyle(color: theme.colorScheme.error)))),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(BuildContext context) {
    final Color dual = const Color(0xFF7C3AED);
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            _DetailStat(label: t('طلبات مستلمة'), value: '${stats.received}', color: AppColors.info, icon: Icons.inbox_rounded),
            const SizedBox(width: 10),
            _DetailStat(label: t('طلبات ناجحة'), value: '${stats.delivered}', color: AppColors.success, icon: Icons.check_circle_rounded),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            _DetailStat(label: t('طلبات مرتجعة'), value: '${stats.returned}', color: AppColors.danger, icon: Icons.assignment_return_rounded),
            const SizedBox(width: 10),
            _DetailStat(label: t('قيد التنفيذ'), value: '${stats.inProgress}', color: AppColors.warning, icon: Icons.local_shipping_rounded),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            _DetailStat(label: t('متوسط التوصيل'), value: '${stats.avgDeliveryMin} ${t('دقيقة')}', color: dual, icon: Icons.timer_outlined),
            const SizedBox(width: 10),
            _DetailStat(label: t('الالتزام بالوقت'), value: '${stats.onTimePercent}%', color: AppColors.primaryLight, icon: Icons.schedule_rounded),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            _DetailStat(label: t('إجمالي القيمة المسلّمة'), value: '${_money.format(stats.totalRevenue)} $currency', color: AppColors.success, icon: Icons.payments_rounded),
            const SizedBox(width: 10),
            _DetailStat(
              label: t('آخر طلب'),
              value: stats.lastOrderAt == null ? '—' : DateFormat('dd/MM/yyyy').format(stats.lastOrderAt!),
              color: AppColors.textSecondary,
              icon: Icons.event_rounded,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(t('ملخص آخر 7 أيام'), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(child: _MiniStat(label: t('مستلمة'), value: '${stats.receivedLast7}', color: AppColors.info)),
                    const SizedBox(width: 10),
                    Expanded(child: _MiniStat(label: t('ناجحة'), value: '${stats.deliveredLast7}', color: AppColors.success)),
                    const SizedBox(width: 10),
                    Expanded(child: _MiniStat(label: t('مرتجعة'), value: '${stats.returnedLast7}', color: AppColors.danger)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value, required this.color, required this.icon});

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: color)),
              ),
              const SizedBox(height: 2),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.65))),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final EmployeeOrder order;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = orderStatusColor(order.status);
    final String shortId = order.id.length >= 8 ? order.id.substring(0, 8) : order.id;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(t(order.statusLabel), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('#$shortId', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    order.createdAt == null ? '—' : _dayFormat.format(order.createdAt!),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            Text('${_money.format(order.total)} $currency', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
