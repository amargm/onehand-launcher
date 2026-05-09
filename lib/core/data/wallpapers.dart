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

enum WallpaperCategory { nebula, abstract, minimal }

extension WallpaperCategoryLabel on WallpaperCategory {
  String get label {
    switch (this) {
      case WallpaperCategory.nebula:
        return 'Nebula';
      case WallpaperCategory.abstract:
        return 'Abstract';
      case WallpaperCategory.minimal:
        return 'Minimal';
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

  // ── Abstract / Fluid ────────────────────────────────────────────────────
  WallpaperEntry(
    id: 'a1',
    url:
        'https://images.unsplash.com/photo-1541701494587-cb58502866ab?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1541701494587-cb58502866ab?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  WallpaperEntry(
    id: 'a2',
    url:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  WallpaperEntry(
    id: 'a3',
    url:
        'https://images.unsplash.com/photo-1550859492-d5da9d8e45f3?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1550859492-d5da9d8e45f3?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  WallpaperEntry(
    id: 'a4',
    url:
        'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  WallpaperEntry(
    id: 'a5',
    url:
        'https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),

  // ── Minimal / Dark Architecture ─────────────────────────────────────────
  WallpaperEntry(
    id: 'm1',
    url:
        'https://images.unsplash.com/photo-1516912481808-3406841bd33c?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1516912481808-3406841bd33c?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.minimal,
  ),
  WallpaperEntry(
    id: 'm2',
    url:
        'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.minimal,
  ),
  WallpaperEntry(
    id: 'm3',
    url:
        'https://images.unsplash.com/photo-1500964757637-c85e8a162429?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1500964757637-c85e8a162429?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.minimal,
  ),
  WallpaperEntry(
    id: 'm4',
    url:
        'https://images.unsplash.com/photo-1448375240586-882707db888b?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1448375240586-882707db888b?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.minimal,
  ),
  WallpaperEntry(
    id: 'm5',
    url:
        'https://images.unsplash.com/photo-1532274402911-5a369e4c4bb5?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1532274402911-5a369e4c4bb5?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.minimal,
  ),
];
