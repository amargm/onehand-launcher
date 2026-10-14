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
const _kAppDrawerCustomGroupsKey = 'app_drawer_custom_groups';
final appDrawerCustomGroupsProvider = StateNotifierProvider<AppDrawerCustomGroupsNotifier, List<String>>(
  (ref) => AppDrawerCustomGroupsNotifier(ref.watch(sharedPreferencesProvider)),
);
class AppDrawerCustomGroupsNotifier extends StateNotifier<List<String>> {
  AppDrawerCustomGroupsNotifier(this._prefs) : super(_load(_prefs));
  final SharedPreferences _prefs;
  static List<String> _load(SharedPreferences prefs) =>
      (prefs.getStringList(_kAppDrawerCustomGroupsKey) ?? const <String>[])
          .map((name) => name.trim()).where((name) => name.isNotEmpty && !_drawerGroups.contains(name)).toSet().toList();
  void addGroup(String name) {
    final value = name.trim();
    if (value.isEmpty || _drawerGroups.any((g) => g.toLowerCase() == value.toLowerCase()) || state.any((g) => g.toLowerCase() == value.toLowerCase())) return;
    state = [...state, value]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _prefs.setStringList(_kAppDrawerCustomGroupsKey, state);
  }
}

final appDrawerGroupOverridesProvider = StateNotifierProvider<
    AppDrawerGroupOverridesNotifier, Map<String, String>>(
  (ref) => AppDrawerGroupOverridesNotifier(ref.watch(sharedPreferencesProvider)),
);

const _kAppDrawerCollapsedGroupsKey = 'app_drawer_collapsed_groups';

final appDrawerCollapsedGroupsProvider =
    StateNotifierProvider<AppDrawerCollapsedGroupsNotifier, Set<String>>(
  (ref) => AppDrawerCollapsedGroupsNotifier(ref.watch(sharedPreferencesProvider)),
);

class AppDrawerCollapsedGroupsNotifier extends StateNotifier<Set<String>> {
  AppDrawerCollapsedGroupsNotifier(this._prefs)
      : super((_prefs.getStringList(_kAppDrawerCollapsedGroupsKey) ??
                const <String>[])
            .toSet());

  final SharedPreferences _prefs;

  void toggle(String group) {
    final next = {...state};
    if (!next.add(group)) next.remove(group);
    state = next;
    _persist();
  }

  void collapseAll(Iterable<String> groups) {
    state = {...state, ...groups};
    _persist();
  }

  void expandAll() {
    state = <String>{};
    _persist();
  }

