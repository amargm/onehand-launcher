import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/settings_provider.dart';
import 'features/home/home_screen.dart';

class OneHandApp extends ConsumerWidget {
  const OneHandApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    return MaterialApp(
      title: 'One-Handed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(accent),
      home: const HomeScreen(),
    );
  }
}
