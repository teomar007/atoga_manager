import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/employee_models.dart';

final employeesRepositoryProvider = Provider<EmployeesRepository>(
  (Ref ref) => EmployeesRepository(ref.watch(supabaseClientProvider)),
);

/// إدارة الموظفين (سائق/معبئ/موظف بكلا المهمتين): القائمة والمؤشرات عبر RPCs
/// محصورة بـ super_admin، وإدارة الحساب عبر دوال الإدارة الحالية.
class EmployeesRepository {
  const EmployeesRepository(this._client);

  final SupabaseClient _client;

  /// قائمة الموظفين فقط (سائق/معبئ/موظف) — تُستبعد حسابات الإدارة.
  Future<List<StaffMember>> fetchEmployees() async {
    final dynamic rows = await _client.rpc('admin_list_staff');
    if (rows is! List) {
      return const <StaffMember>[];
    }
    return rows
        .map((dynamic row) => StaffMember.fromJson(Map<String, dynamic>.from(row as Map)))
        .where((StaffMember m) => isFulfillmentRole(m.role))
        .toList();
  }

  /// إحصاءات أداء كل موظف (المستلمة/الناجحة/المرتجعة/الجارية/النسبة...).
  Future<List<EmployeeStats>> fetchEmployeeStats() async {
    final dynamic rows = await _client.rpc('admin_employee_stats');
    if (rows is! List) {
      return const <EmployeeStats>[];
    }
    return rows
        .map((dynamic row) => EmployeeStats.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  /// آخر طلبات موظف معيّن (لصفحة التفاصيل).
  Future<List<EmployeeOrder>> fetchEmployeeOrders(String userId, {int limit = 30}) async {
    final dynamic rows = await _client.rpc('admin_employee_orders', params: <String, dynamic>{
      'p_user_id': userId,
      'p_limit': limit,
    });
    if (rows is! List) {
      return const <EmployeeOrder>[];
    }
    return rows
        .map((dynamic row) => EmployeeOrder.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> createStaff({
    required String username,
    required String password,
    required String role,
    String? phone,
    String? fullName,
  }) async {
    await _client.functions.invoke(
      'admin-create-staff',
      body: <String, dynamic>{
        'username': username,
        'password': password,
        'role': role,
        'phone': phone,
        'full_name': fullName,
      },
    );
  }

  /// تجميد/تفعيل الحساب (يمنع الدخول إلى تطبيق التوصيل والتجهيز).
  Future<void> setEmployeeActive({required String userId, required bool active}) async {
    await _client.rpc('admin_set_account_active', params: <String, dynamic>{
      'p_user_id': userId,
      'p_active': active,
    });
  }

  /// تعديل بيانات الموظف (اسم المستخدم/الاسم الكامل/الهاتف) والمهام (الدور).
  Future<void> updateEmployee({
    required String userId,
    required String username,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    await _client.rpc('admin_update_account', params: <String, dynamic>{
      'p_user_id': userId,
      'p_username': username,
      'p_full_name': fullName,
      'p_phone': phone,
      'p_role': role,
    });
  }

  /// تغيير كلمة مرور الموظف عبر الدالة `admin-manage-user`.
  Future<void> changePassword({required String userId, required String newPassword}) async {
    final FunctionResponse response = await _client.functions.invoke(
      'admin-manage-user',
      body: <String, dynamic>{
        'action': 'password',
        'user_id': userId,
        'new_password': newPassword,
      },
    );
    final dynamic data = response.data;
    if (data is Map && data['error'] != null) {
      throw StateError('${data['error']}');
    }
  }

  /// حذف الحساب نهائياً (مع الملف والدور).
  Future<void> deleteEmployee(String userId) async {
    await _client.rpc('admin_delete_account', params: <String, dynamic>{'p_user_id': userId});
  }
}
