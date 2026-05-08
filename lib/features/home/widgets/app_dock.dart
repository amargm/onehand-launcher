import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/folder_icons.dart';
import '../../../core/models/app_folder.dart';
import '../../../core/providers/folders_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../folder/folder_screen.dart';
import '../../search/search_overlay.dart';

/// The bottom dock — folder buttons and a search button.
/// Labels and icons are configurable via Settings.
class AppDock extends ConsumerWidget {
  const AppDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    final showFolderLabels = ref.watch(showFolderLabelsProvider);
    final showSearchLabel = ref.watch(showSearchLabelProvider);
    final rightHanded = ref.watch(rightHandedProvider);
    final accent = Theme.of(context).colorScheme.primary;

    final searchBtn = _DockButton(
      label: 'Search',
      icon: Icons.search_rounded,
      color: Colors.white54,
      showLabel: showSearchLabel,
      onTap: () => _openSearch(context),
    );

    final folderWidgets = <Widget>[];
    for (int i = 0; i < folders.length; i++) {
      folderWidgets.add(
        _DockButton(
          label: folders[i].name,
          icon: kFolderIcons[folders[i].iconKey] ?? Icons.folder_rounded,
          color: accent.withValues(alpha: 0.85),
          showLabel: showFolderLabels,
          onTap: () => _openFolder(context, folders[i]),
        ),
      );
      if (i < folders.length - 1) folderWidgets.add(const SizedBox(width: 18));
    }

    // Right-handed: folders … search  |  Left-handed: search … folders
    final rowChildren =
        rightHanded
            ? [...folderWidgets, const SizedBox(width: 18), searchBtn]
            : [searchBtn, const SizedBox(width: 18), ...folderWidgets];

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: rowChildren),
          ),
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
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _openSearch(BuildContext context) {
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

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.showLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          if (showLabel) ...[
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 9,
                color: Colors.white54,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
