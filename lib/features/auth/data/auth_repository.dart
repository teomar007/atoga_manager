import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/l10n/app_l10n.dart';
import '../domain/access_request.dart';
import '../domain/staff_role.dart';

/// مصادقة الموظفين (بريد إلكتروني + كلمة مرور) وقراءة الدور.
class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  String? get currentEmail => _client.auth.currentUser?.email;

  /// دخول بـ «اسم المستخدم»: يحوّله الخادم إلى البريد الداخلي ثم يسجّل الدخول.
  Future<void> signIn({required String username, required String password}) async {
    final dynamic resolved = await _client.rpc(
      'resolve_username',
      params: <String, dynamic>{'p_username': username.trim()},
    );
    final String email = '$resolved';
    if (email.isEmpty || email == 'null') {
      throw const UsernameNotFoundException();
    }
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  /// يقرأ دور المستخدم الحالي من دالة `get_my_staff_role` (SECURITY DEFINER).
  Future<StaffRole> fetchMyRole() async {
    final dynamic result = await _client.rpc('get_my_staff_role');
    return StaffRole.parse(result);
  }

  /// لغة العرض المحفوظة في حساب الموظف (`profiles.language_code`).
  Future<String?> fetchMyLanguage() async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    try {
      final dynamic row = await _client.from('profiles').select('language_code').eq('id', userId).maybeSingle();
      if (row is Map) {
        final String? code = row['language_code']?.toString();
        return (code == 'ar' || code == 'fr') ? code : null;
      }
    } on Object {
      // لا شيء
    }
    return null;
  }

  /// أحدث طلب وصول للمستخدم (أو null إن لم يقدّم طلباً بعد).
  Future<AccessRequest?> fetchAccessRequest() async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    final dynamic rows = await _client
        .from('admin_requests')
        .select()
        .eq('user_id', userId)
        .order('requested_at', ascending: false)
        .limit(1);
    if (rows is! List || rows.isEmpty) {
      return null;
    }
    return AccessRequest.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  /// يُرسل طلب وصول باسم المستخدم (بريده يفرضه الخادم من الـ JWT).
  Future<void> submitAccessRequest() async {
    final String? userId = _client.auth.currentUser?.id;
    final String? email = _client.auth.currentUser?.email;
    if (userId == null || email == null) {
      throw StateError('not_authenticated');
    }
    await _client.from('admin_requests').insert(<String, dynamic>{
      'user_id': userId,
      'email': email,
    });
  }
}

/// اسم المستخدم غير موجود في قاعدة البيانات.
class UsernameNotFoundException implements Exception {
  const UsernameNotFoundException();

  @override
  String toString() => t('اسم المستخدم غير موجود.');
}
