import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/app_folder.dart';
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
    return _SettingsTile(
      icon: Icons.folder_rounded,
      label: folder.name,
      subtitle: '${folder.packageNames.length} apps',
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 18),
        onPressed: () => _renameFolder(context, ref),
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
