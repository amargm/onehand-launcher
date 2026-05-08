import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/apps_provider.dart';
import '../../../core/providers/pinned_apps_provider.dart';
import '../../search/search_overlay.dart';
import 'circular_app_icon.dart';

/// Fixed 4×2 grid of pinned circular app icons in the bottom third.
/// Empty slots show a "+" tap target that opens search to pick an app.
class AppGrid extends ConsumerWidget {
  const AppGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedSlots = ref.watch(pinnedAppsProvider);
    final appsAsync = ref.watch(appsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: appsAsync.when(
        loading:
            () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
            ),
        error: (_, __) => const SizedBox(height: 180),
        data: (allApps) {
          final appMap = {for (final a in allApps) a.packageName: a};
          return GridView.builder(
            // Fixed 4×2 — no scrolling
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 20,
              crossAxisSpacing: 4,
              childAspectRatio: 0.75,
            ),
            itemCount: kHomeGridSlots,
            itemBuilder: (context, i) {
              final pkg = pinnedSlots[i];
              final app = pkg != null ? appMap[pkg] : null;

              if (app != null) {
                return CircularAppIcon(
                  app: app,
                  size: 54,
                  onTap: () => CircularAppIcon.launch(app.packageName),
                  onLongPress: () => _showSlotMenu(context, ref, i, pkg!),
                );
              }
              // Empty slot — tap to pin an app
              return _EmptySlot(
                onTap: () => _openSearchToPick(context, ref, i),
              );
            },
          );
        },
      ),
    );
  }

  void _showSlotMenu(
    BuildContext context,
    WidgetRef ref,
    int index,
    String pkg,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.highlight_remove_rounded,
                    color: Colors.white38,
                  ),
                  title: Text(
                    'Remove from home',
                    style: GoogleFonts.sora(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    ref.read(pinnedAppsProvider.notifier).unpin(pkg);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white38,
                  ),
                  title: Text(
                    'Replace with another app',
                    style: GoogleFonts.sora(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openSearchToPick(context, ref, index, replace: pkg);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _openSearchToPick(
    BuildContext context,
    WidgetRef ref,
    int slotIndex, {
    String? replace,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder:
            (_, __, ___) => SearchOverlay(
              pickMode: true,
              onAppPicked: (pkg) {
                if (replace != null) {
                  ref.read(pinnedAppsProvider.notifier).unpin(replace);
                }
                ref
                    .read(pinnedAppsProvider.notifier)
                    .pin(pkg, index: slotIndex);
              },
            ),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10, width: 1.5),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white12,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
