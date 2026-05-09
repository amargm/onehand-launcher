import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/folder_icons.dart';
import '../../core/models/app_folder.dart';
import '../../core/models/app_info.dart';
import '../../core/providers/apps_provider.dart';
import '../../core/providers/context_apps_provider.dart';
import '../../core/providers/context_settings_provider.dart';
import '../../core/providers/folders_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../lock_screen/lock_screen.dart';
import '../search/search_overlay.dart';
import '../wallpaper/wallpaper_picker_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.4,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _NavTile(
            icon: Icons.palette_outlined,
            label: 'Appearance',
            subtitle: 'Accent colour, themes, clock format',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _AppearanceScreen()),
                ),
          ),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.grid_view_rounded,
            label: 'Dock',
            subtitle: 'Labels, handedness',
            onTap:
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const _DockScreen())),
          ),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.sensors_rounded,
            label: 'Context & Shell',
            subtitle: 'Context indicators, quick-launch strip',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _ContextScreen()),
                ),
          ),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.folder_outlined,
            label: 'Folders',
            subtitle: 'Manage dock app folders',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _FoldersScreen()),
                ),
          ),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.info_outline_rounded,
            label: 'About',
            subtitle: 'v1.0.0  ·  Obsidian Pulse',
            onTap:
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const _AboutScreen())),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Navigation tile ─────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-screen scaffold ───────────────────────────────────────────────
class _SubScreen extends StatelessWidget {
  const _SubScreen({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.4,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [...children, const SizedBox(height: 40)],
      ),
    );
  }
}

// ── Appearance sub-screen ────────────────────────────────────────────────────
class _AppearanceScreen extends ConsumerWidget {
  const _AppearanceScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    return _SubScreen(
      title: 'Appearance',
      children: [
        _SectionHeader('Theme'),
        _ThemePresetRow(),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.palette_outlined,
          label: 'Custom accent colour',
          trailing: GestureDetector(
            onTap: () => _pickAccentColor(context, ref, accent),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader('Clock'),
        _ToggleTile(
          icon: Icons.schedule_rounded,
          label: '24-hour clock',
          value: ref.watch(use24HourClockProvider),
          onChanged: (_) => ref.read(use24HourClockProvider.notifier).toggle(),
        ),
        const SizedBox(height: 24),
        _SectionHeader('Other'),
        _SettingsTile(
          icon: Icons.wallpaper_rounded,
          label: 'Wallpaper',
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white24,
            size: 20,
          ),
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WallpaperPickerScreen(),
                ),
              ),
        ),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.lock_outline_rounded,
          label: 'Preview lock screen',
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white24,
            size: 20,
          ),
          onTap:
              () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LockScreen())),
        ),
      ],
    );
  }
}

void _pickAccentColor(BuildContext context, WidgetRef ref, Color current) {
  showDialog(
    context: context,
    builder: (ctx) {
      Color picked = current;
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Accent colour',
          style: GoogleFonts.sora(color: Colors.white, fontSize: 15),
        ),
        content: HueRingPicker(
          pickerColor: current,
          onColorChanged: (c) => picked = c,
          enableAlpha: false,
          displayThumbColor: true,
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
              ref.read(accentColorProvider.notifier).setColor(picked);
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Apply',
              style: GoogleFonts.sora(color: picked, fontSize: 14),
            ),
          ),
        ],
      );
    },
  );
}

// ── Dock sub-screen ──────────────────────────────────────────────────────────
class _DockScreen extends ConsumerWidget {
  const _DockScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SubScreen(
      title: 'Dock',
      children: [
        _SectionHeader('Labels'),
        _ToggleTile(
          icon: Icons.label_outline_rounded,
          label: 'Show folder labels',
          value: ref.watch(showFolderLabelsProvider),
          onChanged:
              (_) => ref.read(showFolderLabelsProvider.notifier).toggle(),
        ),
        const SizedBox(height: 8),
        _ToggleTile(
          icon: Icons.search_rounded,
          label: 'Show "Search" label',
          value: ref.watch(showSearchLabelProvider),
          onChanged: (_) => ref.read(showSearchLabelProvider.notifier).toggle(),
        ),
        const SizedBox(height: 24),
        _SectionHeader('Layout'),
        _HandednessTile(),
      ],
    );
  }
}

// ── Context & Shell sub-screen ───────────────────────────────────────────────
class _ContextScreen extends ConsumerWidget {
  const _ContextScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SubScreen(
      title: 'Context & Shell',
      children: [
        _SectionHeader('Context indicators'),
        _ContextItemsSection(),
        const SizedBox(height: 24),
        _SectionHeader('Context shell apps'),
        _ContextShellAppsSection(),
      ],
    );
  }
}

