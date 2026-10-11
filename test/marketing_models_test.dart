import 'package:atoga_manager/features/marketing/domain/marketing_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MarketingBanner.fromJson يقرأ الحقول', () {
    final MarketingBanner banner = MarketingBanner.fromJson(<String, dynamic>{
      'id': 'b1',
      'title': 'عروض الأسبوع',
      'title_fr': 'Promo de la semaine',
      'sort_order': 2,
      'is_active': true,
    });
    expect(banner.title, 'عروض الأسبوع');
    expect(banner.titleFr, 'Promo de la semaine');
    expect(banner.sortOrder, 2);
    expect(banner.isActive, isTrue);
  });

  test('MarketingCoupon معاني أنواع الخصم و التصنيف', () {
    final MarketingCoupon percent = MarketingCoupon.fromJson(<String, dynamic>{
      'id': 'c1',
      'code': 'PROMO10',
      'discount_type': 'percent',
      'discount_value': 10,
      'min_order': 1000,
      'is_active': true,
    });
    expect(percent.displayTitle, 'PROMO10');
    expect(percent.typeLabel, 'نسبة 10%');
    expect(percent.minOrder, 1000);

    final MarketingCoupon shipping = MarketingCoupon.fromJson(<String, dynamic>{
      'id': 'c2',
      'code': 'SHIPFREE',
      'discount_type': 'free_shipping',
      'min_order': 3000,
      'free_shipping': true,
    });
    expect(shipping.typeLabel, 'توصيل مجاني');
    expect(shipping.freeShipping, isTrue);
  });

  test('MarketingCoupon انتهاء الصلاحية', () {
    final MarketingCoupon expired = MarketingCoupon.fromJson(<String, dynamic>{
      'id': 'c3',
      'code': 'OLD',
      'expires_at': DateTime(2020, 1, 1).toIso8601String(),
    });
    expect(expired.isExpired, isTrue);
  });
}
