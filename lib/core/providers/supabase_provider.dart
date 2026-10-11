import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// عميل Supabase الوحيد المستخدم في التطبيق.
final supabaseClientProvider = Provider<SupabaseClient>(
  (Ref ref) => Supabase.instance.client,
);
