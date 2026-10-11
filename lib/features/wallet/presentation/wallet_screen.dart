import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/wallet_models.dart';
import '../../../core/l10n/app_l10n.dart';
import 'customer_wallet_screen.dart';
import 'wallet_providers.dart';

final NumberFormat walletMoney = NumberFormat('#,##0.00');

/// صفحة المحفظة: قائمة الزبائن + بحث برقم الهاتف أو المعرّف، والتحكم بالرصيد.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  String _text = '';
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// بحث فوري أثناء الكتابة (بتأخير بسيط لتقليل الطلبات).
  void _onChanged(String value) {
    setState(() => _text = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      setState(() => _query = value.trim());
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(walletCustomersProvider);
    try {
      await ref.read(walletCustomersProvider(_query).future);
    } on Object {
      // تُعرض حالة الخطأ من المزوّد.
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CustomerWallet>> customers = ref.watch(walletCustomersProvider(_query));
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: t('ابحث برقم الهاتف أو المعرّف (ID)'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _search.clear();
                        _debounce?.cancel();
                        setState(() {
                          _text = '';
                          _query = '';
                        });
                      },
                    ),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        if (customers.isLoading && customers.hasValue)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: customers.when(
              data: (List<CustomerWallet> items) {
                if (items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      const SizedBox(height: 120),
                      Icon(Icons.account_balance_wallet_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.35)),
                      const SizedBox(height: 14),
                      Text(_query.isEmpty ? t('لا يوجد زبائن') : t('لا نتائج مطابقة'), textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        _query.isEmpty ? t('سيظهر الزبائن هنا') : t('جرّب رقم هاتف أو معرّفاً آخر'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) => _CustomerTile(
                    customer: items[index],
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(builder: (_) => CustomerWalletScreen(customer: items[index])),
                      );
                      ref.invalidate(walletCustomersProvider(_query));
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stack) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  const SizedBox(height: 120),
                  Icon(Icons.error_outline_rounded, size: 56, color: theme.colorScheme.error),
                  const SizedBox(height: 12),
                      Text('${t('تعذّر تحميل الزبائن')}\n$error', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer, required this.onTap});

  final CustomerWallet customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String phone = (customer.phone ?? '').trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  customer.displayName.isEmpty ? '?' : customer.displayName.substring(0, 1).toUpperCase(),
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(customer.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    if (phone.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Icon(Icons.phone_rounded, size: 15, color: theme.colorScheme.primary),
                          const SizedBox(width: 5),
                          Text(
                            phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.3, color: theme.colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ],
                    if (customer.username.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text('@${customer.username}', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('${customer.balance.toStringAsFixed(2)} $currency', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                  Text(t('الرصيد'), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                ],
              ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
