import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Minimalist lock screen — left-aligned 64 sp clock, refined typographic date.
/// Swipe up to dismiss.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timeString {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _dateString {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final wd = weekdays[_now.weekday - 1];
    final mo = months[_now.month - 1];
    return '$wd, $mo ${_now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -200) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Clock ───────────────────────────────────────────────
                Text(
                  _timeString,
                  style: GoogleFonts.sora(
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),

                const SizedBox(height: 6),

                // ── Date ────────────────────────────────────────────────
                Text(
                  _dateString,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white54,
                    letterSpacing: 1.4,
                  ),
                ),

                const Spacer(),

                // ── Swipe hint ───────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.white12,
                        size: 28,
                      ),
                      Text(
                        'swipe up',
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color: Colors.white12,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
