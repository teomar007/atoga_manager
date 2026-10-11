/// نماذج إدارة المحفظة في تطبيق المانجر.
library;

double _toDouble(Object? value) => (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0;
String _toStr(Object? value) => value?.toString() ?? '';
DateTime? _toDate(Object? value) {
  final String s = _toStr(value).trim();
  if (s.isEmpty || s == 'null') {
    return null;
  }
  return DateTime.tryParse(s);
}

/// زبون مع رصيد محفظته.
class CustomerWallet {
  const CustomerWallet({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    this.phone,
    required this.balance,
    this.createdAt,
  });

  final String userId;
  final String fullName;
  final String username;
  final String email;
  final String? phone;
  final double balance;
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

  CustomerWallet copyWith({double? balance}) => CustomerWallet(
        userId: userId,
        fullName: fullName,
        username: username,
        email: email,
        phone: phone,
        balance: balance ?? this.balance,
        createdAt: createdAt,
      );

  factory CustomerWallet.fromJson(Map<String, dynamic> json) {
    final String phone = _toStr(json['phone']).trim();
    return CustomerWallet(
      userId: _toStr(json['user_id']),
      fullName: _toStr(json['full_name']),
      username: _toStr(json['username']),
      email: _toStr(json['email']),
      phone: phone.isEmpty ? null : phone,
      balance: _toDouble(json['wallet_balance']),
      createdAt: _toDate(json['created_at']),
    );
  }
}

/// حركة محفظة (شحن/خصم/دفع طلب).
class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.amount,
    required this.type,
    this.orderId,
    this.note,
    this.createdAt,
  });

  final String id;
  final double amount;
  final String type;
  final String? orderId;
  final String? note;
  final DateTime? createdAt;

  bool get isCredit => amount >= 0;

  String get typeLabel {
    switch (type) {
      case 'deposit':
        return 'شحن';
      case 'withdrawal':
        return 'خصم';
      case 'payment':
        return 'دفع طلب';
      default:
        return type;
    }
  }

  factory WalletEntry.fromJson(Map<String, dynamic> json) {
    final String? note = json['note']?.toString();
    return WalletEntry(
      id: _toStr(json['id']),
      amount: _toDouble(json['amount']),
      type: _toStr(json['type']),
      orderId: json['order_id']?.toString(),
      note: (note ?? '').isEmpty ? null : note,
      createdAt: _toDate(json['created_at']),
    );
  }
}
