import 'package:atoga_manager/features/auth/domain/staff_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StaffRole.parse يطابق القيم الصحيحة ويتجاهل غيرها', () {
    expect(StaffRole.parse('super_admin'), StaffRole.superAdmin);
    expect(StaffRole.parse('manager'), StaffRole.manager);
    expect(StaffRole.parse('marketer'), StaffRole.marketer);
    expect(StaffRole.parse('driver'), StaffRole.driver);
    expect(StaffRole.parse('packager'), StaffRole.packager);
    expect(StaffRole.parse('nope'), StaffRole.unknown);
    expect(StaffRole.parse(null), StaffRole.unknown);
  });

  test('قواعد الصلاحيات والحجب', () {
    expect(StaffRole.superAdmin.isAdminApp, isTrue);
    expect(StaffRole.superAdmin.isSuperAdmin, isTrue);
    expect(StaffRole.manager.isAdminApp, isTrue);
    expect(StaffRole.manager.canManageCatalog, isTrue);
    expect(StaffRole.manager.canManageMarketing, isFalse);
    expect(StaffRole.marketer.isAdminApp, isTrue);
    expect(StaffRole.marketer.canManageMarketing, isTrue);
    expect(StaffRole.marketer.canManageCatalog, isFalse);
    expect(StaffRole.driver.isAdminApp, isFalse);
    expect(StaffRole.driver.isFulfillment, isTrue);
    expect(StaffRole.packager.isAdminApp, isFalse);
    expect(StaffRole.packager.isFulfillment, isTrue);
    expect(StaffRole.unknown.isAdminApp, isFalse);
  });
}
