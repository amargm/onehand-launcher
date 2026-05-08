import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/folder_icons.dart';
import '../../../core/models/app_folder.dart';
import '../../../core/models/app_info.dart';
import '../../../core/providers/apps_provider.dart';
import '../../../core/providers/context_apps_provider.dart';
import '../../../core/providers/folders_provider.dart';
import '../../../core/providers/headphone_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/apps_service.dart';
import '../../folder/folder_screen.dart';
import '../../search/search_overlay.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppDock
//
// Two-layer concentric container:
//
//   Outer shell (#0D0D0D): invisible when headphones disconnected,
//                          expands smoothly when connected.
//     └── [AnimatedSize] Context shell row  (user-configured apps, 32 px)
//     └── Inner dock (#1E1E1E)  (folder + search circles, 56 px)
//
// When headphones disconnected: outer shell has padding=0, color=transparent,
// border=transparent — fully invisible; inner dock appears standalone.
// ─────────────────────────────────────────────────────────────────────────────

class AppDock extends ConsumerWidget {
  const AppDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    final rightHanded = ref.watch(rightHandedProvider);
    final headphones = ref.watch(headphoneProvider);
    final accent = Theme.of(context).colorScheme.primary;

    final searchCircle = _DockCircle(
      icon: Icons.search_rounded,
      isSearch: true,
      accent: accent,
      onTap: () => _openSearch(context),
    );

    final folderCircles = folders
        .map(
          (f) => _DockCircle(
            icon: kFolderIcons[f.iconKey] ?? Icons.folder_rounded,
            isSearch: false,
            accent: accent,
            onTap: () => _openFolder(context, f),
          ),
        )
        .toList();

    final dockRow = rightHanded
        ? [...folderCircles, searchCircle]
        : [searchCircle, ...folderCircles];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        // Outer shell is invisible when headphones disconnected:
        //   padding → 0  /  color → transparent  /  border → transparent
        // All three properties animate to their visible values when connected.
        padding: headphones ? const EdgeInsets.all(8) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: headphones ? const Color(0xFF0D0D0D) : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: headphones
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Context shell ─────────────────────────────────────────────
            // AnimatedSize:   0 height → full height (smooth grow)
            // AnimatedSwitcher: cross-fades content in/out
            AnimatedSize(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: headphones
                    ? const Column(
                        key: ValueKey('shell'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ContextShellRow(),
                          SizedBox(height: 6),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ),

            // ── Inner dock — always visible ───────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: dockRow,
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
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => const SearchOverlay(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

// ── Context shell row ─────────────────────────────────────────────────────────
/// Shown inside the outer shell when headphones / BT are connected.
/// Displays up to 4 user-configured app icons as 32 px circles.
class _ContextShellRow extends ConsumerWidget {
  const _ContextShellRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configuredPkgs = ref.watch(contextShellAppsProvider);
    final appsAsync = ref.watch(appsProvider);

    final pkgMap = {
      for (final a in appsAsync.valueOrNull ?? <AppInfo>[]) a.packageName: a,
    };

    final shellApps = configuredPkgs
        .take(kContextShellMaxApps)
        .map((pkg) => pkgMap[pkg])
        .whereType<AppInfo>()
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: shellApps.isEmpty
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceAround,
        children: shellApps.isEmpty
            // Ghost placeholders hint that apps can be configured in Settings
            ? List.generate(
                2,
                (_) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                ),
              )
            : shellApps.map((app) => _ContextAppIcon(app: app)).toList(),
      ),
    );
  }
}

// ── Context app icon (32 px) ──────────────────────────────────────────────────
class _ContextAppIcon extends StatelessWidget {
  const _ContextAppIcon({required this.app});

  final AppInfo app;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppsService.openApp(app.packageName),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1E1E1E),
        ),
        child: ClipOval(
          child: app.icon != null
              ? Image.memory(
                  app.icon!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.apps_rounded,
                    size: 16,
                    color: Colors.white54,
                  ),
                )
              : const Icon(
                  Icons.apps_rounded,
                  size: 16,
                  color: Colors.white54,
                ),
        ),
      ),
    );
  }
}

// ── Inner dock circle button (56 px) ─────────────────────────────────────────
/// Search: accent-filled with glow shadow.
/// Folders: dark #121212 surface circle.
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
          color: isSearch ? accent : const Color(0xFF121212),
          boxShadow: isSearch
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.30),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
          border: isSearch
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
