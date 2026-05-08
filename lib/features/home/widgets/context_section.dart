import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/context_settings_provider.dart';
import '../../../core/services/launcher_service.dart';

/// Top-of-screen row of up to 4 configurable context indicator pills.
/// Items shown are controlled by [contextItemsProvider].
class ContextSection extends ConsumerStatefulWidget {
  const ContextSection({super.key});

  @override
  ConsumerState<ContextSection> createState() => _ContextSectionState();
}

class _ContextSectionState extends ConsumerState<ContextSection> {
  late Timer _timer;
  late DateTime _now;
  bool _headphoneConnected = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _pollHeadphone();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
        _pollHeadphone();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _pollHeadphone() async {
    try {
      final connected = await LauncherService.isHeadphoneConnected();
      if (mounted && connected != _headphoneConnected) {
        setState(() => _headphoneConnected = connected);
      }
    } catch (_) {
      // ignore platform errors (emulator / audio service unavailable)
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(contextItemsProvider);
    final accent = Theme.of(context).colorScheme.primary;

    final items =
        ContextItemType.values
            .where((t) => enabled.contains(t))
            .map((t) => _buildPill(context, t, accent))
            .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildPill(BuildContext context, ContextItemType type, Color accent) {
    final (icon, label, active) = _itemData(type, accent);
    final pillColor = active ? accent : Colors.white24;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: pillColor.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: pillColor),
          const SizedBox(width: 6),
          Icon(icon, color: pillColor, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 10,
              color: active ? Colors.white60 : Colors.white30,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns (icon, label, isActive) for each context type.
  (IconData, String, bool) _itemData(ContextItemType type, Color accent) {
    final h = _now.hour;
    switch (type) {
      case ContextItemType.time:
        if (h >= 9 && h < 18) {
          return (Icons.bolt_rounded, 'Focus mode', true);
        } else if (h >= 18 && h < 23) {
          return (Icons.nightlight_rounded, 'Wind-down', true);
        } else {
          return (Icons.bedtime_outlined, 'Rest mode', false);
        }
      case ContextItemType.headphone:
        return _headphoneConnected
            ? (Icons.headphones_rounded, 'Headphones', true)
            : (Icons.headphones_outlined, 'No audio', false);
      case ContextItemType.day:
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return (Icons.calendar_today_outlined, days[_now.weekday - 1], true);
      case ContextItemType.date:
        return (
          Icons.event_outlined,
          '${_now.day} ${_monthAbbr(_now.month)}',
          true,
        );
    }
  }

  String _monthAbbr(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
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
