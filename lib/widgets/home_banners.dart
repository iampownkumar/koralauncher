import 'package:flutter/material.dart';

/// Returns an empty column — permission banners removed.
/// Onboarding flow and Permissions & Privacy screen handle all setup prompts.
class HomeBanners extends StatelessWidget {
  // ignore: unused_element
  final dynamic controller;
  const HomeBanners({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
