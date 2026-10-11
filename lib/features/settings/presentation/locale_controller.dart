import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/providers/supabase_provider.dart';

/// متحكم لغة العرض: يحفظ الاختيار محلياً وفي حساب الموظف (`profiles.language_code`).
class LocaleController extends Notifier<String> {
  static const String _key = 'manager_lang';

  @override
  String build() => gLang;

  /// يحمّل اللغة المحفوظة محلياً عند الإقلاع.
  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _apply(prefs.getString(_key));
    } on Object {
      // لا شيء
    }
  }

  /// يطبّق لغة الحساب بعد الدخول (أولوية أعلى من المحلي).
  void applyFromAccount(String? code) {
    if (code == 'ar' || code == 'fr') {
      _apply(code);
      _persistLocal(code!);
    }
  }

  /// تغيير اللغة من صفحة الإعدادات: يُحفظ محلياً وفي حساب الموظف.
  Future<void> setLanguage(String code, {String? userId}) async {
    if (code != 'ar' && code != 'fr') {
      return;
    }
    _apply(code);
    await _persistLocal(code);
    if (userId != null && userId.isNotEmpty) {
      try {
        await ref.read(supabaseClientProvider).from('profiles').update(<String, dynamic>{'language_code': code}).eq('id', userId);
      } on Object {
        // فشل الحفظ في الحساب لا يُبطل الاختيار المحلي.
      }
    }
  }

  Future<void> _persistLocal(String code) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } on Object {
      // لا شيء
    }
  }

  void _apply(String? code) {
    final String value = (code == 'fr') ? 'fr' : 'ar';
    gLang = value;
    state = value;
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, String>(LocaleController.new);
