import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_l10n.dart';
import '../../auth/domain/staff_role.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../catalog/presentation/catalog_screen.dart';
import '../../customers/presentation/customers_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../employees/presentation/employees_screen.dart';
import '../../marketing/presentation/marketing_screen.dart';
import '../../store_hours/presentation/store_hours_screen.dart';
import '../../wallet/presentation/wallet_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class _Destination {
  const _Destination({required this.title, required this.icon, required this.page});

  final String title;
  final IconData icon;
  final Widget page;
}

/// الغلاف الرئيسي بعد الدخول: تبويبات حسب صلاحية الدور.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AdminAuthState? auth = ref.watch(authControllerProvider).valueOrNull;
    final StaffRole role = auth?.role ?? StaffRole.unknown;

    final List<_Destination> destinations = <_Destination>[
      const _Destination(title: 'لوحة المعلومات', icon: Icons.insights_rounded, page: DashboardScreen()),
      if (role.canManageCatalog)
        const _Destination(title: 'الكتالوج', icon: Icons.inventory_2_rounded, page: CatalogScreen()),
      if (role.canManageMarketing)
        const _Destination(title: 'التسويق', icon: Icons.campaign_rounded, page: MarketingScreen()),
      if (role.canManageWallet)
        const _Destination(title: 'المحفظة', icon: Icons.account_balance_wallet_rounded, page: WalletScreen()),
      if (role.canManageCustomers)
        const _Destination(title: 'الزبائن', icon: Icons.people_alt_rounded, page: CustomersScreen()),
      if (role.canManageStoreHours)
        const _Destination(title: 'أوقات العمل', icon: Icons.schedule_rounded, page: StoreHoursScreen()),
      if (role.isSuperAdmin)
        const _Destination(title: 'الموظفون', icon: Icons.groups_rounded, page: EmployeesScreen()),
      const _Destination(title: 'الإعدادات', icon: Icons.settings_rounded, page: SettingsScreen()),
    ];

    final int safeIndex = _index < destinations.length ? _index : 0;
    final _Destination current = destinations[safeIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(t(current.title)),
        actions: <Widget>[
          IconButton(
            tooltip: t('تسجيل الخروج'),
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: safeIndex,
        children: <Widget>[for (final _Destination destination in destinations) destination.page],
      ),
      bottomNavigationBar: _ManagerNavBar(
        destinations: destinations,
        selectedIndex: safeIndex,
        onSelected: (int value) => setState(() => _index = value),
      ),
    );
  }
}

/// شريط تنقل سفلي أفقي قابل للتمرير: يظهر كل تبويب أيقونةً وتسميةً كاملة في
/// سطر واحد دون اقتطاع، ويمرّر تلقائياً إلى التبويب المحدّد عند تغييره.
class _ManagerNavBar extends StatefulWidget {
  const _ManagerNavBar({required this.destinations, required this.selectedIndex, required this.onSelected});

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<_ManagerNavBar> createState() => _ManagerNavBarState();
}

class _ManagerNavBarState extends State<_ManagerNavBar> {
  final Map<int, GlobalKey> _keys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _scrollToSelected();
  }

  @override
  void didUpdateWidget(covariant _ManagerNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? context = _keys[widget.selectedIndex]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color border = theme.dividerColor;
    final Color selectedColor = scheme.primary;
    final Color unselectedColor = scheme.onSurface.withValues(alpha: 0.6);
    return Material(
      color: scheme.surface,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: SafeArea(
        top: false,
        child: Container(
          height: 66,
          decoration: BoxDecoration(border: Border(top: BorderSide(color: border.withValues(alpha: 0.6)))),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            itemCount: widget.destinations.length,
            itemBuilder: (BuildContext context, int index) {
              final _Destination d = widget.destinations[index];
              final bool selected = index == widget.selectedIndex;
              final Color color = selected ? selectedColor : unselectedColor;
              return InkWell(
                key: _keys.putIfAbsent(index, () => GlobalKey()),
                onTap: () => widget.onSelected(index),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? selectedColor.withValues(alpha: 0.14) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(d.icon, color: color, size: 22),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t(d.title),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
