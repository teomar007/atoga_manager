import 'package:atoga_manager/features/auth/domain/access_request.dart';
import 'package:atoga_manager/features/auth/domain/staff_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AccessRequest.fromJson يقرأ الحالة والتوقيت', () {
    final AccessRequest request = AccessRequest.fromJson(<String, dynamic>{
      'id': 'r1',
      'email': 'user@atoga.com',
      'status': 'pending',
      'requested_at': '2026-10-10T11:00:00.000Z',
    });
    expect(request.id, 'r1');
    expect(request.email, 'user@atoga.com');
    expect(request.status, AccessRequestStatus.pending);
    expect(request.requestedAt, isNotNull);
  });

  test('AccessRequest يعيّن الحالة من القيم الأخرى', () {
    expect(
      AccessRequest.fromJson(<String, dynamic>{'id': 'r', 'status': 'approved'}).status,
      AccessRequestStatus.approved,
    );
    expect(
      AccessRequest.fromJson(<String, dynamic>{'id': 'r', 'status': 'rejected'}).status,
      AccessRequestStatus.rejected,
    );
    expect(
      AccessRequest.fromJson(<String, dynamic>{'id': 'r', 'status': null}).status,
      AccessRequestStatus.pending,
    );
  });

  test('resolveAuthFlowStage: الأدوار الإدارية تدخل مباشرة مهما كان الطلب', () {
    for (final StaffRole role in const <StaffRole>[
      StaffRole.superAdmin,
      StaffRole.manager,
      StaffRole.marketer,
    ]) {
      expect(resolveAuthFlowStage(role: role, requestStatus: null), AuthFlowStage.authorized);
      expect(resolveAuthFlowStage(role: role, requestStatus: AccessRequestStatus.pending), AuthFlowStage.authorized);
    }
  });

  test('resolveAuthFlowStage: سائق/معبئ يُحجب دائماً', () {
    for (final StaffRole role in const <StaffRole>[StaffRole.driver, StaffRole.packager]) {
      expect(
        resolveAuthFlowStage(role: role, requestStatus: AccessRequestStatus.pending),
        AuthFlowStage.fulfillmentBlocked,
      );
      expect(
        resolveAuthFlowStage(role: role, requestStatus: null),
        AuthFlowStage.fulfillmentBlocked,
      );
    }
  });

  test('resolveAuthFlowStage: بلا دور يتبع حالة الطلب', () {
    const StaffRole role = StaffRole.unknown;
    expect(resolveAuthFlowStage(role: role, requestStatus: null), AuthFlowStage.requestRequired);
    expect(
      resolveAuthFlowStage(role: role, requestStatus: AccessRequestStatus.pending),
      AuthFlowStage.pendingApproval,
    );
    expect(
      resolveAuthFlowStage(role: role, requestStatus: AccessRequestStatus.rejected),
      AuthFlowStage.rejected,
    );
    // موافقة دون دور → يطلب إعادة الدخول (تناقض مؤقت).
    expect(
      resolveAuthFlowStage(role: role, requestStatus: AccessRequestStatus.approved),
      AuthFlowStage.requestRequired,
    );
  });
}
