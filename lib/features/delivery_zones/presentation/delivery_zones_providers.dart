import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/delivery_zones_repository.dart';
import '../domain/delivery_zone_models.dart';

/// كل مناطق التوصيل.
final deliveryZonesProvider = FutureProvider<List<DeliveryZone>>(
  (Ref ref) => ref.watch(deliveryZonesRepositoryProvider).fetchAll(),
);
