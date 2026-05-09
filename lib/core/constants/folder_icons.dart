import 'package:flutter/material.dart';

/// Curated abstract icon set for dock folders.
/// The key is stored in [AppFolder.iconKey] and persisted to SharedPreferences.
const Map<String, IconData> kFolderIcons = {
  // ── General ───────────────────────────────────────────────────────────────
  'folder': Icons.folder_rounded,
  'star': Icons.star_border_rounded,
  'home': Icons.home_outlined,

  // ── Work & Productivity ───────────────────────────────────────────────────
  'work': Icons.work_outline_rounded,
  'calendar': Icons.calendar_today_outlined,
  'mail': Icons.mail_outline_rounded,
  'code': Icons.code_rounded,
  'cloud': Icons.cloud_outlined,
  'security': Icons.security_outlined,

  // ── Social & Communication ────────────────────────────────────────────────
  'social': Icons.people_outline_rounded,
  'chat': Icons.chat_bubble_outline_rounded,

  // ── Media & Entertainment ─────────────────────────────────────────────────
  'media': Icons.play_circle_outline_rounded,
  'movie': Icons.movie_outlined,
  'music': Icons.music_note_outlined,
  'game': Icons.sports_esports_outlined,
  'photo': Icons.photo_camera_outlined,

  // ── Lifestyle ─────────────────────────────────────────────────────────────
  'health': Icons.favorite_border_rounded,
  'fitness': Icons.fitness_center_outlined,
  'food': Icons.restaurant_outlined,
  'travel': Icons.flight_outlined,
  'car': Icons.directions_car_outlined,
  'map': Icons.map_outlined,

  // ── Finance & Shopping ────────────────────────────────────────────────────
  'finance': Icons.account_balance_wallet_outlined,
  'shopping': Icons.shopping_bag_outlined,

  // ── Knowledge ─────────────────────────────────────────────────────────────
  'education': Icons.school_outlined,
  'book': Icons.menu_book_rounded,
  'news': Icons.article_outlined,

  // ── Tools & Utilities ─────────────────────────────────────────────────────
  'tools': Icons.build_outlined,
  'art': Icons.palette_outlined,
};
