import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (Ref ref) => DashboardRepository(ref.watch(supabaseClientProvider)),
);

/// الفترات المدعومة لسلسلة المبيعات.
const List<String> salesPeriods = <String>['today', 'week', 'month', 'year'];

final dashboardKpisProvider = FutureProvider<DashboardKpis>(
  (Ref ref) => ref.watch(dashboardRepositoryProvider).fetchKpis(),
);

final dashboardProductsProvider = FutureProvider<ProductReport>(
  (Ref ref) => ref.watch(dashboardRepositoryProvider).fetchProductPerformance(),
);

final salesPeriodProvider = StateProvider<String>((Ref ref) => 'today');

final salesSeriesProvider = FutureProvider.autoDispose<List<SalesPoint>>((Ref ref) {
  final String period = ref.watch(salesPeriodProvider);
  return ref.watch(dashboardRepositoryProvider).fetchSalesSeries(period);
});
