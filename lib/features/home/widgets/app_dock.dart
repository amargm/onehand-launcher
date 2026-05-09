import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/folder_icons.dart';
import '../../../core/models/app_folder.dart';
import '../../../core/models/app_info.dart';
import '../../../core/models/schedule_rule.dart';
import '../../../core/models/special_date_event.dart';
import '../../../core/providers/apps_provider.dart';
import '../../../core/providers/context_apps_provider.dart';
import '../../../core/providers/schedule_rules_provider.dart';
import '../../../core/providers/folders_provider.dart';
import '../../../core/providers/headphone_provider.dart';
import '../../../core/providers/recent_apps_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/special_date_provider.dart';
import '../../../core/services/apps_service.dart';
import '../../search/search_overlay.dart';
import 'circular_app_icon.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppDock
//
// Three-layer stack (bottom-aligned):
//
//   [_FolderPanel]   ← separate rounded container; slides up above the shell
//                      when a folder circle is tapped; NOT concentric.
//   Outer shell      ← invisible when headphones disconnected.
//     └── Context shell row  (user-configured apps, 32 px)
//     └── Inner dock  (folder + search circles, 56 px)
//
// ─────────────────────────────────────────────────────────────────────────────

class AppDock extends ConsumerStatefulWidget {
  const AppDock({super.key});

  @override
  ConsumerState<AppDock> createState() => _AppDockState();
}

