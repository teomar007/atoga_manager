import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/imagekit_uploader.dart';
import '../domain/marketing_models.dart';

/// إدارة التسويق: البانرات، الكوبونات، وإرسال الإشعارات عبر دالة
/// `send-push` (المستضاف بدعم نص + صورة).
class MarketingRepository {
  const MarketingRepository(this._client);

  final SupabaseClient _client;

  // ---------- البانرات ----------
  Future<List<MarketingBanner>> fetchBanners() async {
    final dynamic rows = await _client.from('promo_banners').select().order('sort_order', ascending: true);
    return (rows as List)
        .map((dynamic row) => MarketingBanner.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> createBanner({required String id, required Map<String, dynamic> values}) async {
    await _client.from('promo_banners').insert(<String, dynamic>{'id': id, ...values});
  }

  Future<void> updateBanner(String id, Map<String, dynamic> values) async {
    await _client.from('promo_banners').update(values).eq('id', id);
  }

  Future<void> deleteBanner(String id) async {
    await _client.from('promo_banners').delete().eq('id', id);
  }

  // ---------- الكوبونات ----------
  Future<List<MarketingCoupon>> fetchCoupons() async {
    final dynamic rows = await _client.from('coupons').select().order('created_at', ascending: false);
    return (rows as List)
        .map((dynamic row) => MarketingCoupon.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> createCoupon(Map<String, dynamic> values) async {
    await _client.from('coupons').insert(values);
  }

  Future<void> updateCoupon(String id, Map<String, dynamic> values) async {
    await _client.from('coupons').update(values).eq('id', id);
  }

  // ---------- سجل الحملات ----------
  Future<List<CampaignRecord>> fetchCampaigns() async {
    final dynamic rows = await _client
        .from('notification_campaigns')
        .select()
        .order('created_at', ascending: false)
        .limit(30);
    return (rows as List)
        .map((dynamic row) => CampaignRecord.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  // ---------- الإشعارات المجدولة ----------
  Future<List<ScheduledNotification>> fetchScheduled() async {
    final dynamic rows = await _client
        .from('scheduled_notifications')
        .select()
        .eq('status', 'scheduled')
        .order('scheduled_at', ascending: true)
        .limit(100);
    return (rows as List)
        .map((dynamic row) => ScheduledNotification.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> createScheduled({
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? imageUrl,
    required String mode,
    String? topic,
    String? targetUserId,
  }) async {
    final String? uid = _client.auth.currentUser?.id;
    await _client.from('scheduled_notifications').insert(<String, dynamic>{
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'mode': mode,
      'topic': mode == 'topic' ? (topic ?? 'all') : null,
      'target_user_id': mode == 'user' ? targetUserId : null,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'status': 'scheduled',
      'created_by': uid,
    });
  }

  Future<void> cancelScheduled(String id) async {
    await _client
        .from('scheduled_notifications')
        .update(<String, dynamic>{'status': 'cancelled'})
        .eq('id', id)
        .eq('status', 'scheduled');
  }

  /// تعديل إشعار مجدول (المحتوى والجمهور والوقت) وإعادته إلى حالة «مجدول».
  Future<void> updateScheduled({
    required String id,
    required String title,
    required String body,
    String? imageUrl,
    required String mode,
    String? topic,
    String? targetUserId,
    required DateTime scheduledAt,
  }) async {
    await _client.from('scheduled_notifications').update(<String, dynamic>{
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'mode': mode,
      'topic': mode == 'topic' ? (topic ?? 'all') : null,
      'target_user_id': mode == 'user' ? targetUserId : null,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'status': 'scheduled',
      'error': null,
      'sent_at': null,
    }).eq('id', id);
  }

  Future<void> deleteScheduled(String id) async {
    await _client.from('scheduled_notifications').delete().eq('id', id);
  }

  Future<void> deleteCampaign(String id) async {
    await _client.from('notification_campaigns').delete().eq('id', id);
  }

  // ---------- الإشعارات ----------
  /// يرسل عبر الدالة `send-push` (وضع topic للجميع أو user لمحدد).
  Future<FunctionResponse> sendNotification({
    required String title,
    required String body,
    String? imageUrl,
    String? topic,
    String? targetUserId,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      if (topic != null && topic.isNotEmpty)
        ...<String, dynamic>{'mode': 'topic', 'topic': topic}
      else
        ...<String, dynamic>{'mode': 'user', 'user_id': targetUserId},
      'title': title,
      'body': body,
      'data': <String, dynamic>{},
      if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
    };
    return _client.functions.invoke('send-push', body: payload);
  }

  /// يسجّل الحملة في `notification_campaigns` بعد الإرسال.
  Future<void> logCampaign({
    required String title,
    required String body,
    String? imageUrl,
    required String mode,
    String? topic,
    String? targetUserId,
    required String status,
    Object? response,
  }) async {
    await _client.from('notification_campaigns').insert(<String, dynamic>{
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'mode': mode,
      'topic': topic,
      'target_user_id': targetUserId,
      'status': status,
      'response': response == null ? null : jsonEncode(response),
    });
  }

  /// يبحث عن معرّف المستخدم عبر رقم هاتفه (لإرسال إشعار محدد).
  Future<String?> findUserByPhone(String phone) async {
    final dynamic rows = await _client
        .from('profiles')
        .select('id')
        .eq('phone', phone.trim())
        .limit(1);
    if (rows is List && rows.isNotEmpty) {
      return '${(rows.first as Map)['id']}';
    }
    return null;
  }

  // ---------- الصور ----------
  /// يرفع الصورة إلى ImageKit (مجلد باسم [bucket]) ويعيد رابط CDN مع التحويلات.
  Future<String> uploadImage({
    required XFile file,
    required String bucket,
    required String path,
  }) {
    return ImageKitUploader(_client).upload(file: file, folder: '/$bucket', fileNameBase: path);
  }
}
