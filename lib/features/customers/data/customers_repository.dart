import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/customer_models.dart';

final customersRepositoryProvider = Provider<CustomersRepository>(
  (Ref ref) => CustomersRepository(ref.watch(supabaseClientProvider)),
);

/// إدارة الزبائن عبر دوال `admin_*` (المدير العام + المدير).
class CustomersRepository {
  const CustomersRepository(this._client);

  final SupabaseClient _client;

  Future<List<CustomerRow>> fetchCustomers(String query) async {
    final dynamic rows = await _client.rpc('admin_customer_list', params: <String, dynamic>{
      'p_query': query.trim().isEmpty ? null : query.trim(),
    });
    if (rows is! List) {
      return const <CustomerRow>[];
    }
    return rows
        .map((dynamic row) => CustomerRow.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> setFrozen({required String userId, required bool frozen, String? reason}) async {
    await _client.rpc('admin_set_customer_frozen', params: <String, dynamic>{
      'p_user_id': userId,
      'p_frozen': frozen,
      'p_reason': reason,
    });
  }
}
