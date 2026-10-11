import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../data/catalog_repository.dart';
import '../domain/catalog_models.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (Ref ref) => CatalogRepository(ref.watch(supabaseClientProvider)),
);

final catalogCategoriesProvider = FutureProvider<List<CatalogCategory>>(
  (Ref ref) => ref.watch(catalogRepositoryProvider).fetchCategories(),
);

final catalogProductsProvider = FutureProvider<List<CatalogProduct>>(
  (Ref ref) => ref.watch(catalogRepositoryProvider).fetchProducts(),
);
