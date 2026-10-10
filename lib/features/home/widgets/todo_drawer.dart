import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/planner_item.dart';
import '../../../core/providers/planner_items_provider.dart';
import '../../../core/providers/settings_provider.dart';

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
  }

  @override
  void dispose() {
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
      ref.read(plannerItemsProvider.notifier).add(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final accent = ref.watch(accentColorProvider);
    final items = [...ref.watch(plannerItemsProvider)]
      ..sort((a, b) => a.date.compareTo(b.date));
    final panelHeight = mq.size.height * 0.65;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) {
          final t = _curve.value;
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
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: t,
                      child: SizedBox(
                        height: panelHeight,
                        child: IgnorePointer(
                          ignoring: !_open,
                          child: _buildPanel(items, accent, mq.padding.bottom),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: mq.padding.bottom + 72 * (1 - t),
                child: _togglePill(accent, t),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _togglePill(Color accent, double t) {
    return GestureDetector(
      onTap: _toggle,
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -3 && !_open) _toggle();
        if (details.delta.dy > 3 && _open) _toggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF202023),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              t > 0.5 ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
              size: 18,
              color: accent,
            ),
            const SizedBox(width: 7),
            Text(
              'TO-DO & EVENTS',
              style: GoogleFonts.sora(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 10,
                letterSpacing: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 7),
            Icon(
              t > 0.5 ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
              size: 18,
              color: accent.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(List<PlannerItem> items, Color accent, double bottomInset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final grouped = <DateTime, List<PlannerItem>>{};
    for (final item in items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      grouped.putIfAbsent(date, () => []).add(item);
    }
    final dates = grouped.keys.toList()..sort();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
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
            padding: const EdgeInsets.fromLTRB(20, 17, 18, 12),
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
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 5),
                      Text('Your upcoming plans',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
                Text('${items.where((e) => !e.isCompleted && e.type == PlannerItemType.todo).length} left',
                    style: GoogleFonts.sora(color: Colors.white54, fontSize: 11)),
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
                              style: GoogleFonts.sora(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Text('Add a to-do or event and it will appear here by date.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.sora(color: Colors.white54, fontSize: 11, height: 1.5)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 88),
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
                              onToggle: () => ref.read(plannerItemsProvider.notifier).toggleCompleted(item.id),
                              onDelete: () => ref.read(plannerItemsProvider.notifier).remove(item.id),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 2, 18, 12 + bottomInset),
              child: FloatingActionButton(
                heroTag: 'planner_add_button',
                tooltip: 'Add a to-do or event',
                onPressed: _addItem,
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 3,
                highlightElevation: 6,
                mini: false,
                child: const Icon(Icons.add_rounded, size: 25),
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(12),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      )),
                  if (item.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.description,
                        style: GoogleFonts.sora(color: Colors.white54, fontSize: 10, height: 1.4)),
                  ],
                  const SizedBox(height: 5),
                  Text(isTodo ? (item.isCompleted ? 'COMPLETED' : 'TO-DO') : 'EVENT',
                      style: GoogleFonts.sora(color: accent.withValues(alpha: 0.9), fontSize: 8, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
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
