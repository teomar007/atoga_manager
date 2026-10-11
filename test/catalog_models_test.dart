import 'package:atoga_manager/features/catalog/domain/catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CatalogProduct.fromJson و discountPercent', () {
    final CatalogProduct product = CatalogProduct.fromJson(<String, dynamic>{
      'id': 'p1',
      'name': 'زبدة',
      'name_fr': 'Beurre',
      'price': 200,
      'old_price': 400,
      'category_id': 'c1',
      'is_active': true,
    });
    expect(product.displayName, 'زبدة');
    expect(product.discountPercent, 50);
    expect(product.isPromo, isTrue);
    expect(product.categoryId, 'c1');
  });

  test('CatalogProduct بلا سعر قديم = بلا خصم', () {
    final CatalogProduct product = CatalogProduct.fromJson(<String, dynamic>{
      'id': 'p2',
      'name': 'سكر',
      'price': 190,
    });
    expect(product.discountPercent, 0);
    expect(product.isPromo, isFalse);
    expect(product.isActive, isTrue);
  });

  test('CatalogCategory يقرأ الحقول ويختار الاسم', () {
    final CatalogCategory category = CatalogCategory.fromJson(<String, dynamic>{
      'id': 'c1',
      'name_ar': 'معلبات',
      'name_fr': 'Conserves',
      'display_order': 3,
      'is_active': false,
    });
    expect(category.displayName, 'معلبات');
    expect(category.displayOrder, 3);
    expect(category.isActive, isFalse);
  });
}
