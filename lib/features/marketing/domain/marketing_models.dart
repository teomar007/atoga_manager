/// نماذج التسويق: البانرات، الكوبونات، وسجلات الحملات.
library;

import '../../../core/l10n/app_l10n.dart';

double _toDouble(Object? value) => (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0;
int _toInt(Object? value) => (value is num) ? value.toInt() : int.tryParse('$value') ?? 0;

class MarketingBanner {
  const MarketingBanner({
    required this.id,
    required this.title,
    this.titleFr,
    this.subtitle,
    this.subtitleFr,
    this.discountLabel,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    this.targetCategoryId,
    this.backgroundColor,
    this.imageAlignX = 0,
    this.imageAlignY = 0,
    this.imageScale = 1,
  });

  final String id;
  final String title;
  final String? titleFr;
  final String? subtitle;
  final String? subtitleFr;
  final String? discountLabel;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final String? targetCategoryId;
  final String? backgroundColor;
  final double imageAlignX;
  final double imageAlignY;
  final double imageScale;

  factory MarketingBanner.fromJson(Map<String, dynamic> json) {
    return MarketingBanner(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      titleFr: json['title_fr']?.toString(),
      subtitle: json['subtitle']?.toString(),
      subtitleFr: json['subtitle_fr']?.toString(),
      discountLabel: json['discount_label']?.toString(),
      imageUrl: json['image_url']?.toString(),
      sortOrder: _toInt(json['sort_order']),
      isActive: json['is_active'] != false,
      targetCategoryId: json['target_category_id']?.toString(),
      backgroundColor: json['background_color']?.toString(),
      imageAlignX: _toDouble(json['image_align_x']),
      imageAlignY: _toDouble(json['image_align_y']),
      imageScale: _toDouble(json['image_scale']) == 0 ? 1 : _toDouble(json['image_scale']),
    );
  }
}

class MarketingCoupon {
  const MarketingCoupon({
    required this.id,
    required this.code,
    this.title,
    this.startsAt,
    this.expiresAt,
    this.discountType,
    this.discountValue = 0,
    this.minOrder = 0,
    this.maxDiscount,
    this.freeShipping = false,
    this.usageLimitPerUser,
    this.isWelcome = false,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String? title;
  final DateTime? startsAt;
  final DateTime? expiresAt;

  /// `percent` | `fixed` | `free_shipping`
  final String? discountType;
  final double discountValue;
  final double minOrder;
  final double? maxDiscount;
  final bool freeShipping;
  final int? usageLimitPerUser;
  final bool isWelcome;
  final bool isActive;

  String get displayTitle => (title ?? '').trim().isEmpty ? code : title!.trim();

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  String get typeLabel {
    switch (discountType) {
      case 'percent':
        return '${t('نسبة')} ${discountValue.round()}%';
      case 'fixed':
        return '${t('مبلغ ثابت')} ${discountValue.round()} $currency';
      case 'free_shipping':
        return t('توصيل مجاني');
      default:
        return t('عرض خاص');
    }
  }

  factory MarketingCoupon.fromJson(Map<String, dynamic> json) {
    return MarketingCoupon(
      id: '${json['id'] ?? ''}',
      code: '${json['code'] ?? ''}',
      title: json['title']?.toString(),
      startsAt: DateTime.tryParse('${json['starts_at'] ?? ''}'),
      expiresAt: DateTime.tryParse('${json['expires_at'] ?? ''}'),
      discountType: json['discount_type']?.toString(),
      discountValue: _toDouble(json['discount_value']),
      minOrder: _toDouble(json['min_order']),
      maxDiscount: json['max_discount'] == null ? null : _toDouble(json['max_discount']),
      freeShipping: json['free_shipping'] == true,
      usageLimitPerUser: json['usage_limit_per_user'] == null ? null : _toInt(json['usage_limit_per_user']),
      isWelcome: json['is_welcome'] == true,
      isActive: json['is_active'] != false,
    );
  }
}

/// سجل حملة إشعار أُرسلت (من `notification_campaigns`).
class CampaignRecord {
  const CampaignRecord({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.mode,
    this.topic,
    this.targetUserId,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String mode;
  final String? topic;
  final String? targetUserId;
  final String status;
  final DateTime? createdAt;

  factory CampaignRecord.fromJson(Map<String, dynamic> json) {
    return CampaignRecord(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      body: '${json['body'] ?? ''}',
      imageUrl: json['image_url']?.toString(),
      mode: '${json['mode'] ?? 'topic'}',
      topic: json['topic']?.toString(),
      targetUserId: json['target_user_id']?.toString(),
      status: '${json['status'] ?? 'sent'}',
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }
}

/// إشعار مجدول (من `scheduled_notifications`).
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.mode,
    required this.scheduledAt,
    required this.status,
    this.imageUrl,
    this.topic,
    this.targetUserId,
    this.error,
    this.sentAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String mode;
  final String? topic;
  final String? targetUserId;
  final DateTime scheduledAt;
  final String status; // scheduled | sent | failed | cancelled
  final String? error;
  final DateTime? sentAt;
  final DateTime? createdAt;

  String get statusLabel {
    switch (status) {
      case 'scheduled':
        return 'مجدول';
      case 'sent':
        return 'أُرسل';
      case 'failed':
        return 'فشل';
      case 'cancelled':
        return 'ملغى';
      default:
        return status;
    }
  }

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      body: '${json['body'] ?? ''}',
      imageUrl: json['image_url']?.toString(),
      mode: '${json['mode'] ?? 'topic'}',
      topic: json['topic']?.toString(),
      targetUserId: json['target_user_id']?.toString(),
      scheduledAt: DateTime.tryParse('${json['scheduled_at'] ?? ''}') ?? DateTime.now(),
      status: '${json['status'] ?? 'scheduled'}',
      error: json['error']?.toString(),
      sentAt: DateTime.tryParse('${json['sent_at'] ?? ''}'),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }
}
