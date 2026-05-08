import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_folder.dart';
import 'settings_provider.dart';

const _kFoldersKey = 'app_folders';

/// Three dock folders — created with empty defaults on first launch.
final foldersProvider = StateNotifierProvider<FoldersNotifier, List<AppFolder>>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return FoldersNotifier(prefs);
  },
);

class FoldersNotifier extends StateNotifier<List<AppFolder>> {
  FoldersNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static List<AppFolder> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kFoldersKey);
    if (raw == null) return _defaults();
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => AppFolder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _defaults();
    }
  }

  static List<AppFolder> _defaults() => [
    AppFolder(id: const Uuid().v4(), name: 'Work', packageNames: []),
    AppFolder(id: const Uuid().v4(), name: 'Social', packageNames: []),
    AppFolder(id: const Uuid().v4(), name: 'Media', packageNames: []),
  ];

  void _persist() {
    _prefs.setString(
      _kFoldersKey,
      jsonEncode(state.map((f) => f.toJson()).toList()),
    );
  }

  void renameFolder(String id, String newName) {
    state = [
      for (final f in state)
        if (f.id == id) f.copyWith(name: newName) else f,
    ];
    _persist();
  }

  void addApp(String folderId, String packageName) {
    state = [
      for (final f in state)
        if (f.id == folderId && !f.packageNames.contains(packageName))
          f.copyWith(packageNames: [...f.packageNames, packageName])
        else
          f,
    ];
    _persist();
  }

  void removeApp(String folderId, String packageName) {
    state = [
      for (final f in state)
        if (f.id == folderId)
          f.copyWith(
            packageNames:
                f.packageNames.where((p) => p != packageName).toList(),
          )
        else
          f,
    ];
    _persist();
  }
}
