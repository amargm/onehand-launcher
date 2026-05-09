import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/folder_icons.dart';
import '../../core/models/app_folder.dart';
import '../../core/models/app_info.dart';
import '../../core/models/schedule_rule.dart';
import '../../core/models/special_date_event.dart';
import '../../core/providers/apps_provider.dart';
import '../../core/providers/context_apps_provider.dart';
import '../../core/providers/folders_provider.dart';
import '../../core/providers/schedule_rules_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/special_date_provider.dart';
import '../../core/services/apps_service.dart';
import '../../core/theme/app_theme.dart';
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
            label: 'Dock & Folders',
            subtitle: 'Labels, handedness, app folders',
            onTap:
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const _DockScreen())),
          ),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.sensors_rounded,
            label: 'Context & Shell',
            subtitle: 'Headphone apps · Schedule rules',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _ContextScreen()),
                ),
          ),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.celebration_outlined,
            label: 'Special Dates',
            subtitle: 'Birthdays, anniversaries & reminders',
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _SpecialDatesScreen(),
                  ),
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
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.article_outlined,
            label: 'Note from Developer',
            subtitle: 'Release notes & updates',
            onTap: () => _showDeveloperNote(context),
          ),
          const SizedBox(height: 8),
          _NavTile(
            icon: Icons.favorite_outline_rounded,
            label: 'Share Feedback',
            subtitle: 'Help shape the next version',
            onTap: () => _showFeedbackDialog(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialogs opened from the main settings screen
// ─────────────────────────────────────────────────────────────────────────────

void _showDeveloperNote(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.70),
    builder:
        (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      color: Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'NOTE FROM DEVELOPER',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white38,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'v1.0.0  ·  Obsidian Pulse',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome to the first release of One-Handed Launcher.\n\n'
                  'This is the foundation — a minimal, ergonomic launcher built around the Obsidian Pulse aesthetic. '
                  'Everything you see has been crafted to keep your most-used apps within one thumb\'s reach.\n\n'
                  'Future notes about new features, improvements, and fixes will appear right here.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: Colors.white54,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Got it',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: Colors.white60,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

void _showFeedbackDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.70),
    builder:
        (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_outline_rounded,
                      color: Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SHARE FEEDBACK',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white38,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Your ideas shape this app.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'One-Handed Launcher is under active development and every piece of feedback directly influences what gets built next. '
                  'Have a feature idea? Found something that could feel better? '
                  'We genuinely want to hear it — no suggestion is too small.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: Colors.white54,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    AppsService.openUrl(
                      'mailto:feedback@onehandlauncher.app'
                      '?subject=Feedback%20%E2%80%94%20One-Handed%20Launcher'
                      '&body=Hi%2C%0A%0AApp%20version%3A%20v1.0.0%0A%0A',
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          color: Colors.white60,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Send Email Feedback',
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            color: Colors.white70,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        'Maybe later',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: Colors.white30,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
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
    final folders = ref.watch(foldersProvider);
    return _SubScreen(
      title: 'Dock & Folders',
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
        const SizedBox(height: 24),
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

// ── Context & Shell sub-screen ───────────────────────────────────────────────
class _ContextScreen extends ConsumerWidget {
  const _ContextScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SubScreen(
      title: 'Context & Shell',
      children: [
        _SectionHeader('Headphone apps'),
        _ContextShellAppsSection(),
        const SizedBox(height: 24),
        _SectionHeader('Schedules'),
        _ScheduleRulesSection(),
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
        // ── App identity ──────────────────────────────────────────────────
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          label: 'One-Handed Launcher',
          subtitle: 'v1.0.0  ·  Obsidian Pulse',
        ),
        const SizedBox(height: 8),

        // ── Legal & policies (Play Store requirements) ────────────────────
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          subtitle: 'How we handle your data',
          trailing: const Icon(
            Icons.open_in_new_rounded,
            color: Colors.white24,
            size: 16,
          ),
          onTap:
              () => AppsService.openUrl('https://onehandlauncher.app/privacy'),
        ),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.gavel_outlined,
          label: 'Terms of Service',
          subtitle: 'Usage terms and conditions',
          trailing: const Icon(
            Icons.open_in_new_rounded,
            color: Colors.white24,
            size: 16,
          ),
          onTap: () => AppsService.openUrl('https://onehandlauncher.app/terms'),
        ),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.balance_outlined,
          label: 'Open-Source Licenses',
          subtitle: 'Third-party libraries used in this app',
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white24,
            size: 20,
          ),
          onTap:
              () => showLicensePage(
                context: context,
                applicationName: 'One-Handed Launcher',
                applicationVersion: 'v1.0.0',
                applicationLegalese: '© 2025 One-Handed Launcher',
              ),
        ),
        const SizedBox(height: 8),

        // ── Contact ───────────────────────────────────────────────────────
        _SettingsTile(
          icon: Icons.mail_outline_rounded,
          label: 'Contact & Support',
          subtitle: 'support@onehandlauncher.app',
          trailing: const Icon(
            Icons.open_in_new_rounded,
            color: Colors.white24,
            size: 16,
          ),
          onTap:
              () => AppsService.openUrl(
                'mailto:support@onehandlauncher.app'
                '?subject=Support%20%E2%80%94%20One-Handed%20Launcher',
              ),
        ),
        const SizedBox(height: 8),

        // ── Data collection disclosure ────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'This app does not collect, store, or transmit any personal data. '
                  'All settings are stored locally on your device.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: Colors.white38,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Schedule rules
// ─────────────────────────────────────────────────────────────────────────────

// ── Rules list (shown in Context & Shell screen) ──────────────────────────────

class _ScheduleRulesSection extends ConsumerWidget {
  const _ScheduleRulesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(scheduleRulesProvider);
    final appsAsync = ref.watch(appsProvider);
    final accent = Theme.of(context).colorScheme.primary;

    final pkgMap = {
      for (final a in appsAsync.valueOrNull ?? <AppInfo>[]) a.packageName: a,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Description ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Show specific apps in the context shell on chosen days and times. '
            'Multiple rules can be active at once — higher rules fill slots first.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              color: Colors.white38,
              height: 1.5,
            ),
          ),
        ),

        // ── Existing rules ────────────────────────────────────────────────
        for (final rule in rules) ...[
          _RuleCard(rule: rule, pkgMap: pkgMap, accent: accent),
          const SizedBox(height: 8),
        ],

        // ── Empty state ───────────────────────────────────────────────────
        if (rules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'No schedules yet. Add one below.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                color: Colors.white24,
              ),
            ),
          ),

        const SizedBox(height: 4),

        // ── Add button ────────────────────────────────────────────────────
        GestureDetector(
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => _ScheduleEditScreen(
                        rule: ScheduleRule.blank(),
                        isNew: true,
                      ),
                ),
              ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'New schedule',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: accent,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Single rule card ──────────────────────────────────────────────────────────

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.pkgMap,
    required this.accent,
  });

  final ScheduleRule rule;
  final Map<String, AppInfo> pkgMap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final apps =
        rule.apps.map((p) => pkgMap[p]).whereType<AppInfo>().take(3).toList();
    final extra = rule.apps.length > 3 ? rule.apps.length - 3 : 0;

    return GestureDetector(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _ScheduleEditScreen(rule: rule, isNew: false),
            ),
          ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            // ── Rule info ────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.name.isEmpty ? 'Untitled' : rule.name,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        rule.daysLabel,
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          color: accent.withValues(alpha: 0.80),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white24,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        rule.timeLabel,
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          color: Colors.white38,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  if (apps.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final app in apps) ...[
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2A2A2A),
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
                                        size: 14,
                                        color: Colors.white38,
                                      ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (extra > 0)
                          Text(
                            '+$extra',
                            style: GoogleFonts.sora(
                              fontSize: 10,
                              color: Colors.white24,
                            ),
                          ),
                      ],
                    ),
                  ],
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