  void _persist() {
    _prefs.setStringList(_kAppDrawerCollapsedGroupsKey, state.toList());
  }
}

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

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        'Create custom group',
        style: GoogleFonts.sora(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 28,
        textCapitalization: TextCapitalization.words,
        style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(hintText: 'Group name'),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class AppDrawerScreen extends ConsumerStatefulWidget {
  const AppDrawerScreen({super.key});

  @override
  ConsumerState<AppDrawerScreen> createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends ConsumerState<AppDrawerScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'App drawer search');
  String _query = '';
  bool _searchShrunk = false;
  bool _searchOpen = false;
  List<AppInfo>? _indexedApps;
  Map<String, String> _appSearchIndex = <String, String>{};
  Map<String, String> _automaticGroupIndex = <String, String>{};

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _automaticGroupIndexKey(AppInfo app) =>
      '${app.packageName}::${app.appName.toLowerCase()}';

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

  Future<String?> _createGroupName() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const _CreateGroupDialog(),
    );
    if (result == null || result.trim().isEmpty || !mounted) return null;
    final name = result.trim();
    final existing = [..._drawerGroups, ...ref.read(appDrawerCustomGroupsProvider)];
    if (existing.any((g) => g.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A group with that name already exists.')),
      );
      return null;
    }
    ref.read(appDrawerCustomGroupsProvider.notifier).addGroup(name);
    return name;
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
              ListTile(
                dense: true,
                leading: Icon(Icons.create_new_folder_rounded, color: Theme.of(context).colorScheme.primary),
                title: Text('Create custom group…', style: GoogleFonts.sora(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(sheetContext, '__create_group__'),
              ),
              for (final group in [..._drawerGroups, ...ref.read(appDrawerCustomGroupsProvider)])
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
    var destination = selected;
    if (selected == '__create_group__') {
      final created = await _createGroupName();
      if (created == null || !mounted) return;
      destination = created;
    }
    final notifier = ref.read(appDrawerGroupOverridesProvider.notifier);
    if (destination == '__automatic__') {
      notifier.resetToAutomatic(app.packageName);
    } else {
      notifier.setGroup(app.packageName, destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final appsAsync = ref.watch(appsProvider);
    final overrides = ref.watch(appDrawerGroupOverridesProvider);
    final customGroups = ref.watch(appDrawerCustomGroupsProvider);
    final groups = [..._drawerGroups, ...customGroups];
    final collapsedGroups = ref.watch(appDrawerCollapsedGroupsProvider);
    final allGroupsCollapsed = groups.isNotEmpty &&
        groups.every(collapsedGroups.contains);
    final favorites = ref.watch(favoriteAppsProvider);
    final iconSize = ref.watch(drawerIconSizeProvider);
    final gridColumns = ref.watch(drawerGridColumnsProvider);
    final showLabels = ref.watch(showDrawerLabelsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
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
                  IconButton(
                    tooltip: allGroupsCollapsed ? 'Expand all groups' : 'Collapse all groups',
                    onPressed: () {
                      final notifier = ref.read(appDrawerCollapsedGroupsProvider.notifier);
                      if (allGroupsCollapsed) {
                        notifier.expandAll();
                      } else {
                        notifier.collapseAll(groups);
                      }
                    },
                    icon: Icon(
                      allGroupsCollapsed
                          ? Icons.unfold_more_rounded
                          : Icons.unfold_less_rounded,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification || notification is UserScrollNotification) {
                    final next = notification.metrics.pixels > 24;
                    if (next != _searchShrunk && mounted) setState(() => _searchShrunk = next);
                  }
                  return false;
                },
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
                  // Build searchable text once per installed-app snapshot so
                  // scroll/animation rebuilds don't lowercase every app again.
                  if (!identical(_indexedApps, allApps)) {
                    _indexedApps = allApps;
                    _appSearchIndex = {
                      for (final app in allApps)
                        app.packageName:
                            '${app.appName.toLowerCase()} ${app.packageName.toLowerCase()}',
                    };
                    _automaticGroupIndex = {
                      for (final app in allApps)
                        _automaticGroupIndexKey(app): _automaticGroup(app),
                    };
                  }
                  final filtered = _query.isEmpty
                      ? allApps
                      : allApps
                          .where((app) =>
                              _appSearchIndex[app.packageName]!.contains(_query))
                          .toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(_query.isEmpty ? 'No launchable apps found' : 'No apps match “$_query”', style: GoogleFonts.sora(color: Colors.white38, fontSize: 12)),
                    );
                  }

                  final grouped = <String, List<AppInfo>>{
                    for (final group in groups) group: <AppInfo>[],
                  };
                  for (final app in filtered) {
                    final override = overrides[app.packageName];
                    final group = override != null && groups.contains(override)
                        ? override
                        : (_automaticGroupIndex[_automaticGroupIndexKey(app)] ??
                            _automaticGroup(app));
                    grouped.putIfAbsent(group, () => <AppInfo>[]).add(app);
                  }
                  // allApps is alphabetically ordered by the native app-list
                  // query; filtering preserves that order, so grouped lists do
                  // not need to be sorted again on every search keystroke.

                  // Package lookup avoids scanning all filtered apps for every
                  // favorite (O(A × F) -> O(A + F)).
                  final appByPackage = {
                    for (final app in filtered) app.packageName: app,
                  };
                  final filteredPackages = appByPackage.keys.toSet();
                  final visibleFavorites = favorites
                      .where(filteredPackages.contains)
                      .toList();

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
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
                                final app = appByPackage[packageName]!;
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
                      for (final group in groups)
                        if (grouped[group]?.isNotEmpty ?? false)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                            sliver: SliverToBoxAdapter(
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.075)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Semantics(
                                      button: true,
                                      expanded: _query.isNotEmpty || !collapsedGroups.contains(group),
                                      label: '$group group, ${grouped[group]!.length} apps',
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(14),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: () {
                                            // Search results temporarily show matching apps
                                            // in expanded groups without changing saved state.
                                            if (_query.isNotEmpty) return;
                                            ref.read(appDrawerCollapsedGroupsProvider.notifier).toggle(group);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 3),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: AnimatedDefaultTextStyle(
                                                    duration: const Duration(milliseconds: 460),
                                                    curve: Curves.easeInOutQuart,
                                                    style: GoogleFonts.sora(
                                                      color: Colors.white70,
                                                      fontSize: (_query.isEmpty && collapsedGroups.contains(group)) ? 15.5 : 11,
                                                      letterSpacing: (_query.isEmpty && collapsedGroups.contains(group)) ? 0.4 : 1.0,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                    child: Text(
                                                      group.toUpperCase(),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                                Text('${grouped[group]!.length}', style: GoogleFonts.sora(color: accent, fontSize: 10, fontWeight: FontWeight.w600)),
                                                const SizedBox(width: 8),
                                                AnimatedRotation(
                                                  turns: (_query.isEmpty && collapsedGroups.contains(group)) ? -0.25 : 0,
                                                  duration: const Duration(milliseconds: 400),
                                                  curve: Curves.easeInOutQuart,
                                                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 460),
                                      curve: Curves.easeInOutQuart,
                                      alignment: Alignment.topCenter,
                                      child: _query.isNotEmpty || !collapsedGroups.contains(group)
                                          ? TweenAnimationBuilder<double>(
                                              tween: Tween<double>(begin: 0, end: 1),
                                              duration: const Duration(milliseconds: 520),
                                              curve: Curves.easeOutCubic,
                                              builder: (context, progress, child) => Opacity(
                                                opacity: progress,
                                                child: Transform.translate(
                                                  offset: Offset(0, 10 * (1 - progress)),
                                                  child: child,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.only(top: 12),
                                                child: GridView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: grouped[group]!.length,
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: gridColumns,
                                                  mainAxisExtent: iconSize + (showLabels ? 36 : 12),
                                                  crossAxisSpacing: 7,
                                                  mainAxisSpacing: 8,
                                                ),
                                                itemBuilder: (context, index) {
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
                                              ),
                                              ),
                                            )
                                          : const SizedBox(width: double.infinity)

                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  );
                },
              ),
              ),
            ),
          ],
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 14,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedScale(
                  scale: _searchOpen || !_searchShrunk ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeInOutCubic,
                    width: _searchOpen ? MediaQuery.sizeOf(context).width - 36 : 56,
                    height: _searchOpen ? 62 : 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(_searchOpen ? 22 : 28),
                      border: _searchOpen
                          ? Border.all(color: accent.withValues(alpha: 0.22))
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: _searchOpen ? 18 : 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Don't mount the editable field until the animated
                        // pill is wide enough to give it real layout space.
                        // This prevents a transient RenderFlex/pixel overflow
                        // on the first frames after the search button is tapped.
                        final showInput =
                            _searchOpen && constraints.maxWidth >= 140;
                        return Row(
                          mainAxisAlignment: showInput
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                        if (showInput)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 18, right: 4),
                              child: AnimatedOpacity(
                                opacity: 1,
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  autofocus: false,
                                  onChanged: (value) => setState(
                                    () => _query = value.trim().toLowerCase(),
                                  ),
                                  style: GoogleFonts.sora(color: Colors.white, fontSize: 13),
                                  cursorColor: accent,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: 'Search apps',
                                    hintStyle: GoogleFonts.sora(color: Colors.white38, fontSize: 12),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (showInput) const SizedBox(width: 4),
                        Material(
                          color: accent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              if (_searchOpen) {
                                _searchFocusNode.unfocus();
                                _searchController.clear();
                                setState(() {
                                  _query = '';
                                  _searchOpen = false;
                                });
                              } else {
                                setState(() => _searchOpen = true);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted && _searchOpen) {
                                    _searchFocusNode.requestFocus();
                                  }
                                });
                              }
                            },
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
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
