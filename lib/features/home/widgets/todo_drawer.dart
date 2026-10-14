import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/planner_item.dart';
import '../../../core/providers/planner_items_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/headphone_provider.dart';
import '../../../core/providers/schedule_rules_provider.dart';

/// True while the planner's lower edge is merging with the dock/context shell.
/// The dock listens to this one threshold rather than rebuilding every frame.
final plannerDrawerCoveringDockProvider = StateProvider<bool>((ref) => false);

/// Actual laid-out height of the dock/context-shell surface, measured by
/// AppDock and used as the planner morph's collapsed geometry.
final dockSurfaceGeometryProvider = StateProvider<Size?>((ref) => null);

/// Tracks which PageView page is active so the planner can recover its
/// animation after a round-trip to the calendar page.
final homePageActiveProvider = StateProvider<bool>((ref) => true);

/// Locks the home PageView while the planner is expanded so horizontal
/// gestures cannot detach the dock/shell from the planner surface.
final plannerDrawerOpenProvider = StateProvider<bool>((ref) => false);

Color _contrastForeground(Color background) =>
    background.computeLuminance() > 0.50 ? Colors.black : Colors.white;

class TodoDrawer extends ConsumerStatefulWidget {
  const TodoDrawer({super.key});

  @override
  ConsumerState<TodoDrawer> createState() => _TodoDrawerState();
}

