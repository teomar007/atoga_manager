import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/access_denied_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/rejected_access_screen.dart';
import '../../features/auth/presentation/request_access_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/waiting_access_screen.dart';
import '../../features/shell/presentation/home_shell.dart';

/// الراوتر مع حراسة صلاحيات تعتمد على دور الموظف:
/// زائر → Login، محجوب (سائق/مجهّز) → Access Denied، مخوّل → Home.
final routerProvider = Provider<GoRouter>((Ref ref) {
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<AsyncValue<AdminAuthState>>(
    authControllerProvider,
    (_, _) => refresh.value++,
  );

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<AdminAuthState> auth = ref.read(authControllerProvider);
      final String location = state.matchedLocation;

      if (auth.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final AdminAuthState? value = auth.valueOrNull;
      if (value == null || value.status == AdminAuthStatus.unauthenticated) {
        return location == '/login' ? null : '/login';
      }
      switch (value.status) {
        case AdminAuthStatus.denied:
          return location == '/denied' ? null : '/denied';
        case AdminAuthStatus.requestRequired:
          return location == '/request' ? null : '/request';
        case AdminAuthStatus.pendingApproval:
          return location == '/waiting' ? null : '/waiting';
        case AdminAuthStatus.rejected:
          return location == '/rejected' ? null : '/rejected';
        case AdminAuthStatus.authorized:
          // مخوّل: لا يبقى على شاشات الدخول/الحجب/الطلب.
          if (const <String>['/login', '/splash', '/denied', '/request', '/waiting', '/rejected'].contains(location)) {
            return '/home';
          }
          return null;
        case AdminAuthStatus.unauthenticated:
          return location == '/login' ? null : '/login';
      }
    },
    routes: <RouteBase>[
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/denied', builder: (_, _) => const AccessDeniedScreen()),
      GoRoute(path: '/request', builder: (_, _) => const RequestAccessScreen()),
      GoRoute(path: '/waiting', builder: (_, _) => const WaitingAccessScreen()),
      GoRoute(path: '/rejected', builder: (_, _) => const RejectedAccessScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeShell()),
    ],
  );
});
