import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';

final supportLinksRepositoryProvider = Provider<SupportLinksRepository>(
  (Ref ref) => SupportLinksRepository(ref.watch(supabaseClientProvider)),
);

/// إدارة روابط الدعم والتواصل المعروضة في تطبيق الزبون (جدول `social_links`).
///
/// القيم تُقرأ مباشرةً من تطبيق الزبون (اتصل بنا / واتساب / فيسبوك /
/// إنستغرام / تيك توك)، والتحديث هنا ينعكس هناك دون إعادة نشر.
class SupportLinksRepository {
  const SupportLinksRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, String>> fetchAll() async {
    final dynamic rows = await _client.from('social_links').select().order('key', ascending: true);
    final Map<String, String> values = <String, String>{};
    for (final dynamic row in (rows as List)) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(row as Map);
      values['${map['key'] ?? ''}'] = '${map['url'] ?? ''}'.trim();
    }
    return values;
  }

  /// يحفظ كل القيم دفعة واحدة (إدراج أو تحديث حسب المفتاح).
  Future<void> saveAll(Map<String, String> values) async {
    final List<Map<String, dynamic>> rows = values.entries
        .map(
          (MapEntry<String, String> entry) => <String, dynamic>{
            'key': entry.key,
            'url': entry.value.trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        )
        .toList();
    if (rows.isEmpty) {
      return;
    }
    await _client.from('social_links').upsert(rows, onConflict: 'key');
  }
}
