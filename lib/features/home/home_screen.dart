import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/app_info.dart';
import '../../core/providers/apps_provider.dart';
import '../../core/providers/folders_provider.dart';
import '../../core/providers/recent_apps_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/apps_service.dart';
import '../../core/services/launcher_service.dart';
import '../settings/settings_screen.dart';
import '../widgets/widgets_screen.dart';
import 'widgets/app_dock.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;
  final _widgetKey = GlobalKey<WidgetsScreenState>();
  double _prevPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    final page = _pageController.page;
    if (page == null) return;
    // Only call resetToCurrentYear once when crossing the 0.5 threshold back
    // toward home — not on every frame — to avoid per-frame setState jank.
    if (_prevPage >= 0.5 && page < 0.5) {
      _widgetKey.currentState?.resetToCurrentYear();
    }
    _prevPage = page;
  }

  @override
  Widget build(BuildContext context) {
    final wallpaper = ref.watch(wallpaperPathProvider);

    // Scaffold background: wallpaper file if one is set, otherwise pure black.
    // The version key ensures Image.file never serves a stale cached decode
    // when the same file path is overwritten with new wallpaper bytes.
    final Widget background =
        wallpaper.path != null
            ? Image.file(
              File(wallpaper.path!),
              key: ValueKey(wallpaper.version),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
            )
            : const SizedBox.shrink();

    // Intercept back press — a launcher should never exit.
    // If already on the widget page, animate back to home instead of exiting.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          final page = _pageController.page;
          if (page != null && page > 0.5) {
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView(
          controller: _pageController,
          // BouncingScrollPhysics gives an elastic, iOS-style feel at the
          // boundaries instead of the rigid Android glow-clamp default.
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            // Page 0 — home: scales slightly back + dims as widgets slides in.
            // AnimatedBuilder listens to the page controller so the transform
            // updates every scroll frame without rebuilding the heavy child.
            AnimatedBuilder(
              animation: _pageController,
              builder: (_, child) {
                final p =
                    _pageController.hasClients
                        ? (_pageController.page ?? 0.0).clamp(0.0, 1.0)
                        : 0.0;
                return Transform.scale(
                  scale: 1.0 - p * 0.04,
                  alignment: Alignment.center,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child!,
                      // Lightweight dim overlay — just a solid colour rectangle,
                      // far cheaper than Opacity on the whole child subtree.
                      IgnorePointer(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: p * 0.50),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [background, _HomeBody()],
              ),
            ),
            // Page 1 — widgets: fades in from transparent as the user swipes
            // toward it, giving a soft cross-dissolve feel.
            AnimatedBuilder(
              animation: _pageController,
              builder: (_, child) {
                final p =
                    _pageController.hasClients
                        ? (_pageController.page ?? 0.0).clamp(0.0, 1.0)
                        : 0.0;
                return Opacity(opacity: p, child: child);
              },
              child: WidgetsScreen(key: _widgetKey),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerStatefulWidget {
  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody>
    with WidgetsBindingObserver {
  bool _isDefault = true; // optimistic until first check
  StreamSubscription<String?>? _packageSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appsProvider); // warm up app list
      _checkDefaultLauncher();
    });
    // Invalidate app list immediately when any package is installed/removed,
    // rather than waiting for the next resume (which can race with PackageManager).
    // Also prune any uninstalled packages from the recent-apps list so they
    // don't occupy a slot in the search-recents strip.
    _packageSub = AppsService.packageChangeEvents.listen((event) {
      if (!mounted || event == null) return;

      final colon = event.indexOf(':');
      final action = colon > 0 ? event.substring(0, colon) : 'CHANGED';
      final pkg = colon > 0 ? event.substring(colon + 1) : event;

      if (action == 'REMOVED') {
        final prevApps = ref.read(appsProvider).valueOrNull ?? <AppInfo>[];
        String appName = pkg;
        for (final a in prevApps) {
          if (a.packageName == pkg) {
            appName = a.appName;
            break;
          }
        }

        ref.invalidate(appsProvider);
        ref.read(recentAppsProvider.notifier).prunePackage(pkg);
        ref.read(foldersProvider.notifier).removeFromAllFolders(pkg);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$appName uninstalled',
              style: GoogleFonts.sora(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ref.invalidate(appsProvider);
      }
    });
  }

  @override
  void dispose() {
    _packageSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check every time the user returns to the launcher
  /// (e.g. after dismissing the system default-app chooser).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reset the search overlay flag in case the overlay was open when the
      // app was backgrounded — prevents the clock staying invisible on return.
      ref.read(searchOverlayActiveProvider.notifier).state = false;
      _checkDefaultLauncher();
      // Refresh installed apps list so newly installed/uninstalled
      // apps appear immediately when the user returns to the launcher.
      ref.invalidate(appsProvider);
    }
  }

  Future<void> _checkDefaultLauncher() async {
    final isDefault = await LauncherService.isDefaultLauncher();
    if (mounted && isDefault != _isDefault) {
      setState(() => _isDefault = isDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenHeight = mq.size.height;

    return Stack(
      children: [
        // ── Radial accent glow from bottom third ────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: screenHeight * 0.45,
          child: _BottomGlow(),
        ),

        // ── Layout: pill top · spacer · grid + dock bottom third ────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status bar padding + settings gear (top-right)
            SizedBox(height: mq.padding.top + 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: _GhostIconButton(
                  icon: Icons.tune_rounded,
                  onTap: () => _openSettings(context),
                ),
              ),
            ),

            // ── Clock ────────────────────────────────────────────────────
            Consumer(
              builder: (context, ref, _) {
                final searchOpen = ref.watch(searchOverlayActiveProvider);
                return AnimatedOpacity(
                  opacity: searchOpen ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 20, top: 28),
                    child: _ClockWidget(),
                  ),
                );
              },
            ),

            // ── Negative space / wallpaper zone ─────────────────────────
            const Spacer(),

            // ── Unified dock (context row + action buttons) ───────────────
            const AppDock(),

            // ── "Set as default" banner (shown when not default) ─────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child:
                  _isDefault
                      ? SizedBox(
                        key: const ValueKey('empty'),
                        height: mq.padding.bottom + 4,
                      )
                      : _DefaultLauncherBanner(
                        key: const ValueKey('banner'),
                        onTap: LauncherService.requestDefaultLauncher,
                        bottomPadding: mq.padding.bottom,
                      ),
            ),
          ],
        ),
      ],
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }
}