// ── Folders sub-screen ───────────────────────────────────────────────────────
class _FoldersScreen extends ConsumerWidget {
  const _FoldersScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    return _SubScreen(
      title: 'Folders',
      children: [
        _SectionHeader('Dock folders'),
        for (final folder in folders) ...[
          _FolderTile(folder: folder),
          const SizedBox(height: 8),
        ],
        if (folders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No folders yet · create one via the + button',
                style: GoogleFonts.sora(fontSize: 12, color: Colors.white24),
              ),
            ),
          ),
      ],
    );
  }
}

// ── About sub-screen ─────────────────────────────────────────────────────────
class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    return _SubScreen(
      title: 'About',
      children: [
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          label: 'One-Handed Launcher',
          subtitle: 'v1.0.0  ·  Obsidian Pulse',
        ),
      ],
    );
  }
}

// ── Theme preset row ───────────────────────────────────────────────────────

class _ThemePresetRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(accentColorProvider);

    const presets = [
      (label: 'Amber', color: AppTheme.presetAmber),
      (label: 'Stealth', color: AppTheme.presetStealth),
      (label: 'Midnight', color: AppTheme.presetMidnight),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.style_outlined, color: Colors.white54, size: 20),
              const SizedBox(width: 14),
              Text(
                'Theme preset',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final preset in presets)
                _PresetSwatch(
                  label: preset.label,
                  color: preset.color,
                  isSelected: current == preset.color,
                  onTap:
                      () => ref
                          .read(accentColorProvider.notifier)
                          .setColor(preset.color),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetSwatch extends StatelessWidget {
  const _PresetSwatch({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  color == AppTheme.presetStealth
                      ? Colors.white.withValues(alpha: 0.12)
                      : color.withValues(alpha: 0.15),
              border: Border.all(
                color: isSelected ? color : Colors.white10,
                width: isSelected ? 2 : 1,
              ),
            ),
            child:
                isSelected
                    ? Icon(
                      Icons.check_rounded,
                      color:
                          color == AppTheme.presetStealth
                              ? Colors.white
                              : color,
                      size: 18,
                    )
                    : Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 9.5,
              color: isSelected ? color : Colors.white38,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Folder management tile ─────────────────────────────────────────────────

class _FolderTile extends ConsumerWidget {
  const _FolderTile({required this.folder});

  final AppFolder folder;

  static const int _kMaxFolderApps = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final folderIcon = kFolderIcons[folder.iconKey] ?? Icons.folder_rounded;
    final appsAsync = ref.watch(appsProvider);
    final pkgMap = {
      for (final a in appsAsync.valueOrNull ?? <AppInfo>[]) a.packageName: a,
    };

    final folderApps =
        folder.packageNames
            .take(_kMaxFolderApps)
            .map((pkg) => pkgMap[pkg])
            .whereType<AppInfo>()
            .toList();

    final canAdd = folder.packageNames.length < _kMaxFolderApps;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              // Tappable icon — opens icon picker
              GestureDetector(
                onTap: () => _pickIcon(context, ref),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.10),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(folderIcon, color: accent, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      folder.name,
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${folder.packageNames.length} / $_kMaxFolderApps apps  ·  tap icon to change',
                      style: GoogleFonts.sora(
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white38,
                  size: 18,
                ),
                onPressed: () => _renameFolder(context, ref),
              ),
            ],
          ),

          // ── Apps chips + Add button ──────────────────────────────────────
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final app in folderApps)
                _FolderAppChip(
                  app: app,
                  onRemove:
                      () => ref
                          .read(foldersProvider.notifier)
                          .removeApp(folder.id, app.packageName),
                ),
              if (canAdd)
                GestureDetector(
                  onTap: () => _addApp(context, ref),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                  ),
                ),
              if (folderApps.isEmpty && !canAdd)
                Text(
                  'No apps',
                  style: GoogleFonts.sora(fontSize: 11, color: Colors.white24),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _addApp(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder:
            (_, __, ___) => SearchOverlay(
              multiPickMode: true,
              onMultiPicked: (pkgs) {
                for (final pkg in pkgs) {
                  ref.read(foldersProvider.notifier).addApp(folder.id, pkg);
                }
              },
            ),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _pickIcon(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Choose icon',
              style: GoogleFonts.sora(color: Colors.white, fontSize: 15),
            ),
            content: SizedBox(
              width: 280,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: kFolderIcons.length,
                itemBuilder: (_, i) {
                  final entry = kFolderIcons.entries.elementAt(i);
                  final isSelected = entry.key == folder.iconKey;
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(foldersProvider.notifier)
                          .setFolderIcon(folder.id, entry.key);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isSelected
                                ? accent.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                          color:
                              isSelected
                                  ? accent.withValues(alpha: 0.5)
                                  : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        entry.value,
                        color: isSelected ? accent : Colors.white38,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.sora(color: Colors.white38),
                ),
              ),
            ],
          ),
    );
  }

  void _renameFolder(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Rename folder',
              style: GoogleFonts.sora(color: Colors.white, fontSize: 15),
            ),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.sora(color: Colors.white),
              cursorColor: Theme.of(context).colorScheme.primary,
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
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
                  final name = ctrl.text.trim();
                  if (name.isNotEmpty) {
                    ref
                        .read(foldersProvider.notifier)
                        .renameFolder(folder.id, name);
                  }
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  'Save',
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

