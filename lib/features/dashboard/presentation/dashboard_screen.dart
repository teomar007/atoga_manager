import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../domain/dashboard_models.dart';
import 'dashboard_providers.dart';

final NumberFormat _money = NumberFormat('#,##0');

String _moneyStr(double value) => '${_money.format(value)} $currency';

/// لوحة المعلومات: KPI يومية + منحنى المبيعات حسب الفترة + أداء المنتجات.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardKpisProvider);
    ref.invalidate(dashboardProductsProvider);
    ref.invalidate(salesSeriesProvider);
    final List<Future<void>> futures = <Future<void>>[
      ref.read(dashboardKpisProvider.future).then((_) {}),
      ref.read(dashboardProductsProvider.future).then((_) {}),
      ref.read(salesSeriesProvider.future).then((_) {}),
    ];
    try {
      await Future.wait<void>(futures);
    } on Object {
      // تُعرض حالة الخطأ من المزوّد مباشرة.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DashboardKpis> kpis = ref.watch(dashboardKpisProvider);
    final AsyncValue<List<SalesPoint>> series = ref.watch(salesSeriesProvider);
    final AsyncValue<ProductReport> products = ref.watch(dashboardProductsProvider);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _HeroCard(kpis: kpis),
          const SizedBox(height: 14),
          _SecondaryKpis(kpis: kpis),
          const SizedBox(height: 18),
          _SalesChartCard(series: series),
          const SizedBox(height: 18),
          _ProductSections(report: products),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.kpis});

  final AsyncValue<DashboardKpis> kpis;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final double salesToday = kpis.valueOrNull?.salesToday ?? 0;
    final int deliveredToday = kpis.valueOrNull?.deliveredToday ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(t('مبيعات اليوم'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            _moneyStr(salesToday),
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                '$deliveredToday ${t('طلب مسلّم')}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryKpis extends StatelessWidget {
  const _SecondaryKpis({required this.kpis});

  final AsyncValue<DashboardKpis> kpis;

  @override
  Widget build(BuildContext context) {
    final DashboardKpis? k = kpis.valueOrNull;
    return Row(
      children: <Widget>[
        Expanded(
          child: _SmallKpi(
            label: t('طلبات قيد الانتظار'),
            value: '${k?.pendingOrders ?? 0}',
            icon: Icons.schedule_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SmallKpi(
            label: t('إجمالي الطلبات'),
            value: '${k?.totalOrders ?? 0}',
            icon: Icons.receipt_long_rounded,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SmallKpi(
            label: t('متوسط الطلب'),
            value: _moneyStr(k?.avgOrderValue ?? 0),
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _SmallKpi extends StatelessWidget {
  const _SmallKpi({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesChartCard extends ConsumerWidget {
  const _SalesChartCard({required this.series});

  final AsyncValue<List<SalesPoint>> series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String period = ref.watch(salesPeriodProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(t('تحليل المبيعات'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'today', label: Text(t('اليوم'))),
                  ButtonSegment<String>(value: 'week', label: Text(t('أسبوع'))),
                  ButtonSegment<String>(value: 'month', label: Text(t('شهر'))),
                  ButtonSegment<String>(value: 'year', label: Text(t('سنة'))),
                ],
                selected: <String>{period},
                onSelectionChanged: (Set<String> selection) {
                  ref.read(salesPeriodProvider.notifier).state = selection.first;
                },
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 230,
              child: series.when(
                data: (List<SalesPoint> points) => _LineChart(points: points),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace stack) => _ChartError(message: '$error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.points});

  final List<SalesPoint> points;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    if (points.isEmpty) {
      return Center(child: Text(t('لا توجد بيانات'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))));
    }

    final double maxY = points.fold<double>(0, (double m, SalesPoint p) => math.max(m, p.revenue));
    final int n = points.length;
    final int step = math.max(1, (n / 6).ceil());

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 10 : maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY <= 0 ? 5 : (maxY / 4),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) => Text(
                _money.format(value),
                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int i = value.toInt();
                if (i < 0 || i >= n || (i % step != 0 && i != n - 1)) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    points[i].label,
                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: <FlSpot>[
              for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].revenue),
            ],
            isCurved: true,
            color: primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: primary.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}

class _ChartError extends StatelessWidget {
  const _ChartError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        t('تعذّر تحميل التحليلات'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _ProductSections extends StatelessWidget {
  const _ProductSections({required this.report});

  final AsyncValue<ProductReport> report;

  @override
  Widget build(BuildContext context) {
    return report.when(
      data: (ProductReport value) => Column(
        children: <Widget>[
          _ProductCard(title: t('الأعلى مبيعاً'), items: value.top, icon: Icons.trending_up_rounded, color: AppColors.success),
          const SizedBox(height: 14),
          _ProductCard(title: t('الأقل مبيعاً'), items: value.least, icon: Icons.trending_down_rounded, color: AppColors.danger),
        ],
      ),
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))),
      error: (Object error, StackTrace stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(t('تعذّر تحميل أداء المنتجات'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.title, required this.items, required this.icon, required this.color});

  final String title;
  final List<ProductPerformance> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(t('لا توجد بيانات'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)))
            else
              for (int i = 0; i < items.length; i++)
                _ProductRow(index: i + 1, item: items[i]),
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.index, required this.item});

  final int index;
  final ProductPerformance item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            child: Text('$index', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(
                  '${item.quantity} ${t('قطعة')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          Text(_moneyStr(item.revenue), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
