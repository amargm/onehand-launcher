import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/folder_icons.dart';
import '../../core/models/app_folder.dart';
import '../../core/models/app_info.dart';
import '../../core/providers/apps_provider.dart';
import '../../core/providers/folders_provider.dart';
import '../home/widgets/circular_app_icon.dart';
import '../search/search_overlay.dart';

/// Displays apps inside a dock folder.
/// Tap "Add app" to add via search. Long-press an app to remove it.
class FolderScreen extends ConsumerWidget {
  const FolderScreen({super.key, required this.folder});

  final AppFolder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(appsProvider);
    // Watch live folder so UI refreshes when apps are added/removed
    final liveFolder = ref
        .watch(foldersProvider)
        .firstWhere((f) => f.id == folder.id, orElse: () => folder);
    final accent = Theme.of(context).colorScheme.primary;
    final folderIcon = kFolderIcons[liveFolder.iconKey] ?? Icons.folder_rounded;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Backdrop: tap anywhere to close ──────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.black87),
          ),

          // ── Content panel (absorbs taps so backdrop doesn't fire) ────
          SafeArea(
            child: GestureDetector(
              onTap: () {}, // absorb — prevents backdrop dismiss
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ── Folder title ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(folderIcon, color: accent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        liveFolder.name,
                        style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'tap to launch  ·  long-press to remove',
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      color: Colors.white24,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── App grid ─────────────────────────────────────────
                  Expanded(
                    child: appsAsync.when(
                      loading:
                          () => const Center(
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          ),
                      error:
                          (_, __) => Center(
                            child: Text(
                              'Error loading apps',
                              style: GoogleFonts.sora(color: Colors.white38),
                            ),
                          ),
                      data: (allApps) {
                        final folderApps =
                            allApps
                                .where(
                                  (a) => liveFolder.packageNames.contains(
                                    a.packageName,
                                  ),
                                )
                                .toList();

                        if (folderApps.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.white12,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Folder is empty',
                                  style: GoogleFonts.sora(
                                    color: Colors.white24,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap + below to add apps',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.sora(
                                    color: Colors.white12,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: folderApps.length,
                          itemBuilder: (ctx, i) {
                            final app = folderApps[i];
                            return CircularAppIcon(
                              app: app,
                              size: 52,
                              onTap: () {
                                Navigator.of(context).pop();
                                CircularAppIcon.launch(app.packageName);
                              },
                              onLongPress:
                                  () => _confirmRemove(
                                    context,
                                    ref,
                                    liveFolder,
                                    app,
                                  ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ── Add app — full-width primary button (Design spec) ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: GestureDetector(
                      onTap: () => _addApp(context, ref, liveFolder.id),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          // Primary button: #FF5722 bg, white text, full-width
                          color: const Color(0xFFFF5722),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5722).withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Add app',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.05 * 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addApp(BuildContext context, WidgetRef ref, String folderId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder:
            (_, __, ___) => SearchOverlay(
              pickMode: true,
              onAppPicked: (pkg) {
                // Add app — SearchOverlay handles its own dismissal via onDismiss
                ref.read(foldersProvider.notifier).addApp(folderId, pkg);
              },
            ),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    AppFolder liveFolder,
    AppInfo app,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Remove from folder?',
              style: GoogleFonts.sora(color: Colors.white, fontSize: 15),
            ),
            content: Text(
              '${app.appName} will be removed from "${liveFolder.name}".',
              style: GoogleFonts.sora(color: Colors.white54, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.sora(color: Colors.white38),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref
                      .read(foldersProvider.notifier)
                      .removeApp(liveFolder.id, app.packageName);
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  'Remove',
                  style: GoogleFonts.sora(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
