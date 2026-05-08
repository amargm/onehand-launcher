import 'dart:typed_data';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/app_info.dart';
import '../../../core/providers/folders_provider.dart';

/// A single circular app icon with label beneath.
/// Long-press opens "Add to folder" context menu.
class CircularAppIcon extends ConsumerWidget {
  const CircularAppIcon({
    super.key,
    required this.app,
    this.size = 56,
    required this.onTap,
    this.onLongPress,
  });

  final AppInfo app;
  final double size;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress ?? () => _showFolderMenu(context, ref),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AppCircle(icon: app.icon, size: size),
          const SizedBox(height: 5),
          SizedBox(
            width: size + 8,
            child: Text(
              app.appName,
              style: GoogleFonts.sora(
                fontSize: 9.5,
                color: Colors.white70,
                letterSpacing: 0.2,
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

  void _showFolderMenu(BuildContext context, WidgetRef ref) {
    final folders = ref.read(foldersProvider);
    final accent = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _AppCircle(icon: app.icon, size: 40),
                    const SizedBox(width: 12),
                    Text(
                      app.appName,
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'ADD TO FOLDER',
                  style: GoogleFonts.sora(
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                for (final folder in folders)
                  ListTile(
                    leading: Icon(
                      Icons.folder_rounded,
                      color: accent,
                      size: 20,
                    ),
                    title: Text(
                      folder.name,
                      style: GoogleFonts.sora(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      ref
                          .read(foldersProvider.notifier)
                          .addApp(folder.id, app.packageName);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${app.appName} added to ${folder.name}',
                            style: GoogleFonts.sora(fontSize: 12),
                          ),
                          backgroundColor: const Color(0xFF1A1A1A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
    );
  }

  /// Launch an app by package name via device_apps.
  static Future<void> launch(String packageName) async {
    await DeviceApps.openApp(packageName);
  }
}

class _AppCircle extends StatelessWidget {
  const _AppCircle({required this.icon, required this.size});

  final List<int>? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1C1C1C),
      ),
      child: ClipOval(
        child:
            icon != null
                ? Image.memory(
                  icon!.asUint8List(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(context),
                )
                : _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) => Icon(
    Icons.android,
    color: Theme.of(context).colorScheme.primary,
    size: size * 0.55,
  );
}

extension on List<int> {
  Uint8List asUint8List() =>
      this is Uint8List ? this as Uint8List : Uint8List.fromList(this);
}
