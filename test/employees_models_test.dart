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

  test('EmployeeStats يقرأ القيم الرقمية النصية', () {
    final EmployeeStats stats = EmployeeStats.fromJson(<String, dynamic>{
      'user_id': 'u1',
      'role': 'driver',
      'full_name': 'أحمد',
      'email': 'driver@atoga.com',
      'is_active': true,
      'received': 3,
      'delivered': 2,
      'returned': '1',
      'in_progress': 0,
      'success_rate': '0.5',
      'avg_delivery_min': '30',
      'total_revenue': '1500.5',
      'on_time_rate': 0.9,
    });
    expect(stats.role, 'driver');
    expect(stats.displayName, 'أحمد');
    expect(stats.received, 3);
    expect(stats.successRate, closeTo(0.5, 0.0001));
    expect(stats.avgDeliveryMin, 30);
  });
}
