import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../data/store_hours_repository.dart';
import '../domain/store_shift_models.dart';
import 'store_hours_providers.dart';

/// قسم «أوقات العمل»: ضبط ورديات الأسبوع (أكثر من وردية في اليوم).
class StoreHoursScreen extends ConsumerStatefulWidget {
  const StoreHoursScreen({super.key});

  @override
  ConsumerState<StoreHoursScreen> createState() => _StoreHoursScreenState();
}

class _StoreHoursScreenState extends ConsumerState<StoreHoursScreen> {
  Map<int, List<DayShift>>? _week;
  bool _busy = false;

  void _snack(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? AppColors.danger : null),
    );
  }

  void _addShift(int day) {
    setState(() => _week![day]!.add(DayShift(open: const TimeOfDay(hour: 8, minute: 0), close: const TimeOfDay(hour: 12, minute: 0))));
  }

  void _removeShift(int day, int index) {
    setState(() => _week![day]!.removeAt(index));
  }

  Future<void> _pickTime(int day, int index, {required bool isOpen}) async {
    final DayShift shift = _week![day]![index];
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? shift.open : shift.close,
      helpText: isOpen ? t('وقت الفتح') : t('وقت الإغلاق'),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isOpen) {
        shift.open = picked;
      } else {
        shift.close = picked;
      }
    });
  }

  Future<void> _saveDay(int day) async {
    final List<DayShift> shifts = _week![day]!;
    for (final DayShift s in shifts) {
      final int open = s.open.hour * 60 + s.open.minute;
      final int close = (s.close.hour == 0 && s.close.minute == 0) ? 24 * 60 : s.close.hour * 60 + s.close.minute;
      if (close <= open) {
        _snack(t('في %s: وقت الإغلاق يجب أن يكون بعد الفتح.').replaceFirst('%s', t(kDayNames[day]!)), error: true);
        return;
      }
    }
    setState(() => _busy = true);
    try {
      await ref.read(storeHoursRepositoryProvider).saveDay(day, shifts);
      if (mounted) {
        _snack(t('تم حفظ أوقات %s.').replaceFirst('%s', t(kDayNames[day]!)));
      }
      ref.invalidate(storeWeekProvider);
    } on Object catch (error) {
      _snack(t('تعذّر الحفظ: %s').replaceFirst('%s', '$error'), error: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Map<int, List<DayShift>>> weekAsync = ref.watch(storeWeekProvider);
    return Stack(
      children: <Widget>[
        weekAsync.when(
          data: (Map<int, List<DayShift>> data) {
            _week ??= <int, List<DayShift>>{
              for (final MapEntry<int, List<DayShift>> e in data.entries)
                e.key: e.value.map((DayShift s) => s.copy()).toList(),
            };
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: <Widget>[
                Text(
                  t('حدّد ورديات الأسبوع. يمكن إضافة أكثر من وردية في اليوم الواحد.'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 12),
                for (final int day in kWeekOrder) _dayCard(day),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stack) => Center(child: Text('${t('تعذّر تحميل الأوقات')}\n$error', textAlign: TextAlign.center)),
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(color: Color(0x22000000), child: Center(child: CircularProgressIndicator())),
          ),
      ],
    );
  }

  Widget _dayCard(int day) {
    final List<DayShift> shifts = _week![day]!;
    final ThemeData theme = Theme.of(context);
    final String summary = shifts.isEmpty
        ? t('مغلق طوال اليوم')
        : shifts.map((DayShift s) => '${formatTime(s.open)} - ${formatTime(s.close)}').join('    •    ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(t(kDayNames[day]!), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            summary,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: shifts.isEmpty ? AppColors.danger : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (shifts.isNotEmpty)
            for (int i = 0; i < shifts.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Text(t('من')),
                    const SizedBox(width: 6),
                    _timeChip(formatTime(shifts[i].open), () => _pickTime(day, i, isOpen: true)),
                    const SizedBox(width: 8),
                    Text(t('إلى')),
                    const SizedBox(width: 6),
                    _timeChip(formatTime(shifts[i].close), () => _pickTime(day, i, isOpen: false)),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: t('حذف الوردية'),
                      onPressed: _busy ? null : () => _removeShift(day, i),
                      icon: const Icon(Icons.close_rounded, color: AppColors.danger, size: 20),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              TextButton.icon(
                onPressed: _busy ? null : () => _addShift(day),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(t('إضافة وردية')),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : () => _saveDay(day),
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(t('حفظ')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: _busy ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }
}
