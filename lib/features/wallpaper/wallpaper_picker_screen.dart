import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/data/wallpapers.dart';
import '../../core/providers/settings_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WallpaperPickerScreen
//
// Three-category filter chip row + 3-column thumbnail grid.
// Tap a thumbnail → full-screen preview with "Set Wallpaper" button.
// Applies by downloading the image to app documents dir and updating
// wallpaperPathProvider — the home screen DecorationImage reads that path.
// ─────────────────────────────────────────────────────────────────────────────

class WallpaperPickerScreen extends StatefulWidget {
  const WallpaperPickerScreen({super.key});

  @override
  State<WallpaperPickerScreen> createState() => _WallpaperPickerScreenState();
}

class _WallpaperPickerScreenState extends State<WallpaperPickerScreen> {
  WallpaperCategory? _filter; // null = show all

  List<WallpaperEntry> get _visible =>
      _filter == null
          ? kWallpapers
          : kWallpapers.where((w) => w.category == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Wallpaper',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.4,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category filter chips ─────────────────────────────────────
          SizedBox(
            height: 28,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == null,
                  accent: accent,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                for (final cat in WallpaperCategory.values) ...[
                  _FilterChip(
                    label: cat.label,
                    selected: _filter == cat,
                    accent: accent,
                    onTap:
                        () => setState(
                          () => _filter = _filter == cat ? null : cat,
                        ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Thumbnail grid ─────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 9 / 16, // portrait phone ratio
              ),
              itemCount: _visible.length,
              itemBuilder: (ctx, i) {
                final entry = _visible[i];
                return _WallpaperThumb(
                  entry: entry,
                  accent: accent,
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _WallpaperPreviewScreen(entry: entry),
                        ),
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          color:
              selected
                  ? accent.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                selected
                    ? accent.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 11,
            color: selected ? accent : Colors.white54,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Thumbnail tile ────────────────────────────────────────────────────────────
class _WallpaperThumb extends StatelessWidget {
  const _WallpaperThumb({
    required this.entry,
    required this.accent,
    required this.onTap,
  });

  final WallpaperEntry entry;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail image
            CachedNetworkImage(
              imageUrl: entry.thumbUrl,
              fit: BoxFit.cover,
              placeholder:
                  (_, __) => Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
              errorWidget:
                  (_, __, ___) => Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white24,
                      size: 24,
                    ),
                  ),
            ),

            // Category badge bottom-left
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${entry.category.label} · ${entry.displayId}',
                  style: GoogleFonts.sora(
                    fontSize: 8,
                    color: Colors.white70,
                    letterSpacing: 0.5,
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

// ── Full-screen preview screen ────────────────────────────────────────────────
class _WallpaperPreviewScreen extends ConsumerStatefulWidget {
  const _WallpaperPreviewScreen({required this.entry});

  final WallpaperEntry entry;

  @override
  ConsumerState<_WallpaperPreviewScreen> createState() =>
      _WallpaperPreviewScreenState();
}

class _WallpaperPreviewScreenState
    extends ConsumerState<_WallpaperPreviewScreen> {
  _SetState _state = _SetState.idle;
  bool _imageError = false;

  /// Downloads the full-res image, saves it to the app documents directory,
  /// and updates wallpaperPathProvider so the home screen redraws immediately.
  Future<void> _apply() async {
    if (_state == _SetState.loading) return;
    setState(() => _state = _SetState.loading);
    try {
      final response = await http
          .get(Uri.parse(widget.entry.url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      // Persist to a fixed filename so old wallpapers are automatically
      // replaced and no orphan files accumulate.
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/wallpaper.jpg');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      // Evict the old decode from Flutter's image cache so Image.file
      // always loads fresh bytes on every wallpaper change.
      await FileImage(file).evict();

      // Update the provider — home screen will rebuild immediately.
      ref.read(wallpaperPathProvider.notifier).set(file.path);

      if (mounted) setState(() => _state = _SetState.done);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        // Pop preview, then pop picker — user lands back on home with wallpaper
        Navigator.of(context)
          ..pop() // preview
          ..pop(); // picker
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = _SetState.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not set wallpaper — check your connection.',
              style: GoogleFonts.sora(fontSize: 12),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // ── Full-screen image ─────────────────────────────────────────
          Positioned.fill(
            child: _imageError
                ? _ImageErrorRetry(
                    onRetry: () => setState(() => _imageError = false),
                  )
                : CachedNetworkImage(
                    imageUrl: widget.entry.url,
                    fit: BoxFit.cover,
                    placeholder:
                        (_, __) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white24,
                            strokeWidth: 1.5,
                          ),
                        ),
                    errorWidget:
                        (_, __, ___) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) {
                              if (mounted) setState(() => _imageError = true);
                            },
                          );
                          return const SizedBox.shrink();
                        },
                  ),
          ),

          // ── Bottom gradient + Set button ──────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 40, 24, mq.padding.bottom + 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.80),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Photo: ${widget.entry.credit}',
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      color: Colors.white38,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _apply,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color:
                              _state == _SetState.done
                                  ? Colors.green.withValues(alpha: 0.85)
                                  : accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child:
                              _state == _SetState.loading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    _state == _SetState.done
                                        ? 'Applied!'
                                        : 'Set as Wallpaper',
                                    style: GoogleFonts.sora(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          accent.computeLuminance() > 0.4
                                              ? Colors.black
                                              : Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SetState { idle, loading, done }

// ── Image error / retry widget ────────────────────────────────────────────────
/// Shown in the preview when the full-res image fails to load.
/// Lets the user tap to retry without leaving the screen.
class _ImageErrorRetry extends StatelessWidget {
  const _ImageErrorRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.signal_wifi_off_rounded,
              color: Colors.white24,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Image failed to load',
              style: GoogleFonts.sora(fontSize: 13, color: Colors.white38),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
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
