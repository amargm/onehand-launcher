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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInCubic,
    );
    _controller.addListener(_syncDockCovering);
  }

  void _syncDockCovering() {
    final shouldCover = _curve.value >= 0.70;
    if (shouldCover == _dockCovering) return;
    _dockCovering = shouldCover;
    ref.read(plannerDrawerCoveringDockProvider.notifier).state = shouldCover;
  }

  @override
  void dispose() {
    _controller.removeListener(_syncDockCovering);
    ref.read(plannerDrawerCoveringDockProvider.notifier).state = false;
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
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
    final mq = MediaQuery.of(context);
    final accent = ref.watch(accentColorProvider);
    final items = [...ref.watch(plannerItemsProvider)]
      ..sort((a, b) => a.date.compareTo(b.date));
    final panelHeight = mq.size.height * 0.65;
    final shellVisible = ref.watch(headphoneProvider) ||
        ref.watch(isScheduleContextActiveProvider);
    final dockBridgeHeight = shellVisible ? 184.0 : 92.0;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) {
          final t = _curve.value;
          // The planner grows from the dock's floating footprint instead of
          // stretching to the physical screen edge. Keep its resting baseline
          // aligned with AppDock's bottom spacing (system inset + 24 px).
          // Phase 1 (0–70%): grow upward from the top of the dock/shell.
          // Phase 2 (70–100%): extend the lower edge down to the dock's
          // floating baseline, while the dock itself gently fades away.
          final upT = (t / 0.70).clamp(0.0, 1.0);
          final downT = ((t - 0.70) / 0.30).clamp(0.0, 1.0);
          final compactWidth = (mq.size.width - 48).clamp(200.0, 280.0).toDouble();
          final panelWidth = compactWidth +
              (mq.size.width - 32 - compactWidth) * downT;
          final panelLeft = (mq.size.width - panelWidth) / 2;
          final floatingBottom = mq.padding.bottom + 24;
          final panelBottom = floatingBottom + dockBridgeHeight * (1 - downT);
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
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        heightFactor: upT,
                        child: SizedBox(
                          height: panelHeight + dockBridgeHeight * downT,
                          child: IgnorePointer(
                            ignoring: !_open,
                            child: _buildPanel(items, accent, t),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!_open)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: mq.padding.bottom + 64,
                  height: 96,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragEnd: (details) {
                      if ((details.primaryVelocity ?? 0) < -120) _toggle();
                    },
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
        opacity: ((expansion - 0.12) / 0.78).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - expansion)),
          child: Column(
        children: [
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -120 && !_open) {
                _toggle();
              } else if (velocity > 120 && _open) {
                _toggle();
              }
            },
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
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF252529),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTodo)
              Semantics(
                button: true,
                label: item.isCompleted ? 'Mark as not completed' : 'Mark as completed',
                child: InkWell(
                  onTap: () {
                    Feedback.forTap(context);
                    onToggle();
                  },
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => ScaleTransition(
                          scale: animation,
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                        child: Icon(
                          item.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                          key: ValueKey(item.isCompleted),
                          size: 20,
                          color: item.isCompleted ? accent : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 1),
                child: Icon(Icons.event_available_rounded, size: 19, color: accent),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: GoogleFonts.sora(
                        color: item.isCompleted ? Colors.white38 : Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      )),
                  if (item.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.description,
                        style: GoogleFonts.sora(color: Colors.white54, fontSize: 9.5, height: 1.35)),
                  ],
                  const SizedBox(height: 5),
                  Text(isTodo ? (item.isCompleted ? 'COMPLETED' : 'TO-DO') : 'EVENT',
                      style: GoogleFonts.sora(color: accent.withValues(alpha: 0.9), fontSize: 7.5, letterSpacing: 1.0, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
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
