import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_models.dart';
import '../../../core/l10n/app_l10n.dart';
import 'wallet_providers.dart';

final DateFormat _dt = DateFormat('dd/MM/yyyy • HH:mm');

/// صفحة محفظة زبون: الرصيد + شحن/خصم + سجل الحركات.
class CustomerWalletScreen extends ConsumerStatefulWidget {
  const CustomerWalletScreen({super.key, required this.customer});

  final CustomerWallet customer;

  @override
  ConsumerState<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends ConsumerState<CustomerWalletScreen> {
  late double _balance = widget.customer.balance;
  bool _busy = false;

  void _snack(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? AppColors.danger : null),
    );
  }

  Future<void> _openAmountDialog({required bool credit}) async {
    final _AmountInput? input = await showDialog<_AmountInput>(
      context: context,
      builder: (BuildContext context) => _AmountDialog(credit: credit, maxDebit: _balance),
    );
    if (input == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final double newBalance = credit
          ? await ref.read(walletRepositoryProvider).credit(userId: widget.customer.userId, amount: input.amount, note: input.note)
          : await ref.read(walletRepositoryProvider).debit(userId: widget.customer.userId, amount: input.amount, note: input.note);
      setState(() => _balance = newBalance);
      ref.invalidate(walletTransactionsProvider(widget.customer.userId));
      _snack(credit
          ? t('تم شحن الرصيد (+%s).').replaceFirst('%s', '${input.amount.toStringAsFixed(2)} $currency')
          : t('تم خصم المبلغ (%s).').replaceFirst('%s', '${input.amount.toStringAsFixed(2)} $currency'));
    } on Object catch (error) {
      _snack(t('تعذّرت العملية: %s').replaceFirst('%s', _friendly(error)), error: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _friendly(Object error) {
    final String raw = error.toString();
    if (raw.contains('insufficient_balance')) {
      return t('الرصيد غير كافٍ.');
    }
    if (raw.contains('forbidden')) {
      return t('غير مصرّح.');
    }
    if (raw.contains('invalid_amount')) {
      return t('المبلغ غير صحيح.');
    }
    return raw.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CustomerWallet c = widget.customer;
    final AsyncValue<List<WalletEntry>> txs = ref.watch(walletTransactionsProvider(c.userId));

    return Scaffold(
      appBar: AppBar(title: Text(c.displayName)),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: <Color>[AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(t('رصيد المحفظة'), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${_balance.toStringAsFixed(2)} $currency', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(
                      <String>[
                        if ((c.phone ?? '').isNotEmpty) c.phone!,
                        if (c.username.isNotEmpty) '@${c.username}',
                      ].join(' • '),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    SelectableText('ID: ${c.userId}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _openAmountDialog(credit: true),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(t('شحن رصيد')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _openAmountDialog(credit: false),
                      icon: const Icon(Icons.remove_rounded),
                      label: Text(t('خصم من الرصيد')),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(t('سجل الحركات'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              txs.when(
                data: (List<WalletEntry> items) {
                  if (items.isEmpty) {
                    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(t('لا توجد حركات بعد'), style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))))));
                  }
                  return Column(children: <Widget>[for (final WalletEntry e in items) _TxTile(entry: e)]);
                },
                loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                error: (Object e, StackTrace s) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(t('تعذّر تحميل الحركات: %s').replaceFirst('%s', '$e'), style: TextStyle(color: theme.colorScheme.error)))),
              ),
            ],
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(color: Color(0x22000000), child: Center(child: CircularProgressIndicator())),
            ),
        ],
      ),
    );
  }
}

class _AmountInput {
  const _AmountInput({required this.amount, this.note});
  final double amount;
  final String? note;
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.credit, required this.maxDebit});

  final bool credit;
  final double maxDebit;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final double? amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _error = t('أدخل مبلغاً صحيحاً أكبر من صفر.'));
      return;
    }
    if (!widget.credit && amount > _balanceOf()) {
      setState(() => _error = t('المبلغ أكبر من الرصيد المتاح.'));
      return;
    }
    Navigator.pop(context, _AmountInput(amount: amount, note: _note.text.trim().isEmpty ? null : _note.text.trim()));
  }

  double _balanceOf() => widget.maxDebit;

  @override
  Widget build(BuildContext context) {
    final bool credit = widget.credit;
    final Color color = credit ? AppColors.success : AppColors.danger;
    return AlertDialog(
      title: Text(credit ? t('شحن رصيد الزبون') : t('خصم من رصيد الزبون')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: t('المبلغ (دج)'), prefixIcon: Icon(credit ? Icons.add_rounded : Icons.remove_rounded, color: color)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: t('ملاحظة (اختياري)')),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t('إلغاء'))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: color), onPressed: _submit, child: Text(credit ? t('شحن') : t('خصم'))),
      ],
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.entry});

  final WalletEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool credit = entry.isCredit;
    final Color color = credit ? AppColors.success : AppColors.danger;
    final String amount = '${credit ? '+' : '-'}${entry.amount.abs().toStringAsFixed(2)} $currency';
    final String subtitle = <String>[
      t(entry.typeLabel),
      if (entry.createdAt != null) _dt.format(entry.createdAt!),
      if ((entry.note ?? '').isNotEmpty) entry.note!,
    ].join(' • ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            CircleAvatar(radius: 20, backgroundColor: color.withValues(alpha: 0.12), child: Icon(credit ? Icons.add_rounded : Icons.remove_rounded, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(entry.typeLabel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
            Text(amount, style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
