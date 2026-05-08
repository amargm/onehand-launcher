import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/app_info.dart';
import '../../core/providers/apps_provider.dart';
import '../home/widgets/circular_app_icon.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SearchOverlay
//
// Full-screen blurred overlay. Search bar sits just above the keyboard.
// Results are shown as a 2-row horizontal list directly above the search bar:
//   • Most relevant result → bottom-right (closest to thumb)
//   • Less relevant results → scroll left (bottom row), then top row right→left
// ─────────────────────────────────────────────────────────────────────────────

class SearchOverlay extends ConsumerStatefulWidget {
  const SearchOverlay({super.key, this.pickMode = false, this.onAppPicked});

  final bool pickMode;
  final void Function(String packageName)? onAppPicked;

  @override
  ConsumerState<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends ConsumerState<SearchOverlay>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  Timer? _debounce;
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    // Ensure keyboard appears as soon as the overlay animates in
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    _focusNode.unfocus();
    _animCtrl.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  // ── Relevance ranking ──────────────────────────────────────────────────────
  List<AppInfo> _sortedResults(List<AppInfo> all) {
    if (_query.isEmpty) return all;
    final q = _query;
    final matched =
        all.where((a) => a.appName.toLowerCase().contains(q)).toList();
    matched.sort((a, b) => _score(a, q).compareTo(_score(b, q)));
    return matched;
  }

