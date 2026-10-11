import 'package:atoga_manager/features/dashboard/domain/dashboard_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DashboardKpis.fromJson يحوّل الأرقام بأمان', () {
    final DashboardKpis kpis = DashboardKpis.fromJson(<String, dynamic>{
      'sales_today': 1234.5,
      'delivered_today': 3,
      'pending_orders': 2,
      'total_orders': 5,
      'avg_order_value': 600,
    });
    expect(kpis.salesToday, 1234.5);
    expect(kpis.deliveredToday, 3);
    expect(kpis.pendingOrders, 2);
    expect(kpis.totalOrders, 5);
    expect(kpis.avgOrderValue, 600);
  });

  test('SalesPoint.fromJson يقرأ التسمية والإيراد', () {
    final SalesPoint point = SalesPoint.fromJson(<String, dynamic>{'label': '14', 'revenue': 250});
    expect(point.label, '14');
    expect(point.revenue, 250);
  });

  test('ProductPerformance يختار الاسم العربي عند توفره', () {
    final ProductPerformance product = ProductPerformance.fromJson(<String, dynamic>{
      'product_id': 'p1',
      'name': 'طماطم',
      'name_fr': 'Tomates',
      'quantity': 4,
      'revenue': 480,
    });
    expect(product.displayName, 'طماطم');
    expect(product.quantity, 4);
    expect(product.revenue, 480);
  });
}
