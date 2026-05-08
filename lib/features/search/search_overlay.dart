import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/apps_provider.dart';
import '../home/widgets/circular_app_icon.dart';

/// Full-screen search overlay — slides up from the dock search button.
/// In [pickMode] tapping an app calls [onAppPicked] instead of launching it.
class SearchOverlay extends ConsumerStatefulWidget {
  const SearchOverlay({super.key, this.pickMode = false, this.onAppPicked});

  final bool pickMode;
  final void Function(String packageName)? onAppPicked;

  @override
  ConsumerState<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends ConsumerState<SearchOverlay> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(appsProvider);
    final mq = MediaQuery.of(context);

    return Container(
      height: mq.size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle ─────────────────────────────────────────────────────
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Search field ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: GoogleFonts.sora(color: Colors.white, fontSize: 15),
                cursorColor: Theme.of(context).colorScheme.primary,
                decoration: InputDecoration(
                  hintText: 'Search apps…',
                  hintStyle: GoogleFonts.sora(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white24,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged:
                    (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Pick mode label
          if (widget.pickMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'TAP AN APP TO PIN',
                style: GoogleFonts.sora(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
            ),

          // ── Results ─────────────────────────────────────────────────────
          Expanded(
            child: appsAsync.when(
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
              error:
                  (_, __) => Center(
                    child: Text(
                      'Error loading apps',
                      style: GoogleFonts.sora(color: Colors.white38),
                    ),
                  ),
              data: (apps) {
                final filtered =
                    _query.isEmpty
                        ? apps
                        : apps
                            .where(
                              (a) => a.appName.toLowerCase().contains(_query),
                            )
                            .toList();

                if (filtered.isEmpty) {
                  return Container(
                    height: mq.size.height * 0.85,
                    alignment: Alignment.center,
                    child: Text(
                      'No apps found',
                      style: GoogleFonts.sora(
                        color: Colors.white24,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final app = filtered[i];
                    return CircularAppIcon(
                      app: app,
                      size: 52,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (widget.pickMode && widget.onAppPicked != null) {
                          widget.onAppPicked!(app.packageName);
                        } else {
                          CircularAppIcon.launch(app.packageName);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),

          SizedBox(height: mq.padding.bottom + 8),
        ],
      ),
    );
  }
}
