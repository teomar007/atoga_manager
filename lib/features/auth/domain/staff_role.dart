/// أدوار الموظفين المسجّلة في `public.staff_roles`.
enum StaffRole {
  superAdmin('super_admin'),
  manager('manager'),
  marketer('marketer'),
  driver('driver'),
  packager('packager'),
  driverPackager('driver_packager'),
  unknown('unknown');

  const StaffRole(this.wire);

  /// القيمة المطابقة في قاعدة البيانات.
  final String wire;

  static StaffRole parse(Object? value) {
    final String v = value?.toString() ?? '';
    for (final StaffRole role in StaffRole.values) {
      if (role.wire == v) {
        return role;
      }
    }
    return StaffRole.unknown;
  }

  /// هل يُسمح له بالدخول إلى تطبيق الإدارة؟
  bool get isAdminApp => this == superAdmin || this == manager || this == marketer;

  /// أدوار تطبيق التوصيل — تُحجب من تطبيق الإدارة.
  bool get isFulfillment => this == driver || this == packager || this == driverPackager;

  bool get canManageCatalog => this == superAdmin || this == manager;
  bool get canManageMarketing => this == superAdmin || this == marketer;
  bool get canManageWallet => this == superAdmin || this == manager;
  bool get canManageCustomers => this == superAdmin || this == manager;
  bool get canManageStoreHours => this == superAdmin || this == manager;
  bool get isSuperAdmin => this == superAdmin;

  String get label {
    switch (this) {
      case StaffRole.superAdmin:
        return 'مدير عام';
      case StaffRole.manager:
        return 'مدير';
      case StaffRole.marketer:
        return 'مسوّق';
      case StaffRole.driver:
        return 'سائق توصيل';
      case StaffRole.packager:
        return 'مجهّز طلبات';
      case StaffRole.driverPackager:
        return 'موظف';
      case StaffRole.unknown:
        return 'غير معروف';
    }
  }
}
