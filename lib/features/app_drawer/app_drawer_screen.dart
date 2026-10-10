import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/app_info.dart';
import '../../core/providers/apps_provider.dart';
import '../../core/providers/favorite_apps_provider.dart';
import '../../core/providers/recent_apps_provider.dart';
import '../home/widgets/circular_app_icon.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/apps_service.dart';

const _drawerGroups = <String>[
  'Communication',
  'Productivity',
  'Media',
  'Finance',
  'Shopping & Travel',
  'Games',
  'Tools',
  'Other apps',
];

const _kAppDrawerEnabled = 'app_drawer_enabled';

final appDrawerEnabledProvider =
    StateNotifierProvider<AppDrawerEnabledNotifier, bool>(
  (ref) => AppDrawerEnabledNotifier(ref.watch(sharedPreferencesProvider)),
);

class AppDrawerEnabledNotifier extends StateNotifier<bool> {
  AppDrawerEnabledNotifier(this._prefs)
      : super(_prefs.getBool(_kAppDrawerEnabled) ?? false);

  final SharedPreferences _prefs;

  void toggle() {
    state = !state;
    _prefs.setBool(_kAppDrawerEnabled, state);
  }
}

const _kAppDrawerGroupsKey = 'app_drawer_group_overrides';

final appDrawerGroupOverridesProvider = StateNotifierProvider<
    AppDrawerGroupOverridesNotifier, Map<String, String>>(
  (ref) => AppDrawerGroupOverridesNotifier(ref.watch(sharedPreferencesProvider)),
);

class AppDrawerGroupOverridesNotifier
    extends StateNotifier<Map<String, String>> {
  AppDrawerGroupOverridesNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Map<String, String> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kAppDrawerGroupsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  void setGroup(String packageName, String group) {
    state = {...state, packageName: group};
    _persist();
  }

  void resetToAutomatic(String packageName) {
    final next = {...state}..remove(packageName);
    state = next;
    _persist();
  }

  void _persist() {
    _prefs.setString(_kAppDrawerGroupsKey, jsonEncode(state));
  }
}

class AppDrawerScreen extends ConsumerStatefulWidget {
  const AppDrawerScreen({super.key});

  @override
  ConsumerState<AppDrawerScreen> createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends ConsumerState<AppDrawerScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _automaticGroup(AppInfo app) {
    final value = '${app.appName} ${app.packageName}'.toLowerCase();
    bool has(List<String> words) => words.any(value.contains);
    if (has(['whatsapp', 'telegram', 'signal', 'messag', 'phone', 'contact', 'discord', 'wechat', 'messenger', 'skype'])) return 'Communication';
    if (has(['gmail', 'mail', 'calendar', 'docs', 'sheets', 'slides', 'office', 'notion', 'task', 'todo', 'drive', 'teams', 'zoom', 'meet', 'slack', 'keep', 'writer'])) return 'Productivity';
    if (has(['youtube', 'spotify', 'music', 'netflix', 'prime video', 'video', 'camera', 'gallery', 'photo', 'podcast', 'mx player', 'vlc', 'twitch', 'soundcloud'])) return 'Media';
    if (has(['bank', 'finance', 'wallet', 'paytm', 'phonepe', 'gpay', 'google pay', 'paypal', 'money', 'invest', 'stocks', 'trading', 'upi'])) return 'Finance';
    if (has(['amazon', 'flipkart', 'shopping', 'store', 'uber', 'ola', 'maps', 'travel', 'booking', 'swiggy', 'zomato', 'food', 'airline', 'irctc'])) return 'Shopping & Travel';
    if (has(['game', 'gaming', 'clash', 'pubg', 'bgmi', 'free fire', 'roblox', 'minecraft', 'genshin', 'asphalt'])) return 'Games';
    if (has(['settings', 'calculator', 'clock', 'files', 'file manager', 'browser', 'chrome', 'firefox', 'vpn', 'scanner', 'weather', 'security', 'play store', 'launcher', 'recorder', 'translate', 'android'])) return 'Tools';
    return 'Other apps';
  }

