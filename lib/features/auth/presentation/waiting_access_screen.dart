import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import 'auth_controller.dart';

/// شاشة «بانتظار موافقة المدير العام» بعد إرسال طلب الوصول.
class WaitingAccessScreen extends ConsumerWidget {
  const WaitingAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AdminAuthState? auth = ref.watch(authControllerProvider).valueOrNull;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: <Widget>[
                  const BrandLogo(height: 90),
                  const SizedBox(height: 26),
                  const Icon(Icons.hourglass_top_rounded, size: 72, color: AppColors.warning),
                  const SizedBox(height: 18),
                  Text(
                    'Your access request is pending Super Admin approval.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t('طلبك قيد المراجعة من المدير العام، وسيُفعَّل دخولك فور الموافقة. تابع مع فريق الإدارة.'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (auth?.email != null) ...<Widget>[
                    const SizedBox(height: 22),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                        title: Text(auth!.email!),
                        subtitle: Text(t('حساب قيد الموافقة')),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(t('تسجيل الخروج')),
                    onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
