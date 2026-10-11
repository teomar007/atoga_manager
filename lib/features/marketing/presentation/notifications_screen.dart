import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/uuid.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/widgets/image_pick_field.dart';
import '../data/marketing_repository.dart';
import 'marketing_providers.dart';

final DateFormat _scheduleFormat = DateFormat('dd/MM/yyyy • HH:mm');

/// بيانات إشعار للتعديل أو إعادة الإرسال.
class NotificationDraft {
  const NotificationDraft({
    required this.title,
    required this.body,
    this.imageUrl,
    required this.toAll,
    this.scheduledAt,
    this.scheduledId,
  });

  final String title;
  final String body;
  final String? imageUrl;
  final bool toAll;
  final DateTime? scheduledAt;

  /// إن وُجد: تعديل إشعار مجدول قائم (تحديث نفس الصف).
  final String? scheduledId;
}

/// إنشاء/تعديل وإرسال إشعار (نص + صورة) عبر `send-push`، فوراً أو مجدولاً.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, this.draft});

  final NotificationDraft? draft;

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(text: widget.draft?.title ?? '');
  late final TextEditingController _body = TextEditingController(text: widget.draft?.body ?? '');
  final TextEditingController _phone = TextEditingController();
  late int _audience = (widget.draft?.toAll ?? true) ? 0 : 1;
  late int _when = (widget.draft?.scheduledAt != null) ? 1 : 0;
  late DateTime? _scheduledAt = widget.draft?.scheduledAt;
  late final String? _existingImageUrl = widget.draft?.imageUrl;
  XFile? _image;
  bool _sending = false;

  bool get _isEdit => widget.draft != null;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now.add(const Duration(minutes: 5))),
    );
    if (time == null) {
      return;
    }
    setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  /// يضبط وقت الجدولة إلى «الآن + مدة» (مقروباً للدقيقة).
  void _setIn(Duration duration) {
    final DateTime target = DateTime.now().add(duration);
    setState(() => _scheduledAt = DateTime(target.year, target.month, target.day, target.hour, target.minute));
  }

  Future<String?> _imageUrl(MarketingRepository repo) async {
    if (_image != null) {
      return repo.uploadImage(file: _image!, bucket: 'notifications', path: uuidV4());
    }
    return _existingImageUrl;
  }

  void _snack(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final MarketingRepository repo = ref.read(marketingRepositoryProvider);
    final String title = _title.text.trim();
    final String body = _body.text.trim();
    String? targetUserId;
    try {
      final String? imageUrl = await _imageUrl(repo);

      if (_audience == 1) {
        targetUserId = await repo.findUserByPhone(_phone.text.trim());
        if (targetUserId == null) {
          _snack(t('لا يوجد زبون بهذا الرقم'));
          return;
        }
      }

      if (_when == 1) {
        final DateTime? at = _scheduledAt;
        if (at == null) {
          _snack(t('اختر تاريخاً ووقتاً للجدولة.'));
          return;
        }
        if (!at.isAfter(DateTime.now())) {
          _snack(t('الوقت المحدد في الماضي؛ اختر وقتاً لاحقاً.'));
          return;
        }
        if (_isEdit && widget.draft?.scheduledId != null) {
          await repo.updateScheduled(
            id: widget.draft!.scheduledId!,
            title: title,
            body: body,
            imageUrl: imageUrl,
            mode: _audience == 0 ? 'topic' : 'user',
            topic: _audience == 0 ? 'all' : null,
            targetUserId: targetUserId,
            scheduledAt: at,
          );
        } else {
          await repo.createScheduled(
            title: title,
            body: body,
            scheduledAt: at,
            imageUrl: imageUrl,
            mode: _audience == 0 ? 'topic' : 'user',
            topic: _audience == 0 ? 'all' : null,
            targetUserId: targetUserId,
          );
        }
        if (mounted) {
          Navigator.pop(context, 'scheduled:${at.toIso8601String()}');
        }
        return;
      }

      // إرسال فوري.
      final FunctionResponse response = await repo.sendNotification(
        title: title,
        body: body,
        imageUrl: imageUrl,
        topic: _audience == 0 ? 'all' : null,
        targetUserId: targetUserId,
      );
      final bool ok = response.status < 400;
      await repo.logCampaign(
        title: title,
        body: body,
        imageUrl: imageUrl,
        mode: _audience == 0 ? 'topic' : 'user',
        topic: _audience == 0 ? 'all' : null,
        targetUserId: targetUserId,
        status: ok ? 'sent' : 'failed',
        response: ok ? null : response.data,
      );
      // عند تحويل إشعار مجدول إلى إرسال فوري: نحذف الصف المجدول.
      if (_isEdit && widget.draft?.scheduledId != null) {
        await repo.deleteScheduled(widget.draft!.scheduledId!);
      }
      if (mounted) {
        Navigator.pop(context, 'sent');
      }
    } on FunctionException catch (error) {
      if (mounted) {
        _snack(t('فشل الإرسال: %s').replaceFirst('%s', error.reasonPhrase ?? 'HTTP ${error.status}'));
      }
    } on Object catch (error) {
      if (mounted) {
        _snack(t('تعذّرت العملية: %s').replaceFirst('%s', error.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? t('تعديل الإشعار') : t('إشعار جديد'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            ImagePickField(
              file: _image,
              networkUrl: _existingImageUrl,
              onPicked: (XFile? file) => setState(() => _image = file),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: t('العنوان *'), prefixIcon: const Icon(Icons.title_rounded)),
              validator: (String? value) => (value ?? '').trim().isEmpty ? t('أدخل العنوان') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              maxLines: 3,
              decoration: InputDecoration(labelText: t('النص *'), prefixIcon: const Icon(Icons.notes_rounded)),
              validator: (String? value) => (value ?? '').trim().isEmpty ? t('أدخل النص') : null,
            ),
            const SizedBox(height: 16),
            Text(t('الجمهور'), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: <ButtonSegment<int>>[
                ButtonSegment<int>(value: 0, label: Text(t('جميع الزبائن'))),
                ButtonSegment<int>(value: 1, label: Text(t('زبون محدد'))),
              ],
              selected: <int>{_audience},
              onSelectionChanged: (Set<int> selection) => setState(() => _audience = selection.first),
            ),
            if (_audience == 1) ...<Widget>[
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: t('رقم هاتف الزبون'), prefixIcon: const Icon(Icons.phone_rounded)),
                validator: (String? value) => _audience == 1 && (value ?? '').trim().isEmpty ? t('أدخل رقم الهاتف') : null,
              ),
            ],
            const SizedBox(height: 16),
            Text(t('وقت الإرسال'), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: <ButtonSegment<int>>[
                ButtonSegment<int>(value: 0, label: Text(t('الآن')), icon: const Icon(Icons.bolt_rounded)),
                ButtonSegment<int>(value: 1, label: Text(t('جدولة')), icon: const Icon(Icons.schedule_rounded)),
              ],
              selected: <int>{_when},
              onSelectionChanged: (Set<int> selection) {
                setState(() {
                  _when = selection.first;
                  if (_when == 1 && _scheduledAt == null) {
                    final DateTime base = DateTime.now().add(const Duration(minutes: 5));
                    _scheduledAt = DateTime(base.year, base.month, base.day, base.hour, base.minute);
                  }
                });
              },
            ),
            if (_when == 1) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ActionChip(label: Text(t('بعد 5 دقائق')), onPressed: () => _setIn(const Duration(minutes: 5))),
                  ActionChip(label: Text(t('بعد 30 دقيقة')), onPressed: () => _setIn(const Duration(minutes: 30))),
                  ActionChip(label: Text(t('بعد ساعة')), onPressed: () => _setIn(const Duration(hours: 1))),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(_scheduledAt == null ? t('اختر التاريخ والوقت') : _scheduleFormat.format(_scheduledAt!)),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Icon(Icons.info_outline_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _scheduledAt == null
                          ? t('حدّد وقت الإرسال.')
                          : t('سيُرسل في: %s').replaceFirst('%s', _scheduleFormat.format(_scheduledAt!)),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Icon(_when == 1 ? Icons.schedule_send_rounded : Icons.send_rounded, size: 18),
              label: Text(_sending ? t('جارٍ الحفظ...') : (_when == 1 ? t('حفظ الجدولة') : t('إرسال الآن'))),
            ),
            const SizedBox(height: 8),
            Text(
              _when == 1
                  ? t('سيُرسل تلقائياً في الوقت المحدد (فحص كل دقيقة).')
                  : t('يُرسل فوراً عبر دالة send-push: نص فقط أو نص + صورة.'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
