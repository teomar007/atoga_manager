import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wallet_repository.dart';
import '../domain/wallet_models.dart';

/// نتائج البحث عن الزبائن (عائلة حسب نص البحث؛ الفارغ = كل الزبائن).
final walletCustomersProvider = FutureProvider.family<List<CustomerWallet>, String>(
  (ref, String query) => ref.watch(walletRepositoryProvider).searchCustomers(query),
);

/// حركات محفظة زبون معيّن.
final walletTransactionsProvider = FutureProvider.family<List<WalletEntry>, String>(
  (ref, String userId) => ref.watch(walletRepositoryProvider).transactions(userId),
);
