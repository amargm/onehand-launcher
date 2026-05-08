import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/apps_provider.dart';
import '../../core/services/launcher_service.dart';
import '../settings/settings_screen.dart';
import 'widgets/app_dock.dart';
import 'widgets/context_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Intercept back press — a launcher should never exit
    return PopScope(
      canPop: false,
      child: Scaffold(backgroundColor: Colors.black, body: _HomeBody()),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appsProvider); // warm up app list
      _checkDefaultLauncher();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check every time the user returns to the launcher
  /// (e.g. after dismissing the system default-app chooser).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDefaultLauncher();
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
            // Status bar padding + top spacing
            SizedBox(height: mq.padding.top + 14),

            // ── "Context Active" pill — top of screen ───────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(child: ContextSection()),
                  const SizedBox(width: 10),
                  _GhostIconButton(
                    icon: Icons.tune_rounded,
                    onTap: () => _openSettings(context),
                  ),
                ],
              ),
            ),

            // ── Negative space / wallpaper zone ─────────────────────────
            const Spacer(),

            // ── Concentric dock ──────────────────────────────────────────
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

/// Subtle accent radial glow from the bottom — Obsidian Pulse signature.
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
