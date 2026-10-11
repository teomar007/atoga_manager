import 'package:atoga_manager/features/employees/domain/employee_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StaffMember.fromJson يقرأ الحقول ويستنتج الاسم المعروض', () {
    final StaffMember member = StaffMember.fromJson(<String, dynamic>{
      'user_id': 'u1',
      'email': 'driver@atoga.com',
      'role': 'driver',
      'is_active': true,
      'full_name': 'أحمد',
      'phone': '0550112233',
    });
    expect(member.id, 'u1');
    expect(member.email, 'driver@atoga.com');
    expect(member.role, 'driver');
    expect(member.isActive, isTrue);
    expect(member.displayName, 'أحمد');
    expect(member.phone, '0550112233');
  });

  test('StaffMember يعود للبريد عند غياب الاسم ويعتبر الهاتف الفارغ null', () {
    final StaffMember member = StaffMember.fromJson(<String, dynamic>{
      'user_id': 'u2',
      'email': 'packer@atoga.com',
      'role': 'packager',
      'full_name': '',
      'phone': '  ',
    });
    expect(member.displayName, 'packer@atoga.com');
    expect(member.phone, isNull);
    expect(member.isActive, isTrue); // الافتراضي عند غياب is_active
  });

  test('DriverPackagerKpi يقرأ القيم الرقمية النصية', () {
    final DriverPackagerKpi kpi = DriverPackagerKpi.fromJson(<String, dynamic>{
      'user_id': 'u1',
      'role': 'driver',
      'full_name': 'أحمد',
      'email': 'driver@atoga.com',
      'total_orders': 3,
      'successful_rate': '0.6667',
      'avg_delivery_min': '30',
    });
    expect(kpi.isDriver, isTrue);
    expect(kpi.displayName, 'أحمد');
    expect(kpi.totalOrders, 3);
    expect(kpi.successfulRate, closeTo(0.6667, 0.0001));
    expect(kpi.avgDeliveryMin, 30);
  });
}
