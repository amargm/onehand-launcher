/// Curated dark wallpapers from Unsplash's public CDN.
/// All images are free to use under the Unsplash license.
/// URL format: w=width&q=quality&fm=jpg — no API key required.
library;

class WallpaperEntry {
  const WallpaperEntry({
    required this.id,
    required this.url,
    required this.thumbUrl,
    required this.credit,
    required this.category,
  });

  final String id;
  final String url;
  final String thumbUrl;
  final String credit;
  final WallpaperCategory category;
}

enum WallpaperCategory { nebula, abstract, grid }

extension WallpaperCategoryLabel on WallpaperCategory {
  String get label {
    switch (this) {
      case WallpaperCategory.nebula:
        return 'Nebula';
      case WallpaperCategory.abstract:
        return 'Abstract';
      case WallpaperCategory.grid:
        return 'Dark';
    }
  }
}

// ── Wallpaper list ──────────────────────────────────────────────────────────
// Chosen for: true-black or near-black base, top-heavy composition so the
// bottom third (dock zone) is uncluttered, dark aesthetic.

const List<WallpaperEntry> kWallpapers = [
  // ── Nebula / Space ──────────────────────────────────────────────────────
  WallpaperEntry(
    id: 'n1',
    url:
        'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=400&q=70&fm=jpg&fit=crop',
    credit: 'NASA / Unsplash',
    category: WallpaperCategory.nebula,
  ),
  WallpaperEntry(
    id: 'n2',
    url:
        'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.nebula,
  ),
  WallpaperEntry(
    id: 'n3',
    url:
        'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Vincentiu Solomon / Unsplash',
    category: WallpaperCategory.nebula,
  ),
  WallpaperEntry(
    id: 'n4',
    url:
        'https://images.unsplash.com/photo-1543722530-d2c3201371e7?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1543722530-d2c3201371e7?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.nebula,
  ),
  WallpaperEntry(
    id: 'n5',
    url:
        'https://images.unsplash.com/photo-1520034475321-cbe63696469a?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1520034475321-cbe63696469a?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.nebula,
  ),
  WallpaperEntry(
    id: 'n6',
    url:
        'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.nebula,
  ),

  // ── Abstract / Minimal — portrait-oriented, high-downloads ────────────
  // Dark fluid, ink, and minimal wallpapers that frame well in portrait.
  WallpaperEntry(
    id: 'a1',
    url:
        'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  WallpaperEntry(
    id: 'a2',
    url:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  WallpaperEntry(
    id: 'a3',
    url:
        'https://images.unsplash.com/photo-1604871000636-074fa5117945?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1604871000636-074fa5117945?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  WallpaperEntry(
    id: 'a4',
    url:
        'https://images.unsplash.com/photo-1557682224-5b8590cd9ec5?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1557682224-5b8590cd9ec5?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  WallpaperEntry(
    id: 'a5',
    url:
        'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),

  // ── Dark / Solid Black — near-black solid & texture, high-downloads ────
  // Pure and near-black solid-tone backgrounds — favourite for AMOLED screens.
  WallpaperEntry(
    id: 'g1',
    url:
        'https://images.unsplash.com/photo-1547149617-609fafa00a6b?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1547149617-609fafa00a6b?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.grid,
  ),
  WallpaperEntry(
    id: 'g2',
    url:
        'https://images.unsplash.com/photo-1488330890490-c291ecf62571?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1488330890490-c291ecf62571?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.grid,
  ),
  WallpaperEntry(
    id: 'g3',
    url:
        'https://images.unsplash.com/photo-1517999144091-3d9dca6d1e43?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1517999144091-3d9dca6d1e43?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.grid,
  ),
  WallpaperEntry(
    id: 'g4',
    url:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.grid,
  ),
  WallpaperEntry(
    id: 'g5',
    url:
        'https://images.unsplash.com/photo-1567225557594-88d73e55f2cb?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1567225557594-88d73e55f2cb?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.grid,
  ),
];
