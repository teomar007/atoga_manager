import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../../core/widgets/brand_logo.dart';
import 'auth_controller.dart';

/// شاشة تسجيل الدخول للموظفين (بريد إلكتروني + كلمة مرور).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).signIn(_username.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AdminAuthState> auth = ref.watch(authControllerProvider);
    final bool loading = auth.isLoading;
    final String? error = auth.valueOrNull?.message;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Center(child: BrandLogo(height: 120)),
                    const SizedBox(height: 20),
                    Text(
                      'ATOGA MANAGER',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('لوحة إدارة المتجر'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _username,
                      enabled: !loading,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.username],
                      decoration: InputDecoration(
                        labelText: t('اسم المستخدم (يوزر نيم)'),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      validator: (String? value) {
                        final String username = (value ?? '').trim();
                        if (username.isEmpty) {
                          return t('أدخل اسم المستخدم');
                        }
                        if (username.length < 3) {
                          return t('اسم المستخدم 3 أحرف على الأقل');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      enabled: !loading,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: t('كلمة المرور'),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          onPressed: loading ? null : () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (String? value) => (value ?? '').isEmpty ? t('أدخل كلمة المرور') : null,
                    ),
                    if (error != null) ...<Widget>[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : Text(t('تسجيل الدخول')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