// ── Create / edit screen ──────────────────────────────────────────────────────

class _ScheduleEditScreen extends ConsumerStatefulWidget {
  const _ScheduleEditScreen({required this.rule, required this.isNew});

  final ScheduleRule rule;
  final bool isNew;

  @override
  ConsumerState<_ScheduleEditScreen> createState() =>
      _ScheduleEditScreenState();
}

class _ScheduleEditScreenState extends ConsumerState<_ScheduleEditScreen> {
  late final TextEditingController _nameCtrl;
  late Set<int> _days;
  late int _startMinutes;
  late int _endMinutes;
  late List<String> _apps;
  bool _allDay = false;

  static const _dayDefs = [
    (label: 'M', full: 'Monday', weekday: 1),
    (label: 'T', full: 'Tue', weekday: 2),
    (label: 'W', full: 'Wed', weekday: 3),
    (label: 'T', full: 'Thu', weekday: 4),
    (label: 'F', full: 'Fri', weekday: 5),
    (label: 'S', full: 'Sat', weekday: 6),
    (label: 'S', full: 'Sun', weekday: 7),
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _nameCtrl = TextEditingController(text: r.name);
    _days = Set.from(r.days);
    _startMinutes = r.startMinutes;
    _endMinutes = r.endMinutes;
    _apps = List.from(r.apps);
    _allDay = r.isAllDay;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Save ────────────────────────────────────────────────────────────────

  void _save() {
    final rule = widget.rule.copyWith(
      name:
          _nameCtrl.text.trim().isEmpty ? 'My schedule' : _nameCtrl.text.trim(),
      days: _days,
      startMinutes: _allDay ? 0 : _startMinutes,
      endMinutes: _allDay ? 1439 : _endMinutes,
      apps: _apps,
    );
    final notifier = ref.read(scheduleRulesProvider.notifier);
    if (widget.isNew) {
      notifier.add(rule);
    } else {
      notifier.update(rule);
    }
    Navigator.of(context).pop();
  }

  // ── Time helpers ─────────────────────────────────────────────────────────

  Future<void> _pickTime({required bool isStart}) async {
    final initial = TimeOfDay(
      hour: (isStart ? _startMinutes : _endMinutes) ~/ 60,
      minute: (isStart ? _startMinutes : _endMinutes) % 60,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(
                surface: const Color(0xFF1E1E1E),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    setState(() {
      if (isStart) {
        _startMinutes = minutes;
      } else {
        _endMinutes = minutes;
      }
    });
  }

  String _fmtMinutes(int m) => ScheduleRule.fmt(m);

  // ── App picker ────────────────────────────────────────────────────────────

  void _pickApp() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder:
            (_, __, ___) => SearchOverlay(
              pickMode: true,
              onAppPicked: (pkg) {
                if (!_apps.contains(pkg) && _apps.length < kScheduleMaxApps) {
                  setState(() => _apps = [..._apps, pkg]);
                }
              },
            ),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final appsAsync = ref.watch(appsProvider);
    final pkgMap = {
      for (final a in appsAsync.valueOrNull ?? <AppInfo>[]) a.packageName: a,
    };
    final allSelected = _days.length == 7;

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
          widget.isNew ? 'New schedule' : 'Edit schedule',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.4,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: GoogleFonts.sora(
                fontSize: 13,
                color: accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Name ─────────────────────────────────────────────────────────
          _EditSection(
            label: 'NAME',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _nameCtrl,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Work, Commute, Weekend',
                  hintStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    color: Colors.white24,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Active days ───────────────────────────────────────────────────
          _EditSection(
            label: 'ACTIVE DAYS',
            trailing: GestureDetector(
              onTap:
                  () => setState(
                    () => _days = allSelected ? {} : {1, 2, 3, 4, 5, 6, 7},
                  ),
              child: Text(
                allSelected || _days.isEmpty ? 'Every day ✓' : 'Every day',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  color: allSelected || _days.isEmpty ? accent : Colors.white30,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  _dayDefs.map((d) {
                    final sel = _days.contains(d.weekday);
                    return GestureDetector(
                      onTap:
                          () => setState(() {
                            final next = Set<int>.from(_days);
                            if (sel) {
                              next.remove(d.weekday);
                            } else {
                              next.add(d.weekday);
                            }
                            _days = next;
                          }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              sel
                                  ? accent.withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color:
                                sel
                                    ? accent.withValues(alpha: 0.70)
                                    : Colors.white.withValues(alpha: 0.10),
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            d.label,
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w400,
                              color: sel ? accent : Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ── Time window ───────────────────────────────────────────────────
          _EditSection(
            label: 'TIME WINDOW',
            trailing: GestureDetector(
              onTap: () => setState(() => _allDay = !_allDay),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      _allDay
                          ? accent.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _allDay
                            ? accent.withValues(alpha: 0.50)
                            : Colors.white12,
                  ),
                ),
                child: Text(
                  'All day',
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    color: _allDay ? accent : Colors.white30,
                    fontWeight: _allDay ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            child:
                _allDay
                    ? Text(
                      'Active the entire day whenever your chosen days match.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: Colors.white30,
                        height: 1.5,
                      ),
                    )
                    : Row(
                      children: [
                        Expanded(
                          child: _TimeTile(
                            label: 'From',
                            time: _fmtMinutes(_startMinutes),
                            accent: accent,
                            onTap: () => _pickTime(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeTile(
                            label: 'To',
                            time: _fmtMinutes(_endMinutes),
                            accent: accent,
                            onTap: () => _pickTime(isStart: false),
                          ),
                        ),
                      ],
                    ),
          ),

          const SizedBox(height: 24),

          // ── Apps ──────────────────────────────────────────────────────────
          _EditSection(
            label: 'APPS  ·  MAX $kScheduleMaxApps',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(kScheduleMaxApps, (i) {
                final pkg = i < _apps.length ? _apps[i] : null;
                final app = pkg != null ? pkgMap[pkg] : null;

                if (app != null) {
                  return GestureDetector(
                    onTap:
                        () => setState(
                          () => _apps = _apps.where((p) => p != pkg).toList(),
                        ),
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
                                        : const Icon(
                                          Icons.apps_rounded,
                                          color: Colors.white54,
                                          size: 24,
                                        ),
                              ),
                            ),
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
                  final canAdd = _apps.length < kScheduleMaxApps;
                  return GestureDetector(
                    onTap: canAdd ? _pickApp : null,
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
          ),

          // ── Delete (edit mode only) ───────────────────────────────────────
          if (!widget.isNew) ...[
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                ref.read(scheduleRulesProvider.notifier).remove(widget.rule.id);
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.withValues(alpha: 0.70),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete this schedule',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        color: Colors.red.withValues(alpha: 0.70),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}

// ── Edit screen helpers ───────────────────────────────────────────────────────

class _EditSection extends StatelessWidget {
  const _EditSection({required this.label, required this.child, this.trailing});

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 10,
                color: Colors.white30,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[const Spacer(), trailing!],
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.time,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String time;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 10,
                color: Colors.white30,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------------
// SPECIAL DATES
// -------------------------------------------------------------------------------

// -- Special Dates sub-screen --------------------------------------------------
class _SpecialDatesScreen extends ConsumerWidget {
  const _SpecialDatesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(specialDateEventsProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final snoozeMins = ref.watch(snoozeDurationProvider);

    return _SubScreen(
      title: 'Special Dates',
      children: [
        // -- Snooze duration setting -------------------------------------
        _SectionHeader('Default snooze duration'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Snooze · $snoozeMins min',
                style: GoogleFonts.sora(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                'How long to wait before re-showing a reminder',
                style: GoogleFonts.sora(fontSize: 10.5, color: Colors.white30),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mins in [15, 30, 60, 120])
                    GestureDetector(
                      onTap:
                          () => ref
                              .read(snoozeDurationProvider.notifier)
                              .set(mins),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color:
                              snoozeMins == mins
                                  ? accent.withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                snoozeMins == mins
                                    ? accent.withValues(alpha: 0.60)
                                    : Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Text(
                          mins < 60 ? '$mins min' : '${mins ~/ 60} hr',
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            color: snoozeMins == mins ? accent : Colors.white38,
                            fontWeight:
                                snoozeMins == mins
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  // Show an extra chip for any legacy value not in the preset list.
                  if (![15, 30, 60, 120].contains(snoozeMins))
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.60),
                        ),
                      ),
                      child: Text(
                        snoozeMins < 60
                            ? '$snoozeMins min'
                            : '${snoozeMins ~/ 60} hr',
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // -- Events list -------------------------------------------------
        _SectionHeader('Your dates'),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No special dates yet.\nTap + below to add your first.',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  color: Colors.white24,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (final event in events) ...[
            _SpecialDateCard(
              event: event,
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => _SpecialDateEditScreen(
                            event: event,
                            isNew: false,
                          ),
                    ),
                  ),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 16),

        // -- Add button --------------------------------------------------
        GestureDetector(
          onTap: () {
            final blank = SpecialDateEvent.blank().copyWith(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
            );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => _SpecialDateEditScreen(event: blank, isNew: true),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'New special date',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// -- Event card (list item) ----------------------------------------------------
class _SpecialDateCard extends StatelessWidget {
  const _SpecialDateCard({required this.event, required this.onTap});

  final SpecialDateEvent event;
  final VoidCallback onTap;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_months[event.month - 1]} ${event.day}${event.isRecurring ? ' · every year' : ''}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            // Date badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB830).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFFFFB830).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${event.day}',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFB830),
                      height: 1.0,
                    ),
                  ),
                  Text(
                    _months[event.month - 1].toUpperCase(),
                    style: GoogleFonts.sora(
                      fontSize: 7,
                      color: const Color(0xFFFFB830).withValues(alpha: 0.70),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name.isEmpty ? 'Unnamed' : event.name,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: GoogleFonts.sora(
                      fontSize: 10.5,
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

// -- Event edit screen ---------------------------------------------------------
class _SpecialDateEditScreen extends ConsumerStatefulWidget {
  const _SpecialDateEditScreen({required this.event, required this.isNew});

  final SpecialDateEvent event;
  final bool isNew;

  @override
  ConsumerState<_SpecialDateEditScreen> createState() =>
      _SpecialDateEditScreenState();
}

class _SpecialDateEditScreenState
    extends ConsumerState<_SpecialDateEditScreen> {
  late final TextEditingController _nameCtrl;
  late int _month;
  late int _day;
  late bool _recurring;
  late int _snoozeMins;
  late List<RichParagraph> _paragraphs;
  late String _iconKey;
  bool _previewMode = false;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _amber = Color(0xFFFFB830);

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.event.name);
    _month = widget.event.month;
    _day = widget.event.day;
    _recurring = widget.event.isRecurring;
    _snoozeMins = widget.event.snoozeMinutes;
    _iconKey = widget.event.iconKey;
    _paragraphs = List.from(widget.event.message);
    if (_paragraphs.isEmpty) _paragraphs.add(const RichParagraph(text: ''));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.event.copyWith(
      name: _nameCtrl.text.trim(),
      month: _month,
      day: _day,
      isRecurring: _recurring,
      message: _paragraphs,
      snoozeMinutes: _snoozeMins,
      iconKey: _iconKey,
    );
    if (widget.isNew) {
      ref.read(specialDateEventsProvider.notifier).add(updated);
    } else {
      ref.read(specialDateEventsProvider.notifier).update(updated);
    }
    Navigator.of(context).pop();
  }

  int get _daysInMonth {
    const d = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return d[_month - 1];
  }

  void _addParagraph() {
    setState(() => _paragraphs.add(const RichParagraph(text: '')));
  }

  void _updateParagraph(int i, RichParagraph p) {
    setState(() => _paragraphs[i] = p);
  }

  void _removeParagraph(int i) {
    if (_paragraphs.length <= 1) return;
    setState(() => _paragraphs.removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final globalSnooze = ref.watch(snoozeDurationProvider);
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
          widget.isNew ? 'New date' : 'Edit date',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: GoogleFonts.sora(
                fontSize: 13,
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // -- Name ------------------------------------------------------
          _EditSection(
            label: 'NAME',
            child: TextField(
              controller: _nameCtrl,
              style: GoogleFonts.sora(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Mom\'s Birthday',
                hintStyle: GoogleFonts.sora(
                  fontSize: 13,
                  color: Colors.white24,
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // -- Date picker -----------------------------------------------
          _EditSection(
            label: 'DATE',
            child: Row(
              children: [
                // Month
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDialog<int>(
                        context: context,
                        builder: (_) => _MonthPickerDialog(current: _month),
                      );
                      if (picked != null) {
                        setState(() {
                          _month = picked;
                          if (_day > _daysInMonth) _day = _daysInMonth;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _months[_month - 1],
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Day
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDialog<int>(
                        context: context,
                        builder:
                            (_) => _DayPickerDialog(
                              current: _day,
                              maxDay: _daysInMonth,
                            ),
                      );
                      if (picked != null) setState(() => _day = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_day',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // -- Recurring toggle ------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repeats every year',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        _recurring
                            ? 'Shown on this date each year'
                            : 'Shown once only',
                        style: GoogleFonts.sora(
                          fontSize: 10.5,
                          color: Colors.white30,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _recurring,
                  onChanged: (v) => setState(() => _recurring = v),
                  activeColor: accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // -- Icon picker -----------------------------------------------
          _EditSection(
            label: 'ICON',
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    kSpecialDateIcons.entries.map((entry) {
                      final selected = _iconKey == entry.key;
                      return GestureDetector(
                        onTap: () => setState(() => _iconKey = entry.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                selected
                                    ? _amber.withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color:
                                  selected
                                      ? _amber.withValues(alpha: 0.70)
                                      : Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            size: 20,
                            color: selected ? _amber : Colors.white38,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -- Per-event snooze override ---------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Snooze for this date',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        _snoozeMins == 0
                            ? 'Auto — global default ($globalSnooze min)'
                            : '$_snoozeMins min for this date only',
                        style: GoogleFonts.sora(
                          fontSize: 10.5,
                          color: Colors.white30,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    for (final mins in [0, 15, 30, 60])
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _snoozeMins = mins),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _snoozeMins == mins
                                      ? accent.withValues(alpha: 0.18)
                                      : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _snoozeMins == mins
                                        ? accent.withValues(alpha: 0.60)
                                        : Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Text(
                              mins == 0
                                  ? 'Auto'
                                  : mins < 60
                                  ? '${mins}m'
                                  : '${mins ~/ 60}h',
                              style: GoogleFonts.sora(
                                fontSize: 10,
                                color:
                                    _snoozeMins == mins
                                        ? accent
                                        : Colors.white38,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // -- Message editor --------------------------------------------
          _EditSection(
            label: 'MESSAGE',
            trailing: GestureDetector(
              onTap: () => setState(() => _previewMode = !_previewMode),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      _previewMode
                          ? _amber.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _previewMode
                            ? _amber.withValues(alpha: 0.50)
                            : Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  _previewMode ? 'Edit' : 'Preview',
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    color: _previewMode ? _amber : Colors.white38,
                  ),
                ),
              ),
            ),
            child:
                _previewMode
                    ? _MessagePreview(paragraphs: _paragraphs)
                    : _MessageEditor(
                      paragraphs: _paragraphs,
                      accent: accent,
                      onUpdate: _updateParagraph,
                      onRemove: _removeParagraph,
                      onAdd: _addParagraph,
                    ),
          ),
          const SizedBox(height: 32),

          // -- Delete ----------------------------------------------------
          if (!widget.isNew) ...[
            GestureDetector(
              onTap: () {
                ref
                    .read(specialDateEventsProvider.notifier)
                    .remove(widget.event.id);
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.withValues(alpha: 0.70),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete this date',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        color: Colors.red.withValues(alpha: 0.70),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
}

// -- Message editor ------------------------------------------------------------
class _MessageEditor extends StatelessWidget {
  const _MessageEditor({
    required this.paragraphs,
    required this.accent,
    required this.onUpdate,
    required this.onRemove,
    required this.onAdd,
  });

  final List<RichParagraph> paragraphs;
  final Color accent;
  final void Function(int, RichParagraph) onUpdate;
  final void Function(int) onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < paragraphs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ParagraphEditor(
              index: i,
              paragraph: paragraphs[i],
              accent: accent,
              onUpdate: (p) => onUpdate(i, p),
              onRemove: paragraphs.length > 1 ? () => onRemove(i) : null,
            ),
          ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 15, color: Colors.white24),
                const SizedBox(width: 6),
                Text(
                  'Add paragraph',
                  style: GoogleFonts.sora(fontSize: 11, color: Colors.white24),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -- Single paragraph editor row -----------------------------------------------
class _ParagraphEditor extends StatefulWidget {
  const _ParagraphEditor({
    required this.index,
    required this.paragraph,
    required this.accent,
    required this.onUpdate,
    this.onRemove,
  });

  final int index;
  final RichParagraph paragraph;
  final Color accent;
  final ValueChanged<RichParagraph> onUpdate;
  final VoidCallback? onRemove;

  @override
  State<_ParagraphEditor> createState() => _ParagraphEditorState();
}

class _ParagraphEditorState extends State<_ParagraphEditor> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.paragraph.text);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _emit({
    String? text,
    bool? bold,
    bool? italic,
    TextAlign? align,
    bool? isBullet,
  }) {
    widget.onUpdate(
      widget.paragraph.copyWith(
        text: text ?? _ctrl.text,
        bold: bold,
        italic: italic,
        align: align,
        isBullet: isBullet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.paragraph;
    final accent = widget.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formatting toolbar
          Row(
            children: [
              _FmtBtn(
                label: 'B',
                active: p.bold,
                accent: accent,
                bold: true,
                onTap: () => _emit(bold: !p.bold),
              ),
              const SizedBox(width: 6),
              _FmtBtn(
                label: 'I',
                active: p.italic,
                accent: accent,
                italic: true,
                onTap: () => _emit(italic: !p.italic),
              ),
              const SizedBox(width: 6),
              _FmtBtn(
                label: '�',
                active: p.isBullet,
                accent: accent,
                onTap: () => _emit(isBullet: !p.isBullet),
              ),
              const SizedBox(width: 10),
              // Alignment buttons
              for (final align in [
                TextAlign.left,
                TextAlign.center,
                TextAlign.right,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _emit(align: align),
                    child: Icon(
                      align == TextAlign.left
                          ? Icons.format_align_left_rounded
                          : align == TextAlign.center
                          ? Icons.format_align_center_rounded
                          : Icons.format_align_right_rounded,
                      size: 16,
                      color: p.align == align ? accent : Colors.white30,
                    ),
                  ),
                ),
              const Spacer(),
              if (widget.onRemove != null)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: Colors.white24,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Text field
          TextField(
            controller: _ctrl,
            style: GoogleFonts.sora(
              fontSize: 13,
              color: Colors.white,
              fontWeight: p.bold ? FontWeight.w700 : FontWeight.w400,
              fontStyle: p.italic ? FontStyle.italic : FontStyle.normal,
            ),
            textAlign: p.align,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Write something...',
              hintStyle: GoogleFonts.sora(fontSize: 12, color: Colors.white12),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (t) => _emit(text: t),
          ),
        ],
      ),
    );
  }
}

// -- Format button -------------------------------------------------------------
class _FmtBtn extends StatelessWidget {
  const _FmtBtn({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
    this.bold = false,
    this.italic = false,
  });

  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  final bool bold;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 24,
        decoration: BoxDecoration(
          color:
              active
                  ? accent.withValues(alpha: 0.20)
                  : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                active
                    ? accent.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? accent : Colors.white38,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// -- Message preview -----------------------------------------------------------
class _MessagePreview extends StatelessWidget {
  const _MessagePreview({required this.paragraphs});

  final List<RichParagraph> paragraphs;

  static const _amber = Color(0xFFFFB830);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration_rounded, color: _amber, size: 13),
              const SizedBox(width: 6),
              Text(
                'Preview',
                style: GoogleFonts.sora(
                  fontSize: 10,
                  color: _amber,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final p in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                p.isBullet ? '•  ${p.text}' : p.text,
                textAlign: p.align,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: p.bold ? FontWeight.w700 : FontWeight.w400,
                  fontStyle: p.italic ? FontStyle.italic : FontStyle.normal,
                  height: 1.55,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// -- Month picker dialog -------------------------------------------------------
class _MonthPickerDialog extends StatelessWidget {
  const _MonthPickerDialog({required this.current});

  final int current;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select month',
              style: GoogleFonts.sora(
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (i) {
                final selected = (i + 1) == current;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(i + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? accent.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            selected
                                ? accent.withValues(alpha: 0.60)
                                : Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Text(
                      _months[i].substring(0, 3),
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: selected ? accent : Colors.white54,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// -- Day picker dialog ---------------------------------------------------------
class _DayPickerDialog extends StatelessWidget {
  const _DayPickerDialog({required this.current, required this.maxDay});

  final int current;
  final int maxDay;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select day',
              style: GoogleFonts.sora(
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: maxDay,
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final selected = day == current;
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            selected
                                ? accent.withValues(alpha: 0.22)
                                : Colors.transparent,
                        border: Border.all(
                          color:
                              selected
                                  ? accent.withValues(alpha: 0.55)
                                  : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            color: selected ? accent : Colors.white54,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
