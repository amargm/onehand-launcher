import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/folder_icons.dart';
import '../../../core/models/app_folder.dart';
import '../../../core/models/app_info.dart';
import '../../../core/providers/context_settings_provider.dart';
import '../../../core/providers/folders_provider.dart';
import '../../../core/providers/headphone_provider.dart';
import '../../../core/providers/media_apps_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/apps_service.dart';
import '../../folder/folder_screen.dart';
import '../../search/search_overlay.dart';

/// Unified dock panel: context status row on top, action buttons below.
class AppDock extends ConsumerWidget {
  const AppDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    final rightHanded = ref.watch(rightHandedProvider);
    final accent = Theme.of(context).colorScheme.primary;

    final searchCircle = _DockCircle(
      icon: Icons.search_rounded,
      isSearch: true,
      accent: accent,
      onTap: () => _openSearch(context),
    );

    final folderCircles =
        folders
            .map(
              (f) => _DockCircle(
                icon: kFolderIcons[f.iconKey] ?? Icons.folder_rounded,
                isSearch: false,
                accent: accent,
                onTap: () => _openFolder(context, f),
              ),
            )
            .toList();

    final rowChildren =
        rightHanded
            ? [...folderCircles, searchCircle]
            : [searchCircle, ...folderCircles];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        // ── Outer context-aware shell ──────────────────────────────────────
        // Matches the HTML outer rounded rectangle (#0D0D0D, subtle border)
        // that wraps both the context ring and the inner dock.
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Context-aware outer ring ───────────────────────────────────
            // Shows media app circles when headphones connected;
            // otherwise shows context-indicator circles (time, day, date…).
            _ContextMiniRow(),
            const SizedBox(height: 6),
            // ── Inner dock panel ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: rowChildren,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFolder(BuildContext context, AppFolder folder) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => FolderScreen(folder: folder),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => const SearchOverlay(),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

class _ContextMiniRow extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ContextMiniRow> createState() => _ContextMiniRowState();
}

class _ContextMiniRowState extends ConsumerState<_ContextMiniRow> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Tick once per minute — context chips only change at hour / day boundaries.
    // Headphone state and media apps are driven reactively by Riverpod providers
    // (headphoneProvider polls once every 5 s from one shared timer).
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(contextItemsProvider);
    final headphones = ref.watch(headphoneProvider);
    final mediaApps = ref.watch(mediaAppsProvider).valueOrNull ?? const [];
    final accent = Theme.of(context).colorScheme.primary;

    // ── Headphones connected: media app circles fill the outer ring ────────
    if (headphones && mediaApps.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              mediaApps.take(6).map((app) => _MediaAppIcon(app: app)).toList(),
        ),
      );
    }

    // ── Default: context-indicator circles (icon-only, 32 px = w-8 h-8) ───
    final chips =
        ContextItemType.values
            .where((t) => enabled.contains(t))
            .map((t) => _iconFor(t, accent, headphones))
            .toList();

    if (chips.isEmpty) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: chips,
      ),
    );
  }

  Widget _iconFor(ContextItemType type, Color accent, bool headphones) {
    final h = _now.hour;
    final (IconData icon, bool active) = switch (type) {
      ContextItemType.time =>
        h >= 9 && h < 18
            ? (Icons.bolt_rounded, true)
            : h >= 18 && h < 23
            ? (Icons.nightlight_rounded, true)
            : (Icons.bedtime_outlined, false),
      ContextItemType.headphone =>
        headphones
            ? (Icons.headphones_rounded, true)
            : (Icons.headphones_outlined, false),
      ContextItemType.day => (Icons.calendar_today_outlined, true),
      ContextItemType.date => (Icons.event_outlined, true),
    };

    // 32 px circle matches the HTML outer-ring icon size (w-8 h-8)
    final color = active ? accent.withValues(alpha: 0.85) : Colors.white38;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Icon(icon, color: color, size: 15),
    );
  }
}

// ── Media app quick-launch icon ───────────────────────────────────────────────
/// Small circular icon shown in the headphone media strip.
class _MediaAppIcon extends StatelessWidget {
  const _MediaAppIcon({required this.app});

  final AppInfo app;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppsService.openApp(app.packageName),
      child: Container(
        // 32 px = w-8 h-8 from the HTML outer context ring spec
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1E1E1E),
        ),
        child: ClipOval(
          child:
              app.icon != null
                  ? Image.memory(
                    app.icon!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder:
                        (_, __, ___) => const Icon(
                          Icons.music_note_rounded,
                          size: 18,
                          color: Colors.white54,
                        ),
                  )
                  : const Icon(
                    Icons.music_note_rounded,
                    size: 18,
                    color: Colors.white54,
                  ),
        ),
      ),
    );
  }
}

/// Circular dock button — w-14 h-14 (56 px) matching the HTML inner dock.
/// Search: accent-filled circle with accent glow shadow.
/// Folders: dark #121212 surface circle with subtle border.
class _DockCircle extends StatelessWidget {
  const _DockCircle({
    required this.icon,
    required this.isSearch,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final bool isSearch;
  final Color accent;
  final VoidCallback onTap;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Search: accent fill; Folders: surface-container (#121212)
          color: isSearch ? accent : const Color(0xFF121212),
          boxShadow:
              isSearch
                  ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.30),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ]
                  : null,
          border:
              isSearch
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(
          icon,
          color: isSearch ? Colors.white : Colors.white60,
          size: 24,
        ),
      ),
    );
  }
}
