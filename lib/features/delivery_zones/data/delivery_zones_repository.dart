import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/delivery_zone_models.dart';

final deliveryZonesRepositoryProvider = Provider<DeliveryZonesRepository>(
  (Ref ref) => DeliveryZonesRepository(ref.watch(supabaseClientProvider)),
);

/// إدارة مناطق التوصيل (RLS: قراءة عامة + إدارة لطاقم الإدارة).
class DeliveryZonesRepository {
  const DeliveryZonesRepository(this._client);

  final SupabaseClient _client;

  Future<List<DeliveryZone>> fetchAll() async {
    final dynamic rows = await _client.rpc('admin_delivery_zones');
    return (rows as List)
        .map((dynamic row) => DeliveryZone.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> create({required String name, required double deliveryFee, bool isActive = true}) async {
    await _client.from('delivery_zones').insert(<String, dynamic>{
      'name': name,
      'delivery_fee': deliveryFee,
      'is_active': isActive,
    });
  }

  Future<void> update(String id, {required String name, required double deliveryFee}) async {
    await _client.from('delivery_zones').update(<String, dynamic>{
      'name': name,
      'delivery_fee': deliveryFee,
    }).eq('id', id);
  }

  Future<void> setActive(String id, bool active) async {
    await _client.from('delivery_zones').update(<String, dynamic>{'is_active': active}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('delivery_zones').delete().eq('id', id);
  }
}
