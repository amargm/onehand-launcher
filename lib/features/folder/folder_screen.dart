import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/app_folder.dart';
import '../../core/models/app_info.dart';
import '../../core/providers/apps_provider.dart';
import '../../core/providers/folders_provider.dart';
import '../home/widgets/circular_app_icon.dart';

/// Displays apps inside a dock folder. Long-press an app to remove it.
class FolderScreen extends ConsumerWidget {
  const FolderScreen({super.key, required this.folder});

  final AppFolder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(appsProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.black87,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ── Folder title ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_rounded, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      folder.name,
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
                  style: GoogleFonts.sora(fontSize: 10, color: Colors.white24),
                ),

                const SizedBox(height: 24),

                // ── App grid ─────────────────────────────────────────────
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
                                (a) =>
                                    folder.packageNames.contains(a.packageName),
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
                                'Long-press any app on the home screen\nto add it here.',
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
                                () => _confirmRemove(context, ref, app),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, AppInfo app) {
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
              '${app.appName} will be removed from "${folder.name}".',
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
                      .removeApp(folder.id, app.packageName);
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
