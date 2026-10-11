import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/dashboard_models.dart';

/// استدعاء الدوال التحليلية الآمنة (تُرفض على الخادم لغير موظفي الإدارة).
class DashboardRepository {
  const DashboardRepository(this._client);

  final SupabaseClient _client;

  Future<DashboardKpis> fetchKpis() async {
    final dynamic result = await _client.rpc('admin_dashboard_kpis');
    return DashboardKpis.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<List<SalesPoint>> fetchSalesSeries(String period) async {
    final dynamic result = await _client.rpc(
      'admin_sales_series',
      params: <String, dynamic>{'p_period': period},
    );
    if (result is! List) {
      return const <SalesPoint>[];
    }
    return result
        .map((dynamic e) => SalesPoint.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ProductReport> fetchProductPerformance({int limit = 5}) async {
    final dynamic result = await _client.rpc(
      'admin_product_performance',
      params: <String, dynamic>{'p_limit': limit},
    );
    final Map<String, dynamic> map = Map<String, dynamic>.from(result as Map);
    return ProductReport(top: _products(map['top']), least: _products(map['least']));
  }

  List<ProductPerformance> _products(Object? value) {
    if (value is! List) {
      return const <ProductPerformance>[];
    }
    return value
        .map((dynamic e) => ProductPerformance.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
