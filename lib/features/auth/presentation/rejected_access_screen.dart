import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import 'auth_controller.dart';

/// شاشة «الطلب مرفوض» لحسابٍ سبق أن رُفض طلب وصوله.
class RejectedAccessScreen extends ConsumerWidget {
  const RejectedAccessScreen({super.key});

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
                  const Icon(Icons.cancel_rounded, size: 72, color: AppColors.danger),
                  const SizedBox(height: 18),
                  Text(
                    t('تم رفض طلب الوصول'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t('لم تتم الموافقة على طلبك للوصول إلى لوحة الإدارة في الوقت الحالي.'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (auth?.email != null) ...<Widget>[
                    const SizedBox(height: 22),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.mail_outline_rounded, color: AppColors.danger),
                        title: Text(auth!.email!),
                        subtitle: Text(t('الطلب مرفوض')),
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