class _AppDockState extends ConsumerState<AppDock> {
  String? _activeFolderId;
  bool _messageBoxOpen = false;
  // Retains the last opened folder so close animation renders content
  // while opacity fades and height shrinks — avoids instant collapse.
  AppFolder? _lastActiveFolder;

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(foldersProvider);
    final rightHanded = ref.watch(rightHandedProvider);
    final headphones = ref.watch(headphoneProvider);
    final dayActive = ref.watch(isScheduleContextActiveProvider);
    final showFolderLabels = ref.watch(showFolderLabelsProvider);
    final showSearchLabel = ref.watch(showSearchLabelProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final hasSpecialDate = ref.watch(hasActiveSpecialDateProvider);
    final activeSpecialEvents = ref.watch(activeSpecialDateEventsProvider);
    final globalSnoozeMins = ref.watch(snoozeDurationProvider);

    // Auto-close the message panel if all events were dismissed/snoozed.
    if (activeSpecialEvents.isEmpty && _messageBoxOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _messageBoxOpen = false);
      });
    }

    // Icon to show in the amber dot — reflects the single event's icon,
    // or a generic calendar icon when multiple events are active.
    final dotIcon =
        activeSpecialEvents.length == 1
            ? (kSpecialDateIcons[activeSpecialEvents.first.iconKey] ??
                Icons.celebration_rounded)
            : Icons.event_rounded;

    // Outer shell visible when either context source is active.
    final shellVisible = headphones || dayActive;

    // If the active folder was removed, clear selection.
    final activeFolder =
        _activeFolderId == null
            ? null
            : folders.where((f) => f.id == _activeFolderId).firstOrNull;

    // Keep the last non-null folder so close animation has real content.
    if (activeFolder != null) _lastActiveFolder = activeFolder;
    final displayFolder = activeFolder ?? _lastActiveFolder;

    final searchCircle = _DockCircle(
      icon: Icons.search_rounded,
      isSearch: true,
      isActive: false,
      accent: accent,
      label: 'Search',
      showLabel: showSearchLabel,
      onTap: () {
        setState(() => _activeFolderId = null);
        _openSearch(context);
      },
      onLongPress: () {
        AppsService.forceHaptic();
        AppsService.openBrowserSearch();
      },
    );

    final folderCircles =
        folders
            .map(
              (f) => _DockCircle(
                icon: kFolderIcons[f.iconKey] ?? Icons.folder_rounded,
                isSearch: false,
                isActive: _activeFolderId == f.id,
                accent: accent,
                label: f.name,
                showLabel: showFolderLabels,
                // Folder tap is locked while the message box is open.
                onTap:
                    _messageBoxOpen
                        ? () {}
                        : () => setState(
                          () =>
                              _activeFolderId =
                                  _activeFolderId == f.id ? null : f.id,
                        ),
              ),
            )
            .toList();

    final dockRow =
        rightHanded
            ? [...folderCircles, searchCircle]
            : [searchCircle, ...folderCircles];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Special-date message box ───────────────────────────────────
          // Slides in above the dock when the amber dot is tapped.
          // Independent of the outer shell — visible even when shell is off.
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeInOutQuart,
              child:
                  _messageBoxOpen && activeSpecialEvents.isNotEmpty
                      ? AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SpecialDateMessagePanel(
                              events: activeSpecialEvents,
                              globalSnoozeMins: globalSnoozeMins,
                              onClose:
                                  () => setState(() => _messageBoxOpen = false),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ),

          // ── Folder panel ───────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutQuart,
              child:
                  displayFolder != null
                      ? AnimatedOpacity(
                        opacity: activeFolder != null ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve:
                            activeFolder != null
                                ? Curves.easeIn
                                : Curves.easeOut,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _FolderPanel(
                              key: ValueKey(displayFolder.id),
                              folder: displayFolder,
                              onClose:
                                  () => setState(() => _activeFolderId = null),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ),

          // ── Outer shell + inner dock — wrapped in Stack for amber dot ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Outer shell + inner dock (unchanged layout)
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOutQuart,
                  padding:
                      shellVisible ? const EdgeInsets.all(8) : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color:
                        shellVisible
                            ? const Color(0xFF111111)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color:
                          shellVisible
                              ? Colors.white.withValues(alpha: 0.16)
                              : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeInOutQuart,
                        child:
                            shellVisible
                                ? AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeIn,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (dayActive)
                                        const _DayContextShellRow(),
                                      if (dayActive && headphones)
                                        Container(
                                          height: 1,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                          color: Colors.white.withValues(
                                            alpha: 0.06,
                                          ),
                                        ),
                                      if (headphones) const _ContextShellRow(),
                                      const SizedBox(height: 6),
                                    ],
                                  ),
                                )
                                : AnimatedOpacity(
                                  opacity: 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (dayActive)
                                        const _DayContextShellRow(),
                                      if (headphones) const _ContextShellRow(),
                                      const SizedBox(height: 6),
                                    ],
                                  ),
                                ),
                      ),

                      // ── Inner dock ──────────────────────────────────────
                      IntrinsicWidth(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF272727),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                dockRow
                                    .expand(
                                      (c) => [c, const SizedBox(width: 16)],
                                    )
                                    .toList()
                                  ..removeLast(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Amber dot — floats top-right, fully independent ─────────
              if (hasSpecialDate)
                Positioned(
                  top: -6,
                  right: 0,
                  child: _SpecialDateDot(
                    isOpen: _messageBoxOpen,
                    iconData: dotIcon,
                    onTap:
                        () => setState(() {
                          if (!_messageBoxOpen) {
                            // Close any open folder before showing the message box.
                            // Do NOT null _lastActiveFolder — it is kept so the
                            // folder close animation has content to fade out.
                            _activeFolderId = null;
                          }
                          _messageBoxOpen = !_messageBoxOpen;
                        }),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSearch(BuildContext context) {
    // Set provider BEFORE pushing the route so the clock starts fading
    // immediately — avoids a 1-frame gap where the clock hasn't dimmed yet.
    // Must NOT be set inside SearchOverlay.initState, as that fires during
    // the widget-build phase and triggers a Riverpod "provider modified
    // during build" exception.
    ref.read(searchOverlayActiveProvider.notifier).state = true;
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

// ── Folder panel ──────────────────────────────────────────────────────────────
/// Pops up above the outer shell as a SEPARATE rounded container (not concentric).
/// Same width as the dock. Shows folder apps: max 10, in rows of 5.
class _FolderPanel extends ConsumerWidget {
  const _FolderPanel({super.key, required this.folder, required this.onClose});

  final AppFolder folder;
  final VoidCallback onClose;

  static const int _kMaxApps = 10;
  static const int _kCols = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final appsAsync = ref.watch(appsProvider);

    final pkgMap = {
      for (final a in appsAsync.valueOrNull ?? <AppInfo>[]) a.packageName: a,
    };

    final apps =
        folder.packageNames
            .take(_kMaxApps)
            .map((pkg) => pkgMap[pkg])
            .whereType<AppInfo>()
            .toList();

    // Split into rows of _kCols.
    final rows = <List<AppInfo?>>[];
    for (var i = 0; i < apps.length; i += _kCols) {
      rows.add(
        List<AppInfo?>.from(
          apps.sublist(i, (i + _kCols).clamp(0, apps.length)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                kFolderIcons[folder.iconKey] ?? Icons.folder_rounded,
                color: accent,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  folder.name,
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    color: Colors.white38,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white24,
                  size: 20,
                ),
              ),
            ],
          ),

          if (apps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'No apps · add them in Settings',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    color: Colors.white24,
                  ),
                ),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_kCols, (c) {
                  final app = c < rows[r].length ? rows[r][c] : null;
                  return _FolderPanelIcon(app: app);
                }),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Folder panel app icon (44 px + 8 px label) ───────────────────────────────
// ConsumerWidget so it can access foldersProvider (long-press menu) and
// recentAppsProvider (records launches for the search recents list).
class _FolderPanelIcon extends ConsumerWidget {
  const _FolderPanelIcon({this.app});

  final AppInfo? app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (app == null) {
      // Invisible spacer — keeps grid columns aligned.
      return const SizedBox(width: 44);
    }
    return GestureDetector(
      onTap: () {
        ref.read(recentAppsProvider.notifier).recordLaunch(app!.packageName);
        AppsService.openApp(app!.packageName);
      },
      onLongPress: () => showAppContextMenu(context, ref, app!),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1E1E1E),
            ),
            child: ClipOval(
              child:
                  app!.icon != null
                      ? Image.memory(
                        app!.icon!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                              Icons.apps_rounded,
                              size: 20,
                              color: Colors.white54,
                            ),
                      )
                      : const Icon(
                        Icons.apps_rounded,
                        size: 20,
                        color: Colors.white54,
                      ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 52,
            child: Text(
              app!.appName,
              style: GoogleFonts.sora(
                fontSize: 8,
                color: Colors.white54,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
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

    final shellApps =
        configuredPkgs
            .take(kContextShellMaxApps)
            .map((pkg) => pkgMap[pkg])
            .whereType<AppInfo>()
            .toList();

    // No apps configured — headphone gating means this branch is only reached
    // while the app list is loading. Return nothing rather than ghost circles.
    if (shellApps.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: shellApps.map((app) => _ContextAppIcon(app: app)).toList(),
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
          child:
              app.icon != null
                  ? Image.memory(
                    app.icon!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder:
                        (_, __, ___) => const Icon(
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

// ── Day-of-week context shell row ─────────────────────────────────────────────
/// Shown inside the outer shell on the user's selected days of the week.
/// Displays up to [kDayContextMaxApps] (5) app icons as 32 px circles.
class _DayContextShellRow extends ConsumerWidget {
  const _DayContextShellRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configuredPkgs = ref.watch(activeScheduleAppsProvider);
    final appsAsync = ref.watch(appsProvider);

    final pkgMap = {
      for (final a in appsAsync.valueOrNull ?? <AppInfo>[]) a.packageName: a,
    };

    final apps =
        configuredPkgs
            .take(kScheduleMaxApps)
            .map((pkg) => pkgMap[pkg])
            .whereType<AppInfo>()
            .toList();

    // No apps resolved — either loading or all scheduled apps were uninstalled.
    // Return nothing rather than ghost circles (mirrors _ContextShellRow behaviour).
    if (apps.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: apps.map((app) => _ContextAppIcon(app: app)).toList(),
      ),
    );
  }
}

// ── Inner dock circle button (56 px) ─────────────────────────────────────────
/// Search: accent-filled with glow shadow.
/// Folders: dark #121212 surface circle.
/// Shows a text label below the circle when [showLabel] is true.
class _DockCircle extends StatelessWidget {
  const _DockCircle({
    required this.icon,
    required this.isSearch,
    required this.isActive,
    required this.accent,
    required this.label,
    required this.showLabel,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final bool isSearch;
  final bool isActive;
  final Color accent;
  final String label;
  final bool showLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
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
                : isActive
                ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.40),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
                : null,
        border:
            isSearch
                ? null
                : isActive
                ? Border.all(color: accent.withValues(alpha: 0.85), width: 2)
                : Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Icon(
        icon,
        // On a light/white accent background the white icon disappears.
        // Use black for high-luminance accents, white otherwise.
        color:
            isSearch
                ? (accent.computeLuminance() > 0.4
                    ? Colors.black.withValues(alpha: 0.80)
                    : Colors.white)
                : (isActive ? accent : Colors.white60),
        size: 24,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child:
          showLabel
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  circle,
                  const SizedBox(height: 4),
                  SizedBox(
                    width: _size + 8,
                    child: Text(
                      label,
                      style: GoogleFonts.sora(
                        fontSize: 9,
                        color: Colors.white38,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
              : circle,
    );
  }
}

// ── Amber dot — pulsing special-date indicator ────────────────────────────────
/// Fully independent of the outer shell. Pulsing scale + glow animation.
/// Tapping toggles the message box open/closed.
class _SpecialDateDot extends StatefulWidget {
  const _SpecialDateDot({
    required this.isOpen,
    required this.iconData,
    required this.onTap,
  });

  final bool isOpen;
  final IconData iconData;
  final VoidCallback onTap;

  @override
  State<_SpecialDateDot> createState() => _SpecialDateDotState();
}

class _SpecialDateDotState extends State<_SpecialDateDot>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  static const _amber = Color(0xFFFFB830);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.88,
      end: 1.14,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppsService.forceHaptic();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder:
            (_, __) => Transform.scale(
              scale: widget.isOpen ? 1.0 : _scale.value,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      widget.isOpen ? _amber.withValues(alpha: 0.55) : _amber,
                  boxShadow:
                      widget.isOpen
                          ? null
                          : [
                            BoxShadow(
                              color: _amber.withValues(alpha: 0.55),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                    width: 1.5,
                  ),
                ),
                child: Icon(widget.iconData, size: 14, color: Colors.white),
              ),
            ),
      ),
    );
  }
}

// ── Special-date message panel ────────────────────────────────────────────────
/// Slides in above the dock when the amber dot is tapped.
/// Styled like the folder panel — dark rounded container.
/// Top border uses amber to visually link it to the dot.
/// Each event card has its own Dismiss and Snooze buttons.
class _SpecialDateMessagePanel extends ConsumerWidget {
  const _SpecialDateMessagePanel({
    required this.events,
    required this.globalSnoozeMins,
    required this.onClose,
  });

  final List<SpecialDateEvent> events;
  final int globalSnoozeMins;
  final VoidCallback onClose;

  static const _amber = Color(0xFFFFB830);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxHeight = (MediaQuery.of(context).size.height * 0.36).clamp(
      220.0,
      280.0,
    );
    final icon =
        kSpecialDateIcons[events.first.iconKey] ?? Icons.celebration_rounded;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _amber.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Icon(icon, color: _amber, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    events.length == 1 ? events.first.name : 'Special day',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: _amber.withValues(alpha: 0.90),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white24,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Scrollable event cards
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < events.length; i++) ...[
                    if (i > 0)
                      Divider(
                        color: Colors.white.withValues(alpha: 0.06),
                        height: 20,
                      ),
                    _EventCard(
                      event: events[i],
                      globalSnoozeMins: globalSnoozeMins,
                      onAction: onClose,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single event card inside the message panel ────────────────────────────────
class _EventCard extends ConsumerWidget {
  const _EventCard({
    required this.event,
    required this.globalSnoozeMins,
    required this.onAction,
  });

  final SpecialDateEvent event;
  final int globalSnoozeMins;
  final VoidCallback onAction; // called after dismiss/snooze to close panel

  static const _amber = Color(0xFFFFB830);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event.name.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              event.name,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        // Rich-text message render
        _RichMessageDisplay(paragraphs: event.message),
        const SizedBox(height: 14),
        // Action buttons
        Row(
          children: [
            _ActionButton(
              label: 'Dismiss',
              icon: Icons.check_rounded,
              color: Colors.white38,
              onTap: () {
                dismissSpecialDate(ref, event);
                onAction();
              },
            ),
            const SizedBox(width: 10),
            _ActionButton(
              label: 'Snooze',
              icon: Icons.snooze_rounded,
              color: _amber.withValues(alpha: 0.80),
              onTap: () {
                snoozeSpecialDate(ref, event, globalSnoozeMins);
                onAction();
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ── Rich message display ──────────────────────────────────────────────────────
class _RichMessageDisplay extends StatelessWidget {
  const _RichMessageDisplay({required this.paragraphs});

  final List<RichParagraph> paragraphs;

  @override
  Widget build(BuildContext context) {
    if (paragraphs.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          paragraphs.map((p) {
            final style = GoogleFonts.sora(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.80),
              fontWeight: p.bold ? FontWeight.w700 : FontWeight.w400,
              fontStyle: p.italic ? FontStyle.italic : FontStyle.normal,
              height: 1.55,
            );
            final text = p.isBullet ? '•  ${p.text}' : p.text;
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(text, style: style, textAlign: p.align),
            );
          }).toList(),
    );
  }
}

// ── Action button (Dismiss / Snooze) ─────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
