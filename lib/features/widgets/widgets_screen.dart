import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/settings_provider.dart';

class WidgetsScreen extends ConsumerStatefulWidget {
  const WidgetsScreen({super.key});

  @override
  ConsumerState<WidgetsScreen> createState() => WidgetsScreenState();
}

/// Public state — HomeScreen holds a GlobalKey for WidgetsScreenState
/// and calls resetToCurrentYear() when the user swipes back to page 0.
class WidgetsScreenState extends ConsumerState<WidgetsScreen>
    with WidgetsBindingObserver {
  late int _displayYear;

  @override
  void initState() {
    super.initState();
    _displayYear = DateTime.now().year;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) resetToCurrentYear();
  }

  void resetToCurrentYear() {
    if (mounted) setState(() => _displayYear = DateTime.now().year);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final accent = ref.watch(accentColorProvider);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: mq.padding.top + 10),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _YearCalendarGrid(
              year: _displayYear,
              today: now,
              accent: accent,
            ),
          ),
        ),

        const SizedBox(height: 10),

        _YearNavBar(
          year: _displayYear,
          currentYear: now.year,
          accent: accent,
          onPrev: () => setState(() => _displayYear--),
          onNext: () => setState(() => _displayYear++),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _AddWidgetButton(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'More widgets coming soon',
                    style: GoogleFonts.sora(fontSize: 13),
                  ),
                  backgroundColor: const Color(0xFF1A1A1A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),

        SizedBox(height: mq.padding.bottom + 14),
      ],
    );
  }
}

// ── 3 × 4 year grid ───────────────────────────────────────────────────────────

class _YearCalendarGrid extends StatelessWidget {
  const _YearCalendarGrid({
    required this.year,
    required this.today,
    required this.accent,
  });

  final int year;
  final DateTime today;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossGap = 10.0;
        const mainGap = 10.0;

        final cellW = (constraints.maxWidth - crossGap * 2) / 3;
        final cellH = (constraints.maxHeight - mainGap * 3) / 4;

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int row = 0; row < 4; row++)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int col = 0; col < 3; col++)
                    SizedBox(
                      width: cellW,
                      height: cellH,
                      child: _MiniMonth(
                        month: row * 3 + col + 1,
                        year: year,
                        today: today,
                        accent: accent,
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

// ── Single mini-month ─────────────────────────────────────────────────────────

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.month,
    required this.year,
    required this.today,
    required this.accent,
  });

  final int month;
  final int year;
  final DateTime today;
  final Color accent;

  static const _fullNames = [
    'January', 'February', 'March',
    'April',   'May',      'June',
    'July',    'August',   'September',
    'October', 'November', 'December',
  ];
  static const _dow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = year == today.year && month == today.month;

    // Monday-first offset
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon … 7=Sun
    final offset = firstWeekday - 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cellW = w / 7;

        const nameRatio = 0.14;
        const dowRatio = 0.11;
        const daysRatio = 1.0 - nameRatio - dowRatio;

        final nameH = h * nameRatio;
        final dowH = h * dowRatio;
        final rowH = (h * daysRatio) / 6; // always 6 rows reserved

        final headerColor = isCurrentMonth
            ? accent
            : Colors.white.withValues(alpha: 0.40);

        final nameFontSize = (nameH * 0.62).clamp(7.0, 11.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Full month name — centered, scaled to fit ─────────────────
            SizedBox(
              height: nameH,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _fullNames[month - 1],
                    style: GoogleFonts.sora(
                      fontSize: nameFontSize,
                      fontWeight: isCurrentMonth
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: headerColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),

            // ── Day-of-week headers ────────────────────────────────────────
            SizedBox(
              height: dowH,
              child: Row(
                children: _dow
                    .map(
                      (d) => SizedBox(
                        width: cellW,
                        child: Center(
                          child: Text(
                            d,
                            style: GoogleFonts.sora(
                              fontSize: (dowH * 0.52).clamp(5.5, 8.5),
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.13),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            // ── 6 day rows ─────────────────────────────────────────────────
            for (int row = 0; row < 6; row++)
              SizedBox(
                height: rowH,
                child: Row(
                  children: List.generate(7, (col) {
                    final dayNum = row * 7 + col - offset + 1;
                    final valid = dayNum >= 1 && dayNum <= daysInMonth;
                    final isToday = isCurrentMonth && dayNum == today.day;

                    return SizedBox(
                      width: cellW,
                      child: Center(
                        child: !valid
                            ? null
                            : isToday
                                ? _TodayBadge(
                                    day: dayNum,
                                    size: rowH * 0.76,
                                    accent: accent,
                                  )
                                : Text(
                                    '$dayNum',
                                    style: GoogleFonts.sora(
                                      fontSize:
                                          (rowH * 0.42).clamp(6.5, 11.0),
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white.withValues(
                                        alpha: isCurrentMonth ? 0.68 : 0.38,
                                      ),
                                    ),
                                  ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Today highlight badge ─────────────────────────────────────────────────────

class _TodayBadge extends StatelessWidget {
  const _TodayBadge({
    required this.day,
    required this.size,
    required this.accent,
  });

  final int day;
  final double size;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.16),
        border: Border.all(
          color: accent.withValues(alpha: 0.75),
          width: 0.8,
        ),
      ),
      child: Center(
        child: Text(
          '$day',
          style: GoogleFonts.sora(
            fontSize: (size * 0.42).clamp(6.5, 11.0),
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ),
    );
  }
}

// ── Year navigation bar ───────────────────────────────────────────────────────

class _YearNavBar extends StatelessWidget {
  const _YearNavBar({
    required this.year,
    required this.currentYear,
    required this.accent,
    required this.onPrev,
    required this.onNext,
  });

  final int year;
  final int currentYear;
  final Color accent;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isNow = year == currentYear;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavChevron(
          icon: Icons.chevron_left_rounded,
          onTap: onPrev,
          accent: accent,
        ),
        const SizedBox(width: 24),
        Text(
          '$year',
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: isNow
                ? accent.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(width: 24),
        _NavChevron(
          icon: Icons.chevron_right_rounded,
          onTap: onNext,
          accent: accent,
        ),
      ],
    );
  }
}

class _NavChevron extends StatelessWidget {
  const _NavChevron({
    required this.icon,
    required this.onTap,
    required this.accent,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: Icon(icon, size: 18, color: accent.withValues(alpha: 0.65)),
      ),
    );
  }
}

// ── Add Widget button ─────────────────────────────────────────────────────────

class _AddWidgetButton extends StatelessWidget {
  const _AddWidgetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          color: Colors.white.withValues(alpha: 0.03),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: 15,
              color: Colors.white.withValues(alpha: 0.30),
            ),
            const SizedBox(width: 8),
            Text(
              'Add Widget',
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
                color: Colors.white.withValues(alpha: 0.30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