  Future<void> _customizeGroup(AppInfo app, String currentGroup) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF17171B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Organize ${app.appName}', style: GoogleFonts.sora(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Choose where this app appears. Long-press again to change it.', style: GoogleFonts.sora(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                leading: const Icon(Icons.auto_awesome_rounded, color: Colors.white54),
                title: Text('Automatic · ${_automaticGroup(app)}', style: GoogleFonts.sora(color: Colors.white70, fontSize: 12)),
                onTap: () => Navigator.pop(sheetContext, '__automatic__'),
              ),
              for (final group in _drawerGroups)
                ListTile(
                  dense: true,
                  leading: Icon(
                    group == currentGroup ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                    color: group == currentGroup ? Theme.of(context).colorScheme.primary : Colors.white38,
                  ),
                  title: Text(group, style: GoogleFonts.sora(color: Colors.white70, fontSize: 12)),
                  onTap: () => Navigator.pop(sheetContext, group),
                ),
            ],
          ),
        ),
      ),
    ),
    );
    if (!mounted || selected == null) return;
    final notifier = ref.read(appDrawerGroupOverridesProvider.notifier);
    if (selected == '__automatic__') {
      notifier.resetToAutomatic(app.packageName);
    } else {
      notifier.setGroup(app.packageName, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final appsAsync = ref.watch(appsProvider);
    final overrides = ref.watch(appDrawerGroupOverridesProvider);
    final favorites = ref.watch(favoriteAppsProvider);
    final iconSize = ref.watch(drawerIconSizeProvider);
    final gridColumns = ref.watch(drawerGridColumnsProvider);
    final showLabels = ref.watch(showDrawerLabelsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 18, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back to home',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('APP LIBRARY', style: GoogleFonts.sora(color: accent, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text('All your apps, at a glance', style: GoogleFonts.sora(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.grid_view_rounded, size: 17),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                cursorColor: accent,
                decoration: InputDecoration(
                  hintText: 'Search apps',
                  hintStyle: GoogleFonts.sora(color: Colors.white38, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded, color: accent, size: 20),
                  suffixIcon: _query.isEmpty ? null : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF17171B),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accent.withValues(alpha: 0.7))),
                ),
              ),
            ),
            Expanded(
              child: appsAsync.when(
                loading: () => Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2)),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.apps_rounded, color: Colors.white38, size: 34),
                        const SizedBox(height: 12),
                        Text('Apps could not be loaded', style: GoogleFonts.sora(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 5),
                        Text('Return home and try opening the app library again.', textAlign: TextAlign.center, style: GoogleFonts.sora(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                data: (allApps) {
                  final filtered = allApps.where((app) {
                    if (_query.isEmpty) return true;
                    return app.appName.toLowerCase().contains(_query) || app.packageName.toLowerCase().contains(_query);
                  }).toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(_query.isEmpty ? 'No launchable apps found' : 'No apps match “$_query”', style: GoogleFonts.sora(color: Colors.white38, fontSize: 12)),
                    );
                  }

                  final grouped = <String, List<AppInfo>>{
                    for (final group in _drawerGroups) group: <AppInfo>[],
                  };
                  for (final app in filtered) {
                    final override = overrides[app.packageName];
                    final group = override != null && _drawerGroups.contains(override)
                        ? override
                        : _automaticGroup(app);
                    grouped[group]!.add(app);
                  }
                  for (final group in grouped.keys) {
                    grouped[group]!.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
                  }

                  final visibleFavorites = favorites
                      .where((packageName) => filtered.any((app) => app.packageName == packageName))
                      .toList();

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    scrollCacheExtent: 500,
                    slivers: [
                      if (visibleFavorites.isNotEmpty) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFC857), size: 16),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'FAVORITES',
                                    style: GoogleFonts.sora(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text('${visibleFavorites.length}', style: GoogleFonts.sora(color: Colors.white38, fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final packageName = visibleFavorites[index];
                                final app = filtered.firstWhere((a) => a.packageName == packageName);
                                return _DrawerAppTile(
                                  key: ValueKey('favorite-$packageName'),
                                  app: app,
                                  accent: accent,
                                  iconSize: iconSize,
                                  showLabel: showLabels,
                                  onTap: () async {
                                    await AppsService.openApp(app.packageName);
                                    if (context.mounted) ref.read(recentAppsProvider.notifier).recordLaunch(app.packageName);
                                  },
                                  onLongPress: () => showAppContextMenu(
                                    context,
                                    ref,
                                    app,
                                    onOrganize: () => _customizeGroup(app, overrides[app.packageName] ?? _automaticGroup(app)),
                                  ),
                                );
                              },
                              childCount: visibleFavorites.length,
                            ),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridColumns,
                              mainAxisExtent: iconSize + (showLabels ? 36 : 12),
                              crossAxisSpacing: 7,
                              mainAxisSpacing: 6,
                            ),
                          ),
                        ),
                      ],
                      for (final group in _drawerGroups)
                        if (grouped[group]!.isNotEmpty) ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                            sliver: SliverToBoxAdapter(
                              child: Row(
                                children: [
                                  Container(width: 3, height: 16, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4))),
                                  const SizedBox(width: 9),
                                  Expanded(child: Text(group.toUpperCase(), style: GoogleFonts.sora(color: Colors.white70, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700))),
                                  Text('${grouped[group]!.length}', style: GoogleFonts.sora(color: accent, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final app = grouped[group]![index];
                                  return _DrawerAppTile(
                                    key: ValueKey('group-$group-${app.packageName}'),
                                    app: app,
                                    accent: accent,
                                    iconSize: iconSize,
                                    showLabel: showLabels,
                                    onTap: () async {
                                      await AppsService.openApp(app.packageName);
                                      if (context.mounted) ref.read(recentAppsProvider.notifier).recordLaunch(app.packageName);
                                    },
                                    onLongPress: () => showAppContextMenu(context, ref, app, onOrganize: () => _customizeGroup(app, group)),
                                  );
                                },
                                childCount: grouped[group]!.length,
                              ),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridColumns,
                                mainAxisExtent: iconSize + (showLabels ? 36 : 12),
                                crossAxisSpacing: 7,
                                mainAxisSpacing: 6,
                              ),
                            ),
                          ),
                        ],
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
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

class _DrawerAppTile extends StatelessWidget {
  const _DrawerAppTile({
    super.key,
    required this.app,
    required this.accent,
    required this.iconSize,
    required this.showLabel,
    required this.onTap,
    required this.onLongPress,
  });

  final AppInfo app;
  final Color accent;
  final int iconSize;
  final bool showLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${app.appName}. Tap to open, long-press to organize',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: iconSize.toDouble(),
              height: iconSize.toDouble(),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF17171B),
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipOval(
                child: app.icon == null
                  ? Icon(Icons.android_rounded, color: accent, size: 25)
                  : Image.memory(
                      app.icon!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.android_rounded, color: accent, size: 25),
                    ),
              ),
            ),
            if (showLabel) ...[
              const SizedBox(height: 5),
              SizedBox(
                width: double.infinity,
                child: Text(
                  app.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(color: Colors.white70, fontSize: 9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
