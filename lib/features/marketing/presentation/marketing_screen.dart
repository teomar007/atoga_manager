import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../domain/marketing_models.dart';
import 'banner_form_screen.dart';
import 'coupon_form_screen.dart';
import 'marketing_providers.dart';
import 'notifications_screen.dart';

final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');
final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy • HH:mm');

/// التسويق: البانرات، الكوبونات المتقدمة، والإشعارات.
class MarketingScreen extends ConsumerStatefulWidget {
  const MarketingScreen({super.key});

  @override
  ConsumerState<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends ConsumerState<MarketingScreen> {
  int _section = 0; // 0 بانرات، 1 كوبونات، 2 إشعارات
  int _notifView = 0; // 0 المرسلة، 1 المجدولة

  Future<void> _refresh() async {
    ref.invalidate(marketingBannersProvider);
    ref.invalidate(marketingCouponsProvider);
    ref.invalidate(marketingCampaignsProvider);
    ref.invalidate(scheduledNotificationsProvider);
    final List<Future<void>> futures = <Future<void>>[
      ref.read(marketingBannersProvider.future).then((_) {}),
      ref.read(marketingCouponsProvider.future).then((_) {}),
      ref.read(marketingCampaignsProvider.future).then((_) {}),
      ref.read(scheduledNotificationsProvider.future).then((_) {}),
    ];
    try {
      await Future.wait<void>(futures);
    } on Object {
      // تُعرض حالة الخطأ من المزوّد.
    }
  }

  Future<void> _openBannerForm([MarketingBanner? banner]) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => BannerFormScreen(banner: banner)),
    );
    if (saved == true) {
      ref.invalidate(marketingBannersProvider);
    }
  }

  Future<void> _openCouponForm([MarketingCoupon? coupon]) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => CouponFormScreen(coupon: coupon)),
    );
    if (saved == true) {
      ref.invalidate(marketingCouponsProvider);
    }
  }

  Future<void> _openNotifications([NotificationDraft? draft]) async {
    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => NotificationsScreen(draft: draft)),
    );
    if (result == null) {
      return;
    }
    ref.invalidate(marketingCampaignsProvider);
    ref.invalidate(scheduledNotificationsProvider);
    final bool scheduled = result.startsWith('scheduled');
    setState(() {
      _section = 2;
      _notifView = scheduled ? 1 : 0;
    });
    if (scheduled) {
      final DateTime? at = DateTime.tryParse(result.substring('scheduled:'.length))?.toLocal();
      _toast(at == null ? t('تمت الجدولة.') : t('تمت الجدولة لإرسالها في %s').replaceFirst('%s', _dateTimeFormat.format(at)));
    } else {
      _toast(t('تم إرسال الإشعار.'));
    }
  }

  Future<void> _editScheduled(ScheduledNotification item) {
    return _openNotifications(
      NotificationDraft(
        title: item.title,
        body: item.body,
        imageUrl: item.imageUrl,
        toAll: item.mode != 'user',
        scheduledAt: item.scheduledAt.toLocal(),
        scheduledId: item.id,
      ),
    );
  }

  Future<void> _deleteScheduled(ScheduledNotification item) async {
    final bool? ok = await _confirm(
      title: t('حذف الإشعار المجدول'),
      message: t('سيُحذف «%s» نهائياً من قائمة المجدولة. متابعة؟').replaceFirst('%s', item.title),
      confirmLabel: t('حذف نهائي'),
    );
    if (ok != true) {
      return;
    }
    await ref.read(marketingRepositoryProvider).deleteScheduled(item.id);
    ref.invalidate(scheduledNotificationsProvider);
  }

  Future<void> _editCampaign(CampaignRecord item) {
    return _openNotifications(
      NotificationDraft(
        title: item.title,
        body: item.body,
        imageUrl: item.imageUrl,
        toAll: item.mode != 'user',
      ),
    );
  }

  Future<void> _resendCampaign(CampaignRecord item) async {
    final bool? ok = await _confirm(
      title: t('إعادة إرسال الإشعار'),
      message: t('سيُرسل «%s» الآن من جديد. متابعة؟').replaceFirst('%s', item.title),
      confirmLabel: t('إرسال الآن'),
    );
    if (ok != true) {
      return;
    }
    final repo = ref.read(marketingRepositoryProvider);
    try {
      final response = await repo.sendNotification(
        title: item.title,
        body: item.body,
        imageUrl: item.imageUrl,
        topic: item.mode == 'user' ? null : (item.topic ?? 'all'),
        targetUserId: item.mode == 'user' ? item.targetUserId : null,
      );
      final bool sent = response.status < 400;
      await repo.logCampaign(
        title: item.title,
        body: item.body,
        imageUrl: item.imageUrl,
        mode: item.mode,
        topic: item.topic,
        targetUserId: item.targetUserId,
        status: sent ? 'sent' : 'failed',
        response: sent ? null : response.data,
      );
      ref.invalidate(marketingCampaignsProvider);
      _toast(sent ? t('تمت إعادة الإرسال.') : t('الخادم رفض الإشعار.'), error: !sent);
    } on Object catch (error) {
      _toast(t('تعذّرت إعادة الإرسال: %s').replaceFirst('%s', '$error'), error: true);
    }
  }

  Future<void> _deleteCampaign(CampaignRecord item) async {
    final bool? ok = await _confirm(
      title: t('حذف الإشعار'),
      message: t('سيُحذف «%s» من سجل المرسلة. متابعة؟').replaceFirst('%s', item.title),
      confirmLabel: t('حذف'),
    );
    if (ok != true) {
      return;
    }
    await ref.read(marketingRepositoryProvider).deleteCampaign(item.id);
    ref.invalidate(marketingCampaignsProvider);
  }

  Future<bool?> _confirm({required String title, required String message, required String confirmLabel}) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('رجوع'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? AppColors.danger : null),
    );
  }

  Future<void> _toggleBanner(MarketingBanner banner, bool active) async {
    await ref.read(marketingRepositoryProvider).updateBanner(banner.id, <String, dynamic>{'is_active': active});
    ref.invalidate(marketingBannersProvider);
  }

  Future<void> _toggleCoupon(MarketingCoupon coupon, bool active) async {
    await ref.read(marketingRepositoryProvider).updateCoupon(coupon.id, <String, dynamic>{'is_active': active});
    ref.invalidate(marketingCouponsProvider);
  }

  Future<void> _deleteBanner(MarketingBanner banner) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(t('حذف البانر')),
        content: Text(t('سيُحذف «%s» نهائياً. متابعة؟').replaceFirst('%s', banner.title)),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('إلغاء'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('حذف')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(marketingRepositoryProvider).deleteBanner(banner.id);
      ref.invalidate(marketingBannersProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MarketingBanner>> banners = ref.watch(marketingBannersProvider);
    final AsyncValue<List<MarketingCoupon>> coupons = ref.watch(marketingCouponsProvider);
    final AsyncValue<List<CampaignRecord>> campaigns = ref.watch(marketingCampaignsProvider);
    final AsyncValue<List<ScheduledNotification>> scheduled = ref.watch(scheduledNotificationsProvider);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: <ButtonSegment<int>>[
                      ButtonSegment<int>(value: 0, label: Text(t('البانرات'))),
                      ButtonSegment<int>(value: 1, label: Text(t('الكوبونات'))),
                      ButtonSegment<int>(value: 2, label: Text(t('الإشعارات'))),
                    ],
                    selected: <int>{_section},
                    onSelectionChanged: (Set<int> selection) => setState(() => _section = selection.first),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (_section == 2)
                IconButton(tooltip: t('تحديث'), icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
              if (_section == 0)
                IconButton.filledTonal(tooltip: t('إضافة بانر'), icon: const Icon(Icons.add_rounded), onPressed: () => _openBannerForm())
              else if (_section == 1)
                IconButton.filledTonal(tooltip: t('إضافة كوبون'), icon: const Icon(Icons.add_rounded), onPressed: () => _openCouponForm())
              else
                IconButton.filledTonal(tooltip: t('إشعار جديد'), icon: const Icon(Icons.send_rounded), onPressed: _openNotifications),
            ],
          ),
        ),
        if (_section == 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 0, label: Text(t('المرسلة'))),
                  ButtonSegment<int>(value: 1, label: Text(t('المجدولة'))),
                ],
                selected: <int>{_notifView},
                onSelectionChanged: (Set<int> selection) => setState(() => _notifView = selection.first),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: switch (_section) {
              0 => _bannersList(banners),
              1 => _couponsList(coupons),
              _ => _notifView == 0 ? _campaignsList(campaigns) : _scheduledList(scheduled),
            },
          ),
        ),
      ],
    );
  }

  Widget _bannersList(AsyncValue<List<MarketingBanner>> banners) {
    return banners.when(
      data: (List<MarketingBanner> items) {
        if (items.isEmpty) {
          return _empty(t('لا توجد بانرات'), t('اضغط + لإضافة أول بانر'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final MarketingBanner banner = items[index];
            return _BannerTile(
              banner: banner,
              onToggleActive: (bool active) => _toggleBanner(banner, active),
              onEdit: () => _openBannerForm(banner),
              onDelete: () => _deleteBanner(banner),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _empty(t('تعذّر تحميل البانرات'), '$error'),
    );
  }

  Widget _couponsList(AsyncValue<List<MarketingCoupon>> coupons) {
    return coupons.when(
      data: (List<MarketingCoupon> items) {
        if (items.isEmpty) {
          return _empty(t('لا توجد كوبونات'), t('اضغط + لإضافة أول كوبون'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final MarketingCoupon coupon = items[index];
            return _CouponTile(
              coupon: coupon,
              onToggleActive: (bool active) => _toggleCoupon(coupon, active),
              onEdit: () => _openCouponForm(coupon),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _empty(t('تعذّر تحميل الكوبونات'), '$error'),
    );
  }

  Widget _campaignsList(AsyncValue<List<CampaignRecord>> campaigns) {
    return campaigns.when(
      data: (List<CampaignRecord> items) {
        if (items.isEmpty) {
          return _empty(t('لا توجد حملات'), t('أرسل أول إشعار من زر الإرسال'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final CampaignRecord campaign = items[index];
            return _CampaignTile(
              campaign: campaign,
              onEdit: () => _editCampaign(campaign),
              onResend: () => _resendCampaign(campaign),
              onDelete: () => _deleteCampaign(campaign),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _empty(t('تعذّر تحميل الحملات'), '$error'),
    );
  }

  Widget _scheduledList(AsyncValue<List<ScheduledNotification>> scheduled) {
    return scheduled.when(
      data: (List<ScheduledNotification> items) {
        if (items.isEmpty) {
          return _empty(t('لا توجد إشعارات مجدولة'), t('أنشئ إشعاراً واختر «جدولة» بوقت مستقبلي'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final ScheduledNotification item = items[index];
            return _ScheduledTile(
              scheduled: item,
              onEdit: () => _editScheduled(item),
              onDelete: () => _deleteScheduled(item),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _empty(t('تعذّر تحميل المجدولة'), '$error'),
    );
  }

  Widget _empty(String title, String hint) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        const SizedBox(height: 120),
        Icon(Icons.storefront_outlined, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(hint, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
      ],
    );
  }
}

class _BannerTile extends StatelessWidget {
  const _BannerTile({required this.banner, required this.onToggleActive, required this.onEdit, required this.onDelete});

  final MarketingBanner banner;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 84,
                height: 52,
                child: (banner.imageUrl ?? '').isEmpty
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_outlined),
                      )
                    : Image.network(banner.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.image_outlined)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(banner.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    [if ((banner.subtitle ?? '').isNotEmpty) banner.subtitle!, t('ترتيب: %s').replaceFirst('%s', '${banner.sortOrder}')].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            Switch(value: banner.isActive, onChanged: onToggleActive),
            IconButton(tooltip: t('تعديل'), icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
            IconButton(tooltip: t('حذف'), icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({required this.coupon, required this.onToggleActive, required this.onEdit});

  final MarketingCoupon coupon;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String expiry = coupon.expiresAt == null ? t('لا انتهاء') : t('ينتهي %s').replaceFirst('%s', _dayFormat.format(coupon.expiresAt!));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: coupon.isWelcome ? AppColors.warning.withValues(alpha: 0.15) : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(coupon.code.length > 4 ? coupon.code.substring(0, 4) : coupon.code,
                  style: TextStyle(fontWeight: FontWeight.w800, color: coupon.isWelcome ? AppColors.warning : theme.colorScheme.primary, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(coupon.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    [coupon.typeLabel, if (coupon.minOrder > 0) '${t('من')} ${coupon.minOrder.round()} $currency', expiry].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            Switch(value: coupon.isActive, onChanged: onToggleActive),
            IconButton(tooltip: t('تعديل'), icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
          ],
        ),
      ),
    );
  }
}

class _CampaignTile extends StatelessWidget {
  const _CampaignTile({required this.campaign, required this.onEdit, required this.onResend, required this.onDelete});

  final CampaignRecord campaign;
  final VoidCallback onEdit;
  final VoidCallback onResend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool failed = campaign.status == 'failed';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Icon(
              campaign.mode == 'user' ? Icons.person_outline_rounded : Icons.groups_outlined,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(campaign.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    [campaign.body, if (campaign.createdAt != null) _dayFormat.format(campaign.createdAt!)].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (failed ? AppColors.danger : AppColors.success).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(failed ? t('فشل') : t('أُرسل'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: failed ? AppColors.danger : AppColors.success)),
            ),
            PopupMenuButton<String>(
              tooltip: t('خيارات'),
              onSelected: (String value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'resend') {
                  onResend();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.edit_outlined), title: Text(t('تعديل'))),
                  ),
                  PopupMenuItem<String>(
                    value: 'resend',
                    child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.send_rounded), title: Text(t('إعادة الإرسال'))),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                      title: Text(t('حذف'), style: const TextStyle(color: AppColors.danger)),
                    ),
                  ),
                ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduledTile extends StatelessWidget {
  const _ScheduledTile({required this.scheduled, required this.onEdit, required this.onDelete});

  final ScheduledNotification scheduled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _statusColor() {
    switch (scheduled.status) {
      case 'sent':
        return AppColors.success;
      case 'failed':
        return AppColors.danger;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = _statusColor();
    final String when = DateFormat('dd/MM/yyyy • HH:mm').format(scheduled.scheduledAt.toLocal());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(t(scheduled.statusLabel), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(scheduled.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${scheduled.body} • $when',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            if (scheduled.status == 'scheduled')
              PopupMenuButton<String>(
                tooltip: t('خيارات'),
                onSelected: (String value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.edit_outlined), title: Text(t('تعديل'))),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                      title: Text(t('حذف نهائي'), style: TextStyle(color: AppColors.danger)),
                    ),
                  ),
                ],
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
