/// نماذج وحدة الموظفين (سائق/معبئ/موظف بكلا المهمتين) وإحصاءات الأداء.
library;

double _toDouble(Object? value) => (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0;
int _toInt(Object? value) => (value is num) ? value.toInt() : int.tryParse('$value') ?? 0;
String _toStr(Object? value) => value?.toString() ?? '';
DateTime? _toDate(Object? value) {
  final String s = _toStr(value).trim();
  if (s.isEmpty || s == 'null') {
    return null;
  }
  return DateTime.tryParse(s);
}

/// أدوار الموظفين العاملين في التوصيل والتجهيز.
const List<String> kFulfillmentRoles = <String>['driver', 'packager', 'driver_packager'];

/// هل الدور من أدوار الموظفين (توصيل/تجهيز)؟
bool isFulfillmentRole(String role) => kFulfillmentRoles.contains(role);

/// التسمية العربية لدور الموظف.
String employeeRoleLabel(String role) {
  switch (role) {
    case 'driver':
      return 'سائق توصيل';
    case 'packager':
      return 'معبئ طلبات';
    case 'driver_packager':
      return 'موظف';
    default:
      return role;
  }
}

/// التسمية العربية لحالة الطلب.
String orderStatusLabel(String status) {
  switch (status) {
    case 'received':
      return 'قيد الاستلام';
    case 'preparing':
      return 'قيد التجهيز';
    case 'on_the_way':
      return 'في الطريق';
    case 'delivered':
      return 'مسلَّم';
    case 'returned':
      return 'مرتجع';
    case 'cancelled':
      return 'ملغى';
    default:
      return status;
  }
}

/// صف من الدالة `admin_list_staff()`.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    required this.fullName,
    this.username,
    this.phone,
  });

  final String id;
  final String email;
  final String role;
  final bool isActive;
  final String fullName;
  final String? username;
  final String? phone;

  String get displayName {
    if (fullName.isNotEmpty) {
      return fullName;
    }
    if ((username ?? '').isNotEmpty) {
      return username!;
    }
    return email;
  }

  String get roleLabel => employeeRoleLabel(role);
  bool get isDual => role == 'driver_packager';

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final String phone = _toStr(json['phone']).trim();
    final String username = _toStr(json['username']).trim();
    return StaffMember(
      id: _toStr(json['user_id']),
      email: _toStr(json['email']),
      role: _toStr(json['role']),
      isActive: json['is_active'] != false,
      fullName: _toStr(json['full_name']),
      username: username.isEmpty ? null : username,
      phone: phone.isEmpty ? null : phone,
    );
  }
}

/// صف من الدالة `admin_employee_stats()` — كل إحصاءات الموظف.
class EmployeeStats {
  const EmployeeStats({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
    required this.isActive,
    required this.received,
    required this.delivered,
    required this.returned,
    required this.inProgress,
    required this.successRate,
    required this.avgDeliveryMin,
    required this.totalRevenue,
    required this.onTimeRate,
    required this.receivedLast7,
    required this.deliveredLast7,
    required this.returnedLast7,
    this.lastOrderAt,
  });

  final String userId;
  final String fullName;
  final String username;
  final String email;
  final String role;
  final bool isActive;
  final int received;
  final int delivered;
  final int returned;
  final int inProgress;

  /// نسبة النجاح = الناجحة ÷ (الناجحة + الفاشلة) — قيمة 0.0 إلى 1.0.
  final double successRate;
  final int avgDeliveryMin;
  final double totalRevenue;

  /// نسبة الالتزام بالوقت المتوقع — 0.0 إلى 1.0.
  final double onTimeRate;
  final int receivedLast7;
  final int deliveredLast7;
  final int returnedLast7;
  final DateTime? lastOrderAt;

  String get displayName {
    if (fullName.isNotEmpty) {
      return fullName;
    }
    if (username.isNotEmpty) {
      return username;
    }
    return email;
  }

  String get roleLabel => employeeRoleLabel(role);
  bool get isDual => role == 'driver_packager';

  int get completed => delivered + returned;
  int get successPercent => (successRate * 100).round();
  int get onTimePercent => (onTimeRate * 100).round();

  factory EmployeeStats.fromJson(Map<String, dynamic> json) {
    return EmployeeStats(
      userId: _toStr(json['user_id']),
      fullName: _toStr(json['full_name']),
      username: _toStr(json['username']),
      email: _toStr(json['email']),
      role: _toStr(json['role']),
      isActive: json['is_active'] != false,
      received: _toInt(json['received']),
      delivered: _toInt(json['delivered']),
      returned: _toInt(json['returned']),
      inProgress: _toInt(json['in_progress']),
      successRate: _toDouble(json['success_rate']),
      avgDeliveryMin: _toInt(json['avg_delivery_min']),
      totalRevenue: _toDouble(json['total_revenue']),
      onTimeRate: _toDouble(json['on_time_rate']),
      receivedLast7: _toInt(json['received_last7']),
      deliveredLast7: _toInt(json['delivered_last7']),
      returnedLast7: _toInt(json['returned_last7']),
      lastOrderAt: _toDate(json['last_order_at']),
    );
  }
}

/// صف من الدالة `admin_employee_orders()`.
class EmployeeOrder {
  const EmployeeOrder({
    required this.id,
    required this.status,
    required this.total,
    this.createdAt,
    this.deliveredAt,
    this.returnedAt,
    this.phone,
    this.street,
  });

  final String id;
  final String status;
  final double total;
  final DateTime? createdAt;
  final DateTime? deliveredAt;
  final DateTime? returnedAt;
  final String? phone;
  final String? street;

  String get statusLabel => orderStatusLabel(status);
  bool get isDelivered => status == 'delivered';
  bool get isReturned => status == 'returned';

  factory EmployeeOrder.fromJson(Map<String, dynamic> json) {
    final String phone = _toStr(json['phone']).trim();
    final String street = _toStr(json['street']).trim();
    return EmployeeOrder(
      id: _toStr(json['id']),
      status: _toStr(json['status']),
      total: _toDouble(json['total']),
      createdAt: _toDate(json['created_at']),
      deliveredAt: _toDate(json['delivered_at']),
      returnedAt: _toDate(json['returned_at']),
      phone: phone.isEmpty ? null : phone,
      street: street.isEmpty ? null : street,
    );
  }
}
