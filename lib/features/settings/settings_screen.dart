import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/folder_icons.dart';
import '../../core/models/app_folder.dart';
import '../../core/providers/context_settings_provider.dart';
import '../../core/providers/folders_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../lock_screen/lock_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final folders = ref.watch(foldersProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainer,
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
          // ── Appearance ─────────────────────────────────────────────────
          _SectionHeader('Appearance'),

          // Theme presets
          _ThemePresetRow(),

          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.palette_outlined,
            label: 'Custom accent colour',
            trailing: GestureDetector(
              onTap: () => _pickColor(context, ref, accent),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
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

          const SizedBox(height: 24),

          // ── Dock ────────────────────────────────────────────────────────
          _SectionHeader('Dock'),

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
            onChanged:
                (_) => ref.read(showSearchLabelProvider.notifier).toggle(),
          ),

          const SizedBox(height: 24),

          // ── Context indicators ──────────────────────────────────────────
          _SectionHeader('Context indicators'),

          _ContextItemsSection(),

          const SizedBox(height: 24),

          // ── Folders ─────────────────────────────────────────────────────
          _SectionHeader('Dock Folders'),

          for (final folder in folders) ...[
            _FolderTile(folder: folder),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 24),

          // ── About ────────────────────────────────────────────────────────
          _SectionHeader('About'),

          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'One-Handed Launcher',
            subtitle: 'v1.0.0  ·  Obsidian Pulse',
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _pickColor(BuildContext context, WidgetRef ref, Color current) {
    showDialog(
      context: context,
      builder: (ctx) {
        Color picked = current;
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
        color: const Color(0xFF141414),
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
                style: GoogleFonts.sora(fontSize: 13, color: Colors.white),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final folderIcon = kFolderIcons[folder.iconKey] ?? Icons.folder_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
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
                  style: GoogleFonts.sora(fontSize: 13, color: Colors.white),
                ),
                Text(
                  '${folder.packageNames.length} apps  ·  tap icon to change',
                  style: GoogleFonts.sora(fontSize: 10, color: Colors.white38),
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
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.sora(fontSize: 13, color: Colors.white),
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: accent),
        ],
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
          color: const Color(0xFF141414),
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
                    style: GoogleFonts.sora(fontSize: 13, color: Colors.white),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.sora(
                        fontSize: 11,
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
