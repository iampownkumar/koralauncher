import 'package:flutter/material.dart';

/// Global navigator key so native-driven routes (e.g. accessibility) avoid importing [main.dart].
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
