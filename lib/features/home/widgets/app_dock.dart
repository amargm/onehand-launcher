import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/folder_icons.dart';
import '../../../core/models/app_folder.dart';
import '../../../core/providers/context_settings_provider.dart';
import '../../../core/providers/folders_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/launcher_service.dart';
import '../../folder/folder_screen.dart';
import '../../search/search_overlay.dart';

/// Unified dock panel: context status row on top, action buttons below.
class AppDock extends ConsumerWidget {
  const AppDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders          = ref.watch(foldersProvider);
    final showFolderLabels = ref.watch(showFolderLabelsProvider);
    final showSearchLabel  = ref.watch(showSearchLabelProvider);
    final rightHanded      = ref.watch(rightHandedProvider);
    final accent           = Theme.of(context).colorScheme.primary;

    final searchBtn = _DockButton(
      label: 'Search',
      icon: Icons.search_rounded,
      color: Colors.white,
      filled: true,
      showLabel: showSearchLabel,
      onTap: () => _openSearch(context),
    );

    final folderBtns = folders
        .map((f) => _DockButton(
              label: f.name,
              icon: kFolderIcons[f.iconKey] ?? Icons.folder_rounded,
              color: accent.withValues(alpha: 0.85),
              filled: false,
              showLabel: showFolderLabels,
              onTap: () => _openFolder(context, f),
            ))
        .toList();

    final rowChildren = rightHanded
        ? [...folderBtns, searchBtn]
        : [searchBtn, ...folderBtns];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ContextMiniRow(),
            const SizedBox(height: 10),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: rowChildren,
            ),
          ],
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

class _ContextMiniRow extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ContextMiniRow> createState() => _ContextMiniRowState();
}

class _ContextMiniRowState extends ConsumerState<_ContextMiniRow> {
  late Timer _timer;
  late DateTime _now;
  bool _headphones = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
        _poll();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final v = await LauncherService.isHeadphoneConnected();
    if (mounted && v != _headphones) setState(() => _headphones = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(contextItemsProvider);
    final accent  = Theme.of(context).colorScheme.primary;

    final items = ContextItemType.values
        .where((t) => enabled.contains(t))
        .map((t) => _iconFor(t, accent))
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items,
    );
  }

  Widget _iconFor(ContextItemType type, Color accent) {
    final h = _now.hour;
    final (IconData icon, bool active) = switch (type) {
      ContextItemType.time => h >= 9 && h < 18
          ? (Icons.bolt_rounded, true)
          : h >= 18 && h < 23
              ? (Icons.nightlight_rounded, true)
              : (Icons.bedtime_outlined, false),
      ContextItemType.headphone => _headphones
          ? (Icons.headphones_rounded, true)
          : (Icons.headphones_outlined, false),
      ContextItemType.day  => (Icons.calendar_today_outlined, true),
      ContextItemType.date => (Icons.event_outlined, true),
    };

    final color = active ? accent.withValues(alpha: 0.85) : Colors.white24;
    return Container(
      width: 40,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 15),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.showLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? Colors.white : color.withValues(alpha: 0.12),
              border: filled
                  ? null
                  : Border.all(
                      color: color.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
            ),
            child: Icon(
              icon,
              color: filled ? Colors.black : color,
              size: 22,
            ),
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