// ── Folder app chip (36 px, removable) ────────────────────────────────────────
/// Small app icon with an × badge. Tap to remove from the folder.
class _FolderAppChip extends StatelessWidget {
  const _FolderAppChip({required this.app, required this.onRemove});

  final AppInfo app;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1E1E1E),
            ),
            child: ClipOval(
              child:
                  app.icon != null
                      ? Image.memory(
                        app.icon!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                      : const Icon(
                        Icons.apps_rounded,
                        size: 16,
                        color: Colors.white54,
                      ),
            ),
          ),
          // × remove badge
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D0D0D),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 9,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Context items section ──────────────────────────────────────────────────

class _ContextItemsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(contextItemsProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (final item in ContextItemType.values)
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                item.displayLabel,
                style: GoogleFonts.sora(fontSize: 13, color: Colors.white),
              ),
              activeColor: accent,
              value: enabled.contains(item),
              onChanged:
                  (_) => ref.read(contextItemsProvider.notifier).toggle(item),
            ),
        ],
      ),
    );
  }
}

// ── Toggle tile ────────────────────────────────────────────────────────────

class _ToggleTile extends ConsumerWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        // Surface 1 — card layer
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: accent),
        ],
      ),
    );
  }
}

// ── Handedness tile ────────────────────────────────────────────────────────

class _HandednessTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rightHanded = ref.watch(rightHandedProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.back_hand_outlined, color: Colors.white54, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Handedness',
              style: GoogleFonts.sora(fontSize: 13, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          // Segmented control
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HandBtn(
                  label: '← Left',
                  selected: !rightHanded,
                  accent: accent,
                  onTap:
                      () => ref.read(rightHandedProvider.notifier).set(false),
                ),
                _HandBtn(
                  label: 'Right →',
                  selected: rightHanded,
                  accent: accent,
                  onTap: () => ref.read(rightHandedProvider.notifier).set(true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HandBtn extends StatelessWidget {
  const _HandBtn({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                selected ? accent.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 12,
            color: selected ? accent : Colors.white38,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.sora(
          fontSize: 10,
          color: Colors.white24,
          letterSpacing: 2,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ── Context shell apps section ─────────────────────────────────────────────
/// Shows 4 configurable slots for the outer context shell.
/// Tap a filled slot to remove it; tap an empty slot to pick an app.
class _ContextShellAppsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configured = ref.watch(contextShellAppsProvider);
    final appsAsync = ref.watch(appsProvider);
    final accent = Theme.of(context).colorScheme.primary;

    final pkgMap = {
      for (final a in appsAsync.valueOrNull ?? <AppInfo>[]) a.packageName: a,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description row
          Row(
            children: [
              Icon(Icons.headphones_rounded, color: accent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Shown when headphones or Bluetooth connected · max 4',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4 slots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(kContextShellMaxApps, (i) {
              final pkg = i < configured.length ? configured[i] : null;
              final app = pkg != null ? pkgMap[pkg] : null;

              if (app != null) {
                // ── Filled slot: show icon + remove badge ─────────────────
                return GestureDetector(
                  onTap:
                      () => ref
                          .read(contextShellAppsProvider.notifier)
                          .remove(pkg!),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E1E1E),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.30),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child:
                                  app.icon != null
                                      ? Image.memory(
                                        app.icon!,
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                      )
                                      : Icon(
                                        Icons.apps_rounded,
                                        color: Colors.white54,
                                        size: 24,
                                      ),
                            ),
                          ),
                          // ×  remove badge
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0D0D0D),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white54,
                                size: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 52,
                        child: Text(
                          app.appName,
                          style: GoogleFonts.sora(
                            fontSize: 8.5,
                            color: Colors.white38,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // ── Empty slot: tap to pick ───────────────────────────────
                final canAdd = configured.length < kContextShellMaxApps;
                return GestureDetector(
                  onTap: canAdd ? () => _pickApp(context, ref) : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: canAdd ? Colors.white24 : Colors.white10,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: canAdd ? Colors.white38 : Colors.white12,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        canAdd ? 'Add' : '',
                        style: GoogleFonts.sora(
                          fontSize: 8.5,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  void _pickApp(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder:
            (_, __, ___) => SearchOverlay(
              pickMode: true,
              onAppPicked:
                  (pkg) => ref.read(contextShellAppsProvider.notifier).add(pkg),
            ),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}
