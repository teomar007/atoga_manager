import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/store_hours_repository.dart';
import '../domain/store_shift_models.dart';

/// ورديات الأسبوع (مجمّعة حسب اليوم).
final storeWeekProvider = FutureProvider<Map<int, List<DayShift>>>(
  (Ref ref) => ref.watch(storeHoursRepositoryProvider).fetchWeek(),
);
