import 'staff_role.dart';

/// حالة طلب الوصول كما في `public.admin_requests.status`.
enum AccessRequestStatus { pending, approved, rejected }

AccessRequestStatus _parseRequestStatus(Object? value) {
  switch (value?.toString()) {
    case 'approved':
      return AccessRequestStatus.approved;
    case 'rejected':
      return AccessRequestStatus.rejected;
    default:
      return AccessRequestStatus.pending;
  }
}

/// صف من جدول `admin_requests` (طلب وصول لوحة الإدارة).
class AccessRequest {
  const AccessRequest({
    required this.id,
    required this.email,
    required this.status,
    this.requestedAt,
  });

  final String id;
  final String email;
  final AccessRequestStatus status;
  final DateTime? requestedAt;

  factory AccessRequest.fromJson(Map<String, dynamic> json) {
    final Object? requestedAt = json['requested_at'];
    return AccessRequest(
      id: '${json['id']}',
      email: '${json['email'] ?? ''}',
      status: _parseRequestStatus(json['status']),
      requestedAt: requestedAt is String ? DateTime.tryParse(requestedAt) : null,
    );
  }
}

/// محطات مسار المصادقة بعد تسجيل الدخول.
enum AuthFlowStage {
  /// دور إداري فعّال → لوحة الإدارة.
  authorized,

  /// سائق/معبئ → حجب فوري وتسجيل خروج.
  fulfillmentBlocked,

  /// لا دور ولا طلب → شاشة طلب الوصول.
  requestRequired,

  /// طلب معلّق بانتظار موافقة المدير العام.
  pendingApproval,

  /// طلب مرفوض.
  rejected,
}

/// حسم المسار من الدور وحالة الطلب (دالة نقية قابلة للاختبار).
AuthFlowStage resolveAuthFlowStage({
  required StaffRole role,
  required AccessRequestStatus? requestStatus,
}) {
  if (role.isAdminApp) {
    return AuthFlowStage.authorized;
  }
  if (role.isFulfillment) {
    return AuthFlowStage.fulfillmentBlocked;
  }
  switch (requestStatus) {
    case AccessRequestStatus.pending:
      return AuthFlowStage.pendingApproval;
    case AccessRequestStatus.rejected:
      return AuthFlowStage.rejected;
    case AccessRequestStatus.approved:
      // موافقة بلا دور بعد (تناقض مؤقت) → يُعاد التسجيل.
      return AuthFlowStage.requestRequired;
    case null:
      return AuthFlowStage.requestRequired;
  }
}
