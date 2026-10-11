import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/store_shift_models.dart';

final storeHoursRepositoryProvider = Provider<StoreHoursRepository>(
  (Ref ref) => StoreHoursRepository(ref.watch(supabaseClientProvider)),
);

/// إدارة أوقات عمل المتجر عبر جدول `store_shifts` ودالة `admin_set_store_shifts`.
class StoreHoursRepository {
  const StoreHoursRepository(this._client);

  final SupabaseClient _client;

  /// كل الورديات مجمّعة حسب اليوم (1..7).
  Future<Map<int, List<DayShift>>> fetchWeek() async {
    final dynamic rows = await _client
        .from('store_shifts')
        .select('day_of_week, open_time, close_time, sort_order')
        .order('day_of_week', ascending: true)
        .order('sort_order', ascending: true);
    final Map<int, List<DayShift>> week = <int, List<DayShift>>{
      for (int d = 1; d <= 7; d++) d: <DayShift>[],
    };
    for (final dynamic raw in (rows as List)) {
      final Map<String, dynamic> row = Map<String, dynamic>.from(raw as Map);
      final int day = (row['day_of_week'] as num?)?.toInt() ?? 0;
      if (day < 1 || day > 7) {
        continue;
      }
      week[day]!.add(DayShift(
        open: parseTime('${row['open_time'] ?? ''}'),
        close: parseTime('${row['close_time'] ?? ''}'),
      ));
    }
    return week;
  }

  /// يستبدل ورديات يوم واحد.
  Future<void> saveDay(int day, List<DayShift> shifts) async {
    await _client.rpc('admin_set_store_shifts', params: <String, dynamic>{
      'p_day': day,
      'p_shifts': shifts.map((DayShift s) => s.toJson()).toList(),
    });
  }
}
