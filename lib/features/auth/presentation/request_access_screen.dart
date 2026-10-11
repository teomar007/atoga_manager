import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import 'auth_controller.dart';

/// شاشة «طلب الوصول» لحساب مُسجّل لا يملك دوراً إدارياً ولا طلباً بعد.
class RequestAccessScreen extends ConsumerStatefulWidget {
  const RequestAccessScreen({super.key});

  @override
  ConsumerState<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends ConsumerState<RequestAccessScreen> {
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await ref.read(authControllerProvider.notifier).submitAccessRequest();
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AdminAuthState? auth = ref.watch(authControllerProvider).valueOrNull;
    final ThemeData theme = Theme.of(context);
    final String email = auth?.email ?? '';

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
                  const SizedBox(height: 24),
                  Text(
                    t('طلب الوصول إلى لوحة الإدارة'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t('هذا الحساب ليس لديه صلاحيات إدارة بعد. يمكنك إرسال طلب للاطلاع على الوصول.'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                      title: Text(email.isEmpty ? t('حسابك') : email),
                      subtitle: Text(t('البريد المرتبط بالحساب')),
                    ),
                  ),
                  if (auth?.message != null) ...<Widget>[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.info_outline_rounded, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(auth!.message!, style: TextStyle(color: theme.colorScheme.error))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_submitting ? t('جارٍ الإرسال...') : t('إرسال طلب الوصول')),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _submitting
                        ? null
                        : () => ref.read(authControllerProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(t('تسجيل الخروج')),
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
