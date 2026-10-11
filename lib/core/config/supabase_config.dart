/// إعدادات الاتصال بمشروع Supabase نفسه المستخدم في تطبيق العميل.
///
/// يمكن تمرير القيم عبر `--dart-define`، وإلا تُستخدم القيم الافتراضية:
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx
/// ```
library;

abstract final class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qwiaxkrwyhdjrucnknhm.supabase.co',
  );

  /// مفتاح publishable (آمن للنشر في العميل، مقيّد بسياسات RLS).
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_yRpWwyXM7PfrkgrXvUnSsg_on18VvM8',
  );
}
