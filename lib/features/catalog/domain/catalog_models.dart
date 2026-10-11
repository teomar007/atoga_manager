/// نماذج الكتالوج (المنتجات والتصنيفات) كما تُقرأ من الجداول الحالية.
library;

double _toDouble(Object? value) => (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0;
int _toInt(Object? value) => (value is num) ? value.toInt() : int.tryParse('$value') ?? 0;

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.nameAr,
    this.nameFr,
    this.iconUrl,
    this.iconName,
    this.isActive = true,
    this.displayOrder = 0,
  });

  final String id;
  final String nameAr;
  final String? nameFr;
  final String? iconUrl;
  final String? iconName;
  final bool isActive;
  final int displayOrder;

  String get displayName => nameAr.trim().isEmpty ? (nameFr ?? '') : nameAr;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: '${json['id'] ?? ''}',
      nameAr: '${json['name_ar'] ?? ''}',
      nameFr: json['name_fr']?.toString(),
      iconUrl: json['icon_url']?.toString(),
      iconName: json['icon_name']?.toString(),
      isActive: json['is_active'] != false,
      displayOrder: _toInt(json['display_order']),
    );
  }
}

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    this.nameFr,
    required this.price,
    this.oldPrice,
    this.isPromo = false,
    this.imageUrl,
    this.unit,
    this.categoryId,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? nameFr;
  final double price;
  final double? oldPrice;
  final bool isPromo;
  final String? imageUrl;
  final String? unit;
  final String? categoryId;
  final bool isActive;

  String get displayName => name.trim().isEmpty ? (nameFr ?? '') : name;

  /// نسبة الخصم المعروضة (سعر قديم أكبر من الحالي).
  double get discountPercent {
    final double? old = oldPrice;
    if (old == null || old <= price || old <= 0) {
      return 0;
    }
    return (old - price) / old * 100;
  }

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    final double price = _toDouble(json['price']);
    final double? oldPrice = json['old_price'] == null ? null : _toDouble(json['old_price']);
    return CatalogProduct(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      nameFr: json['name_fr']?.toString(),
      price: price,
      oldPrice: oldPrice,
      isPromo: json['is_promo'] == true || (oldPrice != null && oldPrice > price),
      imageUrl: json['image_url']?.toString(),
      unit: json['unit']?.toString(),
      categoryId: json['category_id']?.toString(),
      isActive: json['is_active'] != false,
    );
  }
}
