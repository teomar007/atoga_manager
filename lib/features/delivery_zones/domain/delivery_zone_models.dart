/// نماذج مناطق التوصيل (جدول `delivery_zones`).
library;

double _toDouble(Object? value) => (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0;
int _toInt(Object? value) => (value is num) ? value.toInt() : int.tryParse('$value') ?? 0;

/// منطقة توصيل (حي) بسعر توصيل.
class DeliveryZone {
  const DeliveryZone({
    required this.id,
    required this.name,
    required this.deliveryFee,
    this.isActive = true,
    this.usageCount = 0,
  });

  final String id;
  final String name;
  final double deliveryFee;
  final bool isActive;

  /// عدد العناوين التي تستعمل هذه المنطقة (لا يمكن حذفها إن كان > 0).
  final int usageCount;

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      deliveryFee: _toDouble(json['delivery_fee']),
      isActive: json['is_active'] != false,
      usageCount: _toInt(json['usage_count']),
    );
  }
}
