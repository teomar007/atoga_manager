/// نماذج قسم الزبائن في تطبيق المانجر.
library;

int _toInt(Object? value) => (value is num) ? value.toInt() : int.tryParse('$value') ?? 0;
String _toStr(Object? value) => value?.toString() ?? '';
DateTime? _toDate(Object? value) {
  final String s = _toStr(value).trim();
  if (s.isEmpty || s == 'null') {
    return null;
  }
  return DateTime.tryParse(s);
}

/// زبون مع إحصاءات طلباته وحالة التجميد.
class CustomerRow {
  const CustomerRow({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    this.phone,
    required this.isFrozen,
    this.frozenReason,
    required this.ordersTotal,
    required this.ordersDelivered,
    required this.ordersCancelled,
    required this.ordersReturned,
    this.lastOrderAt,
    this.createdAt,
  });

  final String userId;
  final String fullName;
  final String username;
  final String email;
  final String? phone;
  final bool isFrozen;
  final String? frozenReason;
  final int ordersTotal;
  final int ordersDelivered;
  final int ordersCancelled;
  final int ordersReturned;
  final DateTime? lastOrderAt;
  final DateTime? createdAt;

  String get displayName {
    if (fullName.isNotEmpty) {
      return fullName;
    }
    if (username.isNotEmpty) {
      return username;
    }
    if ((phone ?? '').isNotEmpty) {
      return phone!;
    }
    return email;
  }

  factory CustomerRow.fromJson(Map<String, dynamic> json) {
    final String phone = _toStr(json['phone']).trim();
    return CustomerRow(
      userId: _toStr(json['user_id']),
      fullName: _toStr(json['full_name']),
      username: _toStr(json['username']),
      email: _toStr(json['email']),
      phone: phone.isEmpty ? null : phone,
      isFrozen: json['is_frozen'] == true,
      frozenReason: (json['frozen_reason']?.toString().trim().isEmpty ?? true) ? null : json['frozen_reason'].toString(),
      ordersTotal: _toInt(json['orders_total']),
      ordersDelivered: _toInt(json['orders_delivered']),
      ordersCancelled: _toInt(json['orders_cancelled']),
      ordersReturned: _toInt(json['orders_returned']),
      lastOrderAt: _toDate(json['last_order_at']),
      createdAt: _toDate(json['created_at']),
    );
  }
}
