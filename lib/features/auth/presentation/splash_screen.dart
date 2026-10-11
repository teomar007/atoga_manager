import 'package:flutter/material.dart';

import '../../../core/widgets/brand_logo.dart';

/// شاشة إقلاع: تظهر أثناء التحقق من الجلسة والدور.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BrandLogo(height: 150),
            SizedBox(height: 28),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
