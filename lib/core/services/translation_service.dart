import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';

/// ترجمة النصوص عبر دالة `translate` المستضافة (عربي → فرنسي افتراضياً).
class TranslationService {
  const TranslationService(this._client);

  final SupabaseClient _client;

  /// يعيد النص المترجم أو `null` عند التعذّر (فلا يمنع الكتابة اليدوية).
  Future<String?> toFrench(String text) async {
    final String clean = text.trim();
    if (clean.isEmpty) {
      return null;
    }
    try {
      final FunctionResponse response = await _client.functions.invoke(
        'translate',
        body: <String, dynamic>{'text': clean, 'from': 'ar', 'to': 'fr'},
      );
      final dynamic data = response.data;
      if (data is Map && data['translated'] is String) {
        final String translated = (data['translated'] as String).trim();
        return translated.isEmpty ? null : translated;
      }
    } on Object {
      // لا شيء
    }
    return null;
  }
}

final translationServiceProvider = Provider<TranslationService>(
  (Ref ref) => TranslationService(ref.watch(supabaseClientProvider)),
);
