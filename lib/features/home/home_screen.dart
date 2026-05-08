import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/apps_provider.dart';
import '../settings/settings_screen.dart';
import 'widgets/app_dock.dart';
import 'widgets/app_grid.dart';
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

class _HomeBodyState extends ConsumerState<_HomeBody> {
  @override
  void initState() {
    super.initState();
    // Trigger app list load on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appsProvider);
    });
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

            // ── Fixed 4×2 app grid — bottom third ───────────────────────
            const AppGrid(),

            const SizedBox(height: 16),

            // ── Concentric dock ──────────────────────────────────────────
            const AppDock(),

            SizedBox(height: mq.padding.bottom + 4),
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
