import 'package:flutter/material.dart';
import '../state/home_controller.dart';
import 'permission_banners.dart';

class HomeBanners extends StatelessWidget {
  final HomeController controller;
  
  const HomeBanners({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!controller.isDefaultLauncher)
          const DefaultLauncherBanner(),
        if (!controller.hasAccessibilityPermission)
          AccessibilityPermissionBanner(
            onEnabled: controller.triggerRefresh,
          ),
        if (controller.hasAccessibilityPermission && !controller.hasUsagePermission)
          UsagePermissionBanner(
            onEnabled: controller.triggerRefresh,
          ),
      ],
    );
  }
}