  int _score(AppInfo app, String q) {
    final name = app.appName.toLowerCase();
    if (name == q) return 0;
    if (name.startsWith(q)) return 1;
    if (name.split(' ').any((w) => w.startsWith(q))) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(appsProvider);
    final mq = MediaQuery.of(context);
    final accent = Theme.of(context).colorScheme.primary;

    // Material(transparency) is required so that IconButton / InkWell widgets
    // inside this overlay can find a Material ancestor. PageRouteBuilder does
    // NOT inject Material the way MaterialPageRoute does, so we must add it
    // ourselves. type: transparency keeps the visual appearance unchanged.
    return Material(
      type: MaterialType.transparency,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          // Tap outside content → dismiss
          onTap: _dismiss,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // ── Blurred dark background ──────────────────────────────────
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: Colors.black.withValues(alpha: 0.62)),
                ),
              ),

              // ── Bottom-anchored content (search bar + results) ───────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  // Prevent taps on content from dismissing the overlay
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── 2-row horizontal results ───────────────────────
                        appsAsync.when(
                          loading: () => const SizedBox(height: 160),
                          error: (_, __) => const SizedBox(height: 160),
                          data: (all) {
                            final results = _sortedResults(all);
                            if (results.isEmpty && _query.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 36,
                                ),
                                child: Center(
                                  child: Text(
                                    'No apps found',
                                    style: GoogleFonts.sora(
                                      color: Colors.white24,
                                      fontSize: 13,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return _TwoRowResults(
                              results:
                                  _query.isEmpty
                                      ? all.take(32).toList()
                                      : results,
                              accent: accent,
                              pickMode: widget.pickMode,
                              onAppPicked: widget.onAppPicked,
                              onDismiss: _dismiss,
                            );
                          },
                        ),

                        // ── Search bar ─────────────────────────────────────
                        _SearchBar(
                          controller: _controller,
                          focusNode: _focusNode,
                          accent: accent,
                          pickMode: widget.pickMode,
                          onChanged: (v) {
                            // Debounce: wait 200 ms after the user stops typing
                            // before filtering/sorting 200+ apps.
                            _debounce?.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 200),
                              () {
                                if (mounted) {
                                  setState(
                                    () => _query = v.trim().toLowerCase(),
                                  );
                                }
                              },
                            );
                          },
                          onClear: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          onDismiss: _dismiss,
                        ),

                        SizedBox(height: mq.padding.bottom + 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 2-Row horizontal result list ──────────────────────────────────────────────
//
// Layout goal:
//   results[0] = most relevant → bottom-right (rightmost visible column, bottom row)
//   results[1] = second → rightmost column, top row
//   results[2] = third  → second-from-right column, bottom row
//   … and so on, scrolling LEFT for less relevant results.
//
// Achieved by:
//   1. Grouping consecutive pairs into columns: col[i] = (top: results[2i+1], bottom: results[2i])
//   2. Reversing the column list so col[0] (most relevant) is rightmost.
// ─────────────────────────────────────────────────────────────────────────────
class _TwoRowResults extends StatelessWidget {
  const _TwoRowResults({
    required this.results,
    required this.accent,
    required this.pickMode,
    required this.onAppPicked,
    required this.onDismiss,
  });

  final List<AppInfo> results;
  final Color accent;
  final bool pickMode;
  final void Function(String)? onAppPicked;
  final VoidCallback onDismiss;

  static const double _iconSize = 50.0;
  static const double _rowH = _iconSize + 20.0; // icon + label
  static const double _gap = 10.0;
  static const double _gridH = _rowH * 2 + _gap;

  List<({AppInfo? top, AppInfo? bottom})> get _columns {
    final cols = <({AppInfo? top, AppInfo? bottom})>[];
    for (int i = 0; i < results.length; i += 2) {
      cols.add((
        top: (i + 1) < results.length ? results[i + 1] : null,
        bottom: results[i],
      ));
    }
    // Most relevant pair (results[0]) is col[0] → leftmost, immediately visible
    return cols;
  }

  void _handleTap(BuildContext context, String pkg) {
    // Execute the action FIRST, then dismiss.
    // In pick mode this ensures the app is added before the overlay animates out.
    if (pickMode && onAppPicked != null) {
      onAppPicked!(pkg);
    } else {
      CircularAppIcon.launch(pkg);
    }
    onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final cols = _columns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pick mode label
        if (pickMode)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'TAP AN APP TO PIN',
              style: GoogleFonts.sora(
                fontSize: 10,
                color: accent.withValues(alpha: 0.65),
                letterSpacing: 2,
              ),
            ),
          ),

        SizedBox(
          height: _gridH,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cols.length,
            itemBuilder: (ctx, i) {
              final col = cols[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row (less relevant of the pair)
                    SizedBox(
                      height: _rowH,
                      child:
                          col.top != null
                              ? CircularAppIcon(
                                app: col.top!,
                                size: _iconSize,
                                onTap:
                                    () => _handleTap(ctx, col.top!.packageName),
                              )
                              : const SizedBox(),
                    ),
                    SizedBox(height: _gap),
                    // Bottom row (more relevant of the pair)
                    SizedBox(
                      height: _rowH,
                      child:
                          col.bottom != null
                              ? CircularAppIcon(
                                app: col.bottom!,
                                size: _iconSize,
                                onTap:
                                    () => _handleTap(
                                      ctx,
                                      col.bottom!.packageName,
                                    ),
                              )
                              : const SizedBox(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────
// StatefulWidget so we can react to focus and animate the border/glow.
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.accent,
    required this.pickMode,
    required this.onChanged,
    required this.onClear,
    required this.onDismiss,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accent;
  final bool pickMode;
  final void Function(String) onChanged;
  final VoidCallback onClear;
  final VoidCallback onDismiss;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    // Input field: #121212 bg, 1px #2A2A2A border; on focus → orange border + glow
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        // Input fields sit on Surface 0 (#121212) — darker than card
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16), // Buttons/inputs: 16px
        border: Border.all(
          color: _focused ? accent : const Color(0xFF2A2A2A),
          width: 1,
        ),
        boxShadow:
            _focused
                ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
                : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            color: _focused ? accent : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: true,
              style: GoogleFonts.hankenGrotesk(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              cursorColor: accent,
              decoration: InputDecoration(
                hintText: widget.pickMode ? 'Search to pin…' : 'Search apps…',
                hintStyle: GoogleFonts.hankenGrotesk(
                  color: Colors.white38,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child:
                widget.controller.text.isNotEmpty
                    ? IconButton(
                      key: const ValueKey('clear'),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white38,
                        size: 18,
                      ),
                      onPressed: widget.onClear,
                    )
                    : IconButton(
                      key: const ValueKey('down'),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white24,
                        size: 22,
                      ),
                      onPressed: widget.onDismiss,
                    ),
          ),
        ],
      ),
    );
  }
}