class _TodoDrawerState extends ConsumerState<TodoDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  bool _open = false;
  bool _dockCovering = false;
  bool _draggedUp = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      // Give collapse a little more travel time so the surface settles back
      // into the dock instead of snapping through the final part of the morph.
      reverseDuration: const Duration(milliseconds: 520),
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInOutQuart,
    );
    _controller.addListener(_syncDockCovering);
  }

  void _syncDockCovering() {
    // Keep the dock/context shell covered until the planner is almost
    // fully collapsed. Revealing it at 12% progress made it appear while the
    // planner still had a visible extra band of height, breaking the single-
    // surface morph. Both edges now settle before the dock is handed back.
    final shouldCover = _controller.value >= 0.015;
    if (shouldCover == _dockCovering) return;
    _dockCovering = shouldCover;
    ref.read(plannerDrawerCoveringDockProvider.notifier).state = shouldCover;
  }

  @override
  void dispose() {
    _controller.removeListener(_syncDockCovering);
    ref.read(plannerDrawerCoveringDockProvider.notifier).state = false;
    ref.read(plannerDrawerOpenProvider.notifier).state = false;
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    _settle(!_open);
  }

  void _settle(bool open) {
    ref.read(plannerDrawerOpenProvider.notifier).state = open;
    setState(() => _open = open);
    if (open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    // Keep the current animation interruptible, but do not render a partially
    // dragged handle/sliver. The gesture chooses a destination; one animation
    // then carries the entire surface there.
    _controller.stop();
    _draggedUp = false;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta! < 0) _draggedUp = true;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_draggedUp || velocity < -20) {
      // Any upward swipe, however short, completes the full opening.
      _settle(true);
    } else if (velocity > 80) {
      _settle(false);
    }
  }

  Future<void> _addItem() async {
    final item = await showModalBottomSheet<PlannerItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1D20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => const _PlannerItemForm(),
    );
    if (item != null && mounted) {
      final saved = await ref.read(plannerItemsProvider.notifier).add(item);
      if (!saved && mounted) _showPersistenceWarning();
    }
  }

  Future<void> _togglePlannerItem(PlannerItem item) async {
    final saved = await ref
        .read(plannerItemsProvider.notifier)
        .toggleCompleted(item.id);
    if (!saved && mounted) _showPersistenceWarning();
  }

  void _showPersistenceWarning() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            "Couldn't save this change. It may be lost when the app closes.",
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'RETRY',
            onPressed: () async {
              final saved =
                  await ref.read(plannerItemsProvider.notifier).persist();
              if (!mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      saved
                          ? 'Planner changes saved'
                          : 'Still unable to save planner changes',
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                  ),
                );
            },
          ),
        ),
      );
  }

  Future<void> _deletePlannerItem(PlannerItem item) async {
    final notifier = ref.read(plannerItemsProvider.notifier);
    final saved = await notifier.remove(item.id);
    if (!mounted) return;
    if (!saved) {
      _showPersistenceWarning();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '“${item.title}” deleted',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              final restored = await notifier.add(item);
              if (!restored && mounted) _showPersistenceWarning();
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(homePageActiveProvider, (previous, active) {
      if (!active || !mounted) return;
      // A horizontal PageView gesture can interrupt the composited planner
      // surface. Rebuild it on return and resume the intended open state.
      setState(() {});
      if (_open && !_controller.isAnimating) {
        _controller.forward();
      }
    });
    final mq = MediaQuery.of(context);
    final accent = ref.watch(accentColorProvider);
    final items = [...ref.watch(plannerItemsProvider)]
      ..sort((a, b) => a.date.compareTo(b.date));
    final shellVisible = ref.watch(headphoneProvider) ||
        ref.watch(isScheduleContextActiveProvider);
    // Prefer the real laid-out dock/shell height; the fallback is only used
    // for the first frame before AppDock has reported its geometry.
    final dockGeometry = ref.watch(dockSurfaceGeometryProvider);
    final dockBridgeHeight =
        dockGeometry?.height ?? (shellVisible ? 184.0 : 92.0);

    // Size the complete expanded surface (planner + morph bridge) to 75% of
    // the usable display, not 75% of the raw screen plus system insets.
    final usableHeight = (mq.size.height - mq.padding.top - mq.padding.bottom)
        .clamp(1.0, double.infinity)
        .toDouble();
    final expandedSurfaceHeight = usableHeight * 0.75;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) {
          // One progress value drives every part of the dock-to-planner
          // morph. Width, height, lower edge, radius and content all move
          // together; there is no delayed second expansion phase.
          final t = _curve.value;
          final compactWidth = dockGeometry?.width ??
              (mq.size.width - 48).clamp(200.0, 280.0).toDouble();
          final panelWidth = compactWidth +
              (mq.size.width - 32 - compactWidth) * t;
          final panelLeft = (mq.size.width - panelWidth) / 2;
          final floatingBottom = mq.padding.bottom + 24;
          // Keep the planner's lower edge anchored to the dock's lower edge.
          // The panel height shrinks onto the measured dock/shell bounds, rather
          // than lifting the whole panel by the dock height during collapse.
          final panelBottom = floatingBottom;
          final panelHeight = dockBridgeHeight +
              (expandedSurfaceHeight - dockBridgeHeight) * t;
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (t > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !_open,
                    child: GestureDetector(
                      onTap: _toggle,
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.42 * t),
                      ),
                    ),
                  ),
                ),
              if (t > 0)
                Positioned(
                  left: panelLeft,
                  right: panelLeft,
                  bottom: panelBottom,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40 - 12 * t),
                      topRight: Radius.circular(40 - 12 * t),
                      // Keep the expanded panel visibly floating, just like
                      // the dock; never square it off against the screen edge.
                      bottomLeft: Radius.circular(40 - 12 * t),
                      bottomRight: Radius.circular(40 - 12 * t),
                    ),
                    child: ClipRect(
                      child: SizedBox(
                        height: panelHeight,
                        child: IgnorePointer(
                          ignoring: !_open,
                          child: _buildPanel(items, accent, t),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!_open)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: mq.padding.bottom + 40,
                  height: 160,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: _onVerticalDragStart,
                    onVerticalDragUpdate: _onVerticalDragUpdate,
                    onVerticalDragEnd: _onVerticalDragEnd,
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPanel(List<PlannerItem> items, Color accent, double expansion) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final grouped = <DateTime, List<PlannerItem>>{};
    for (final item in items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      grouped.putIfAbsent(date, () => []).add(item);
    }
    final dates = grouped.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40 - 12 * expansion)),
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20 * expansion),
            blurRadius: 24 * expansion,
            offset: Offset(0, -4 * expansion),
          ),
        ],
      ),
      child: Opacity(
        opacity: ((expansion - 0.08) / 0.84).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - expansion)),
          child: Column(
        children: [
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            onTap: _toggle,
            child: SizedBox(
              width: double.infinity,
              height: 24,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: _open ? 42 : 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: _open ? 0.38 : 0.24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TO-DO & EVENTS',
                          style: GoogleFonts.sora(
                            color: accent,
                            fontSize: 9,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 3),
                      Text('Your upcoming plans',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        '${items.where((e) => !e.isCompleted && e.type == PlannerItemType.todo).length} to-do left',
                        style: GoogleFonts.sora(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: 'Add a to-do or event',
                  child: IconButton(
                    tooltip: 'Add a to-do or event',
                    onPressed: _addItem,
                    style: IconButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: _contrastForeground(accent),
                      minimumSize: const Size(48, 48),
                      fixedSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 23),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: dates.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_note_rounded, size: 34, color: accent.withValues(alpha: 0.8)),
                          const SizedBox(height: 12),
                          Text('A little space for what matters',
                              style: GoogleFonts.sora(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Text('Add a to-do or event and it will appear here by date.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.sora(color: Colors.white54, fontSize: 10, height: 1.45)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      final dayItems = grouped[date]!;
                      final isToday = date == today;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
                            child: Row(
                              children: [
                                Text(_dayLabel(date, today),
                                    style: GoogleFonts.sora(
                                      color: isToday ? accent : Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    )),
                                const SizedBox(width: 8),
                                Text(_dateLabel(date),
                                    style: GoogleFonts.sora(color: Colors.white38, fontSize: 10)),
                                const SizedBox(width: 8),
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                              ],
                            ),
                          ),
                          for (final item in dayItems)
                            _PlannerItemTile(
                              item: item,
                              accent: accent,
                              onToggle: () => _togglePlannerItem(item),
                              onDelete: () => _deletePlannerItem(item),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              // The panel already floats above the system navigation inset.
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
              child: IconButton(
                tooltip: 'Collapse to-do and events',
                onPressed: _toggle,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF29292D),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                  fixedSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 27),
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  static String _dayLabel(DateTime date, DateTime today) {
    if (date == today) return 'TODAY';
    if (date == today.add(const Duration(days: 1))) return 'TOMORROW';
    return const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][date.weekday - 1];
  }

  static String _dateLabel(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _PlannerItemTile extends StatelessWidget {
  const _PlannerItemTile({
    required this.item,
    required this.accent,
    required this.onToggle,
    required this.onDelete,
  });

  final PlannerItem item;
  final Color accent;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isTodo = item.type == PlannerItemType.todo;
    final muted = item.isCompleted;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        color: Colors.red.withValues(alpha: 0.15),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1E),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.075)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      color: muted ? Colors.white38 : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: muted ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white38,
                    ),
                  ),
                  if (item.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                        color: muted ? Colors.white24 : Colors.white54,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _PlannerTypePill(
                    label: isTodo
                        ? (item.isCompleted ? 'COMPLETED' : 'TO-DO')
                        : 'EVENT',
                    icon: isTodo
                        ? (item.isCompleted
                            ? Icons.check_rounded
                            : Icons.radio_button_unchecked_rounded)
                        : Icons.event_rounded,
                    color: isTodo ? accent : const Color(0xFFFFB547),
                    subdued: muted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            if (isTodo)
              Semantics(
                button: true,
                label: item.isCompleted
                    ? 'Mark as not completed'
                    : 'Mark as completed',
                child: InkWell(
                  onTap: () {
                    Feedback.forTap(context);
                    onToggle();
                  },
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                        child: Icon(
                          item.isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          key: ValueKey(item.isCompleted),
                          size: 25,
                          color: item.isCompleted
                              ? accent
                              : Colors.white.withValues(alpha: 0.48),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB547).withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Color(0xFFFFB547),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlannerTypePill extends StatelessWidget {
  const _PlannerTypePill({
    required this.label,
    required this.icon,
    required this.color,
    required this.subdued,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final foreground = color.withValues(alpha: subdued ? 0.48 : 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: subdued ? 0.055 : 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: subdued ? 0.10 : 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.sora(
              color: foreground,
              fontSize: 8,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerItemForm extends StatefulWidget {
  const _PlannerItemForm();

  @override
  State<_PlannerItemForm> createState() => _PlannerItemFormState();
}

class _PlannerItemFormState extends State<_PlannerItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime _date = DateTime.now();
  PlannerItemType _type = PlannerItemType.todo;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7448FF),
            surface: Color(0xFF252529),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)))),
              const SizedBox(height: 18),
              Text('Add something to your day',
                  style: GoogleFonts.sora(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              SegmentedButton<PlannerItemType>(
                segments: const [
                  ButtonSegment(value: PlannerItemType.todo, label: Text('To-do'), icon: Icon(Icons.check_circle_outline_rounded)),
                  ButtonSegment(value: PlannerItemType.event, label: Text('Event'), icon: Icon(Icons.event_rounded)),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text('${_date.day.toString().padLeft(2, '0')} / ${_date.month.toString().padLeft(2, '0')} / ${_date.year}'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                autofocus: true,
                maxLength: 70,
                decoration: const InputDecoration(labelText: 'Headline', hintText: 'What do you need to do?'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please add a headline' : null,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _description,
                maxLines: 3,
                maxLength: 180,
                decoration: const InputDecoration(labelText: 'Short description (optional)', hintText: 'Add a little detail…'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.pop(context, PlannerItem(
                      date: _date,
                      title: _title.text.trim(),
                      description: _description.text.trim(),
                      type: _type,
                    ));
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
