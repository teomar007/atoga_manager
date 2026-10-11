import 'package:flutter/material.dart';

/// شعار ATOGA MANAGER — يتبدّل تلقائياً حسب الوضع (فاتح/داكن).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark
          ? 'assets/images/atoga_manager_logo_dark.png'
          : 'assets/images/atoga_manager_logo_light.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) => Icon(
        Icons.storefront_rounded,
        size: height,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
