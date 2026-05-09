/// Curated dark wallpapers from Unsplash's public CDN.
/// All images are free to use under the Unsplash license.
/// URL format: w=width&q=quality&fm=jpg — no API key required.
library;

class WallpaperEntry {
  const WallpaperEntry({
    required this.id,
    required this.displayId,
    required this.url,
    required this.thumbUrl,
    required this.credit,
    required this.category,
  });

  final String id;

  /// Sequential number within its category, starting from 1.
  final int displayId;
  final String url;
  final String thumbUrl;
  final String credit;
  final WallpaperCategory category;
}

enum WallpaperCategory { nebula, abstract, grid, city }

extension WallpaperCategoryLabel on WallpaperCategory {
  String get label {
    switch (this) {
      case WallpaperCategory.nebula:
        return 'Nebula';
      case WallpaperCategory.abstract:
        return 'Abstract';
      case WallpaperCategory.grid:
        return 'Dark';
      case WallpaperCategory.city:
        return 'City';
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
    displayId: 1,
    url:
        'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=400&q=70&fm=jpg&fit=crop',
    credit: 'NASA / Unsplash',
    category: WallpaperCategory.nebula,
  ),
  WallpaperEntry(
    id: 'n2',
    displayId: 2,
    url:
        'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.nebula,
  ),
  // Milky Way arch over mountain ridge — iconic dark sky shot (Joel Filipe)
  WallpaperEntry(
    id: 'n3',
    displayId: 3,
    url:
        'https://images.unsplash.com/photo-1444703686981-a3abbc4d4fe3?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1444703686981-a3abbc4d4fe3?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Joel Filipe / Unsplash',
    category: WallpaperCategory.nebula,
  ),
  // Lone figure under a violet starfield (Greg Rakozy)
  WallpaperEntry(
    id: 'n4',
    displayId: 4,
    url:
        'https://images.unsplash.com/photo-1475274047050-1d0c0975c63e?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1475274047050-1d0c0975c63e?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Greg Rakozy / Unsplash',
    category: WallpaperCategory.nebula,
  ),
  // Starry mountain silhouette, deep blue tones
  WallpaperEntry(
    id: 'n5',
    displayId: 5,
    url:
        'https://images.unsplash.com/photo-1502134249126-9f3755a50d78?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1502134249126-9f3755a50d78?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.nebula,
  ),
  // Deep space galaxy cluster, near-black with vivid colour pockets
  WallpaperEntry(
    id: 'n6',
    displayId: 6,
    url:
        'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?w=400&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.nebula,
  ),
  // Earth rising from lunar surface — NASA blue marble
  WallpaperEntry(
    id: 'n7',
    displayId: 7,
    url:
        'https://images.unsplash.com/photo-1454789548928-9efd52dc4031?w=1440&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1454789548928-9efd52dc4031?w=400&q=70&fm=jpg&fit=crop',
    credit: 'NASA / Unsplash',
    category: WallpaperCategory.nebula,
  ),

  // ── Abstract / Minimal ─────────────────────────────────────────────────
  // Dark fluid, ink, and minimal wallpapers that frame well in portrait.
  WallpaperEntry(
    id: 'a1',
    displayId: 1,
    url:
        'https://images.unsplash.com/photo-1604871000636-074fa5117945?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1604871000636-074fa5117945?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  WallpaperEntry(
    id: 'a2',
    displayId: 2,
    url:
        'https://images.unsplash.com/photo-1557682224-5b8590cd9ec5?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1557682224-5b8590cd9ec5?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  WallpaperEntry(
    id: 'a3',
    displayId: 3,
    url:
        'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  // Vivid liquid-colour gradient on near-black — very popular abstract
  WallpaperEntry(
    id: 'a4',
    displayId: 4,
    url:
        'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  // Dark ink diffusion in water — organic, deep black base
  WallpaperEntry(
    id: 'a5',
    displayId: 5,
    url:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  // Dark moody geometric / low-poly abstract
  WallpaperEntry(
    id: 'a6',
    displayId: 6,
    url:
        'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),
  // Dark crimson / maroon smoke swirl — dramatic portrait
  WallpaperEntry(
    id: 'a7',
    displayId: 7,
    url:
        'https://images.unsplash.com/photo-1617791160505-6f00504f3519?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1617791160505-6f00504f3519?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.abstract,
  ),

  // ── Dark / Solid Black — near-black solid & texture, high-downloads ────
  // Pure and near-black solid-tone backgrounds — favourite for AMOLED screens.
  WallpaperEntry(
    id: 'g1',
    displayId: 1,
    url:
        'https://images.unsplash.com/photo-1488330890490-c291ecf62571?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1488330890490-c291ecf62571?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.grid,
  ),
  WallpaperEntry(
    id: 'g2',
    displayId: 2,
    url:
        'https://images.unsplash.com/photo-1517999144091-3d9dca6d1e43?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1517999144091-3d9dca6d1e43?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.grid,
  ),
  // Dark textured concrete / stone — matte AMOLED look
  WallpaperEntry(
    id: 'g3',
    displayId: 3,
    url:
        'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.grid,
  ),
  // Charcoal dark minimal — near-pure black with subtle grain
  WallpaperEntry(
    id: 'g4',
    displayId: 4,
    url:
        'https://images.unsplash.com/photo-1553095066-5014bc7b7f2d?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1553095066-5014bc7b7f2d?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.grid,
  ),
  // True-black foggy forest at night — ultra-dark, atmospheric
  WallpaperEntry(
    id: 'g5',
    displayId: 5,
    url:
        'https://images.unsplash.com/photo-1511497584788-876760111969?w=1080&h=1920&q=90&fm=jpg&fit=crop',
    thumbUrl:
        'https://images.unsplash.com/photo-1511497584788-876760111969?w=400&h=700&q=70&fm=jpg&fit=crop',
    credit: 'Unsplash',
    category: WallpaperCategory.grid,
  ),
  // Deep black ocean surface at night — mirror-calm and minimal
  WallpaperEntry(
    id: 'g6',
    displayId: 6,
    url:
        'https://images.pexels.com/photos/1933239/pexels-photo-1933239.jpeg?auto=compress&cs=tinysrgb&w=1080&h=1920&fit=crop',
    thumbUrl:
        'https://images.pexels.com/photos/1933239/pexels-photo-1933239.jpeg?auto=compress&cs=tinysrgb&w=400&h=700&fit=crop',
    credit: 'Pexels',
    category: WallpaperCategory.grid,
  ),

  // ── City / Urban Night ─────────────────────────────────────────────────
  // Dark cityscapes, neon streets and night architecture — portrait-optimised.
  // Served from Pexels CDN (free under the Pexels License).
  WallpaperEntry(
    id: 'c1',
    displayId: 1,
    url:
        'https://images.pexels.com/photos/325185/pexels-photo-325185.jpeg?auto=compress&cs=tinysrgb&w=1080&h=1920&fit=crop',
    thumbUrl:
        'https://images.pexels.com/photos/325185/pexels-photo-325185.jpeg?auto=compress&cs=tinysrgb&w=400&h=700&fit=crop',
    credit: 'Pexels',
    category: WallpaperCategory.city,
  ),
  WallpaperEntry(
    id: 'c2',
    displayId: 2,
    url:
        'https://images.pexels.com/photos/1519088/pexels-photo-1519088.jpeg?auto=compress&cs=tinysrgb&w=1080&h=1920&fit=crop',
    thumbUrl:
        'https://images.pexels.com/photos/1519088/pexels-photo-1519088.jpeg?auto=compress&cs=tinysrgb&w=400&h=700&fit=crop',
    credit: 'Pexels',
    category: WallpaperCategory.city,
  ),
  WallpaperEntry(
    id: 'c3',
    displayId: 3,
    url:
        'https://images.pexels.com/photos/2043556/pexels-photo-2043556.jpeg?auto=compress&cs=tinysrgb&w=1080&h=1920&fit=crop',
    thumbUrl:
        'https://images.pexels.com/photos/2043556/pexels-photo-2043556.jpeg?auto=compress&cs=tinysrgb&w=400&h=700&fit=crop',
    credit: 'Pexels',
    category: WallpaperCategory.city,
  ),
  WallpaperEntry(
    id: 'c4',
    displayId: 4,
    url:
        'https://images.pexels.com/photos/1486222/pexels-photo-1486222.jpeg?auto=compress&cs=tinysrgb&w=1080&h=1920&fit=crop',
    thumbUrl:
        'https://images.pexels.com/photos/1486222/pexels-photo-1486222.jpeg?auto=compress&cs=tinysrgb&w=400&h=700&fit=crop',
    credit: 'Pexels',
    category: WallpaperCategory.city,
  ),
  WallpaperEntry(
    id: 'c5',
    displayId: 5,
    url:
        'https://images.pexels.com/photos/3617500/pexels-photo-3617500.jpeg?auto=compress&cs=tinysrgb&w=1080&h=1920&fit=crop',
    thumbUrl:
        'https://images.pexels.com/photos/3617500/pexels-photo-3617500.jpeg?auto=compress&cs=tinysrgb&w=400&h=700&fit=crop',
    credit: 'Pexels',
    category: WallpaperCategory.city,
  ),
  WallpaperEntry(
    id: 'c6',
    displayId: 6,
    url:
        'https://images.pexels.com/photos/2116721/pexels-photo-2116721.jpeg?auto=compress&cs=tinysrgb&w=1080&h=1920&fit=crop',
    thumbUrl:
        'https://images.pexels.com/photos/2116721/pexels-photo-2116721.jpeg?auto=compress&cs=tinysrgb&w=400&h=700&fit=crop',
    credit: 'Pexels',
    category: WallpaperCategory.city,
  ),
  WallpaperEntry(
    id: 'c7',
    displayId: 7,
    url:
        'https://images.pexels.com/photos/466685/pexels-photo-466685.jpeg?auto=compress&cs=tinysrgb&w=1080&h=1920&fit=crop',
    thumbUrl:
        'https://images.pexels.com/photos/466685/pexels-photo-466685.jpeg?auto=compress&cs=tinysrgb&w=400&h=700&fit=crop',
    credit: 'Pexels',
    category: WallpaperCategory.city,
  ),
];