/// Live clock — updates every second.
/// Time is large white Sora. Day + date are accent-coloured (settable).
/// Format follows use24HourClockProvider.
class _ClockWidget extends ConsumerStatefulWidget {
  const _ClockWidget();

  @override
  ConsumerState<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends ConsumerState<_ClockWidget> {
  late DateTime _now;
  Timer? _timer;

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _buildTimeString(bool use24h) {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Returns only the H:MM digits for 12-hour mode (no AM/PM).
  String _timeDigits12h() {
    final hour12 = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final h12 = hour12.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h12:$m';
  }

  String get _period => _now.hour < 12 ? 'AM' : 'PM';

  String get _dateString {
    final day = _days[_now.weekday - 1];
    final month = _months[_now.month - 1];
    return '$day, $month ${_now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final use24h = ref.watch(use24HourClockProvider);
    final fontKey = ref.watch(clockFontProvider);
    final accent = ref.watch(accentColorProvider);
    final digitColor = Colors.white.withValues(alpha: 0.82);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 24h: single plain Text.
        // 12h: RichText so AM/PM is noticeably smaller than the digits
        //      but still larger than the date line below.
        if (use24h)
          Text(
            _buildTimeString(use24h),
            style: _clockTimeStyle(
              fontKey,
              fontSize: 64,
              fontWeight: FontWeight.w700,
              color: digitColor,
              letterSpacing: -1.5,
              height: 1.0,
            ),
          )
        else
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _timeDigits12h(),
                  style: _clockTimeStyle(
                    fontKey,
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    color: digitColor,
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: ' $_period',
                  style: _clockTimeStyle(
                    fontKey,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          _dateString.toUpperCase(),
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.0,
            color: accent.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

/// Returns a TextStyle for the home-screen clock digits in [fontKey].
TextStyle _clockTimeStyle(
  String fontKey, {
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  double? letterSpacing,
  double? height,
}) {
  switch (fontKey) {
    case 'space_mono':
      return GoogleFonts.spaceMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    case 'rajdhani':
      return GoogleFonts.rajdhani(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    case 'nunito':
      return GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    case 'oxanium':
      return GoogleFonts.oxanium(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    default: // 'sora'
      return GoogleFonts.sora(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
  }
}

class _BottomGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, 1.4),
          radius: 1.0,
          colors: [accent.withValues(alpha: 0.07), Colors.transparent],
        ),
      ),
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Icon(icon, color: Colors.white24, size: 18),
      ),
    );
  }
}

/// Compact banner shown below the dock when the app is not the default home.
/// Tapping it opens the system default-launcher chooser.
class _DefaultLauncherBanner extends StatelessWidget {
  const _DefaultLauncherBanner({
    super.key,
    required this.onTap,
    required this.bottomPadding,
  });

  final VoidCallback onTap;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding + 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.home_rounded, color: accent, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Set as default launcher',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Tap to open system home-app chooser',
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      color: Colors.white30,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: accent.withValues(alpha: 0.6),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
