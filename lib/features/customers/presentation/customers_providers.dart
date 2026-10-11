import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/customers_repository.dart';
import '../domain/customer_models.dart';

/// قائمة الزبائن مع إحصاءاتهم (عائلة حسب نص البحث؛ الفارغ = الكل).
final customersProvider = FutureProvider.family<List<CustomerRow>, String>(
  (ref, String query) => ref.watch(customersRepositoryProvider).fetchCustomers(query),
);
