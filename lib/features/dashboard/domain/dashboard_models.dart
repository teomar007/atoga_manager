/// نماذج نتائج الدوال التحليلية (admin_dashboard_kpis / admin_sales_series /
/// admin_product_performance).
library;

double _toDouble(Object? value) => (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0;
int _toInt(Object? value) => (value is num) ? value.toInt() : int.tryParse('$value') ?? 0;

/// مؤشرات لوحة المعلومات اليومية.
class DashboardKpis {
  const DashboardKpis({
    required this.salesToday,
    required this.deliveredToday,
    required this.pendingOrders,
    required this.totalOrders,
    required this.avgOrderValue,
  });

  final double salesToday;
  final int deliveredToday;
  final int pendingOrders;
  final int totalOrders;
  final double avgOrderValue;

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      salesToday: _toDouble(json['sales_today']),
      deliveredToday: _toInt(json['delivered_today']),
      pendingOrders: _toInt(json['pending_orders']),
      totalOrders: _toInt(json['total_orders']),
      avgOrderValue: _toDouble(json['avg_order_value']),
    );
  }
}

/// نقطة في سلسلة المبيعات (يُسمّى اليوم/الساعة + الإيراد).
class SalesPoint {
  const SalesPoint({required this.label, required this.revenue});

  final String label;
  final double revenue;

  factory SalesPoint.fromJson(Map<String, dynamic> json) {
    return SalesPoint(
      label: '${json['label'] ?? ''}',
      revenue: _toDouble(json['revenue']),
    );
  }
}

/// أداء منتج (الكمية المبيعة والإيراد).
class ProductPerformance {
  const ProductPerformance({
    required this.productId,
    required this.name,
    required this.nameFr,
    required this.quantity,
    required this.revenue,
  });

  final String productId;
  final String name;
  final String nameFr;
  final int quantity;
  final double revenue;

  String get displayName => name.trim().isEmpty ? nameFr : name;

  factory ProductPerformance.fromJson(Map<String, dynamic> json) {
    return ProductPerformance(
      productId: '${json['product_id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      nameFr: '${json['name_fr'] ?? ''}',
      quantity: _toInt(json['quantity']),
      revenue: _toDouble(json['revenue']),
    );
  }
}

/// قائمتا الأعلى/الأقل مبيعاً.
class ProductReport {
  const ProductReport({required this.top, required this.least});

  final List<ProductPerformance> top;
  final List<ProductPerformance> least;
}
