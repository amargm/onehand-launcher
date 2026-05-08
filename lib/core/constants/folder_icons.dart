import 'package:flutter/material.dart';

/// Curated abstract icon set for dock folders.
/// The key is stored in [AppFolder.iconKey] and persisted to SharedPreferences.
const Map<String, IconData> kFolderIcons = {
  'folder': Icons.folder_rounded,
  'work': Icons.work_outline_rounded,
  'social': Icons.people_outline_rounded,
  'media': Icons.play_circle_outline_rounded,
  'game': Icons.sports_esports_outlined,
  'photo': Icons.photo_camera_outlined,
  'music': Icons.music_note_outlined,
  'travel': Icons.flight_outlined,
  'health': Icons.favorite_border_rounded,
  'finance': Icons.account_balance_wallet_outlined,
  'education': Icons.school_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'news': Icons.article_outlined,
  'tools': Icons.build_outlined,
  'food': Icons.restaurant_outlined,
};
