import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Context Active" pill — top-of-screen non-intrusive status indicator.
/// Surfaces a time-aware hint inside a compact rounded capsule.
class ContextSection extends ConsumerStatefulWidget {
  const ContextSection({super.key});

  @override
  ConsumerState<ContextSection> createState() => _ContextSectionState();
}

class _ContextSectionState extends ConsumerState<ContextSection> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _contextLabel {
    final h = _now.hour;
    if (h >= 9 && h < 18) return 'Focus mode active';
    if (h >= 18 && h < 23) return 'Wind-down mode';
    return 'Rest mode';
  }

  IconData get _contextIcon {
    final h = _now.hour;
    if (h >= 9 && h < 18) return Icons.bolt_rounded;
    if (h >= 18 && h < 23) return Icons.nightlight_rounded;
    return Icons.bedtime_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: accent.withValues(alpha: 0.18), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing dot
            _PulseDot(color: accent),
            const SizedBox(width: 8),
            Icon(_contextIcon, color: accent, size: 12),
            const SizedBox(width: 5),
            Text(
              _contextLabel,
              style: GoogleFonts.sora(
                fontSize: 11,
                color: Colors.white60,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small animated pulse dot to indicate live status.
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_anim),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
