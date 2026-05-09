import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/apps_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/apps_service.dart';
import '../../core/services/launcher_service.dart';
import '../settings/settings_screen.dart';
import 'widgets/app_dock.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    // Intercept back press — a launcher should never exit
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(fit: StackFit.expand, children: [background, _HomeBody()]),
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
    _packageSub = AppsService.packageChangeEvents.listen((_) {
      if (mounted) ref.invalidate(appsProvider);
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
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 28),
              child: _ClockWidget(),
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
    final accent = ref.watch(accentColorProvider);
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
            style: GoogleFonts.sora(
              fontSize: 64,
              height: 1.0,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.5,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          )
        else
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _timeDigits12h(),
                  style: GoogleFonts.sora(
                    fontSize: 64,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                TextSpan(
                  text: ' $_period',
                  style: GoogleFonts.sora(
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
