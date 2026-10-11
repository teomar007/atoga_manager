import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/locale_controller.dart';

class AtogaManagerApp extends ConsumerStatefulWidget {
  const AtogaManagerApp({super.key});

  @override
  ConsumerState<AtogaManagerApp> createState() => _AtogaManagerAppState();
}

class _AtogaManagerAppState extends ConsumerState<AtogaManagerApp> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(localeControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final String lang = ref.watch(localeControllerProvider);
    final GoRouter router = ref.watch(routerProvider);

    return MaterialApp.router(
      // إعادة بناء الشجرة كاملةً عند تغيير اللغة حتى تُحدَّث كل النصوص
      // (بعض الشاشات مبنية بـ const فلا تتحدّث تلقائياً).
      key: ValueKey<String>(lang),
      title: 'ATOGA MANAGER',
      locale: Locale(lang),
      supportedLocales: const <Locale>[Locale('ar'), Locale('fr')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
