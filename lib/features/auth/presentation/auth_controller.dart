import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../settings/presentation/locale_controller.dart';
import '../data/auth_repository.dart';
import '../domain/access_request.dart';
import '../domain/staff_role.dart';

/// حالة الوصول في تطبيق الإدارة بعد فحص الدور وطلب الوصول.
enum AdminAuthStatus {
  unauthenticated,
  authorized,

  /// سائق/معبئ: حجب فوري مع تسجيل خروج.
  denied,

  /// لا دور ولا طلب وصول بعد → شاشة «طلب الوصول».
  requestRequired,

  /// طلب معلّق بانتظار موافقة المدير العام.
  pendingApproval,

  /// الطلب مرفوض.
  rejected,
}

/// حالة جلسة الموظف في تطبيق الإدارة.
class AdminAuthState {
  const AdminAuthState({
    required this.status,
    this.role = StaffRole.unknown,
    this.email,
    this.message,
  });

  final AdminAuthStatus status;
  final StaffRole role;
  final String? email;
  final String? message;

  const AdminAuthState.unauthenticated({String? message})
      : this(status: AdminAuthStatus.unauthenticated, message: message);

  const AdminAuthState.authorized(StaffRole role, String? email)
      : this(status: AdminAuthStatus.authorized, role: role, email: email);

  /// حجب موظفي التوصيل مع تسجيل الخروج.
  const AdminAuthState.denied(StaffRole role, {String? message})
      : this(status: AdminAuthStatus.denied, role: role, message: message);

  const AdminAuthState.requestRequired(String? email, {String? message})
      : this(status: AdminAuthStatus.requestRequired, email: email, message: message);

  const AdminAuthState.pendingApproval(String? email)
      : this(status: AdminAuthStatus.pendingApproval, email: email);

  const AdminAuthState.rejected(String? email)
      : this(status: AdminAuthStatus.rejected, email: email);
}

final authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

class AuthController extends AsyncNotifier<AdminAuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AdminAuthState> build() async {
    final SupabaseClient client = ref.watch(supabaseClientProvider);

    // إن انتهت الجلسة من الخارج (تسجيل خروج/انتهاء توكن) نعيد الحالة للدخول.
    final StreamSubscription<AuthState> sub = client.auth.onAuthStateChange.listen(
      (AuthState event) {
        if (event.event == AuthChangeEvent.signedOut) {
          state = const AsyncData(AdminAuthState.unauthenticated());
        }
      },
    );
    ref.onDispose(sub.cancel);

    if (client.auth.currentSession == null) {
      return const AdminAuthState.unauthenticated();
    }
    return _resolve();
  }

  /// حسم المسار بعد الدخول: دور إداري → الواجهة، سائق/معبئ → حجب،
  /// وإلا حسب طلب الوصول المخزّن.
  Future<AdminAuthState> _resolve() async {
    final StaffRole role = await _repo.fetchMyRole();
    final AccessRequestStatus? request = (await _repo.fetchAccessRequest())?.status;

    switch (resolveAuthFlowStage(role: role, requestStatus: request)) {
      case AuthFlowStage.authorized:
        // لغة العرض من حساب الموظف (تُطبَّق فور الدخول).
        ref.read(localeControllerProvider.notifier).applyFromAccount(await _repo.fetchMyLanguage());
        return AdminAuthState.authorized(role, _repo.currentEmail);
      case AuthFlowStage.fulfillmentBlocked:
        await _repo.signOut();
        return AdminAuthState.denied(
          role,
          message: 'Access denied. Employees must use the Fulfillment App.',
        );
      case AuthFlowStage.pendingApproval:
        return AdminAuthState.pendingApproval(_repo.currentEmail);
      case AuthFlowStage.rejected:
        return AdminAuthState.rejected(_repo.currentEmail);
      case AuthFlowStage.requestRequired:
        return AdminAuthState.requestRequired(
          _repo.currentEmail,
          message: request == AccessRequestStatus.approved
              ? t('تمت الموافقة على طلبك؛ سجّل الخروج ثم الدخول من جديد.')
              : null,
        );
    }
  }

  Future<void> signIn(String username, String password) async {
    state = const AsyncLoading();
    try {
      await _repo.signIn(username: username, password: password);
      state = AsyncData(await _resolve());
    } on UsernameNotFoundException catch (error) {
      state = AsyncData(AdminAuthState.unauthenticated(message: error.toString()));
    } on AuthException catch (error) {
      state = AsyncData(AdminAuthState.unauthenticated(message: _mapError(error)));
    } on Object {
      state = AsyncData(
        AdminAuthState.unauthenticated(
          message: t('تعذّر الاتصال بالخادم. تحقق من الشبكة وحاول مجدداً.'),
        ),
      );
    }
  }

  /// يُرسل طلب الوصول ويحوّل الحالة إلى «بانتظار الموافقة».
  Future<bool> submitAccessRequest() async {
    state = const AsyncLoading();
    try {
      await _repo.submitAccessRequest();
      state = AsyncData(AdminAuthState.pendingApproval(_repo.currentEmail));
      return true;
    } on Object {
      // إن كان هناك طلب معلّق موجود أصلاً (تزامن أو إعادة إرسال) نعرض الانتظار.
      final AccessRequest? existing = await _repo.fetchAccessRequest();
      if (existing?.status == AccessRequestStatus.pending) {
        state = AsyncData(AdminAuthState.pendingApproval(_repo.currentEmail));
        return true;
      }
      state = AsyncData(
        AdminAuthState.requestRequired(
          _repo.currentEmail,
          message: t('تعذّر إرسال الطلب. حاول مجدداً.'),
        ),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncData(AdminAuthState.unauthenticated());
  }

  String _mapError(AuthException error) {
    final String code = error.code ?? '';
    if (code == 'invalid_credentials' || code == 'invalid_grant') {
      return t('اسم المستخدم أو كلمة المرور غير صحيحة.');
    }
    if (code == 'email_not_confirmed') {
      return t('يرجى تأكيد البريد الإلكتروني أولاً.');
    }
    return t('تعذّر تسجيل الدخول. تحقق من بياناتك وحاول مجدداً.');
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AdminAuthState>(AuthController.new);
