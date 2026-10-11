import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/wallet_models.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (Ref ref) => WalletRepository(ref.watch(supabaseClientProvider)),
);

/// إدارة محافظ الزبائن عبر دوال `admin_wallet_*` (محصورة بالمدير العام).
class WalletRepository {
  const WalletRepository(this._client);

  final SupabaseClient _client;

  /// بحث عن الزبائن برقم الهاتف أو المعرّف (أو الاسم/اسم المستخدم). فارغ = الكل.
  Future<List<CustomerWallet>> searchCustomers(String query) async {
    final dynamic rows = await _client.rpc('admin_wallet_search', params: <String, dynamic>{
      'p_query': query.trim().isEmpty ? null : query.trim(),
    });
    if (rows is! List) {
      return const <CustomerWallet>[];
    }
    return rows
        .map((dynamic row) => CustomerWallet.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  /// شحن رصيد الزبون، ويعيد الرصيد الجديد.
  Future<double> credit({required String userId, required double amount, String? note}) async {
    final dynamic result = await _client.rpc('admin_wallet_credit', params: <String, dynamic>{
      'p_user_id': userId,
      'p_amount': amount,
      'p_note': note,
    });
    return _asDouble(result);
  }

  /// خصم من رصيد الزبون، ويعيد الرصيد الجديد.
  Future<double> debit({required String userId, required double amount, String? note}) async {
    final dynamic result = await _client.rpc('admin_wallet_debit', params: <String, dynamic>{
      'p_user_id': userId,
      'p_amount': amount,
      'p_note': note,
    });
    return _asDouble(result);
  }

  Future<List<WalletEntry>> transactions(String userId, {int limit = 50}) async {
    final dynamic rows = await _client.rpc('admin_wallet_transactions', params: <String, dynamic>{
      'p_user_id': userId,
      'p_limit': limit,
    });
    if (rows is! List) {
      return const <WalletEntry>[];
    }
    return rows
        .map((dynamic row) => WalletEntry.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  double _asDouble(Object? value) => (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0;
}
