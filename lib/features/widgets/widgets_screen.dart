import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/calendar_event.dart';
import '../../core/providers/calendar_events_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/holidays_service.dart';

// ── Color helpers ─────────────────────────────────────────────────────────────

Color _fg(bool isLight, double alpha) =>
    (isLight ? Colors.black : Colors.white).withValues(alpha: alpha);

// ── Widget Screen ─────────────────────────────────────────────────────────────

class WidgetsScreen extends ConsumerStatefulWidget {
  const WidgetsScreen({super.key});

  @override
  ConsumerState<WidgetsScreen> createState() => WidgetsScreenState();
}

/// Public state — HomeScreen holds a GlobalKey for WidgetsScreenState
/// and calls resetToCurrentYear() when the user swipes back to page 0.
class WidgetsScreenState extends ConsumerState<WidgetsScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late int _displayYear;
  bool _panelOpen = false;

  List<CalendarEvent> _holidays = [];
  bool _holidaysLoading = false;
  String? _holidaysError;
  int? _loadedYear;
  String? _loadedCountry;

  @override
  bool get wantKeepAlive => true;

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
    if (!mounted) return;
    final now = DateTime.now().year;
    if (now != _displayYear) {
      setState(() {
        _displayYear = now;
        _holidays = [];
        _holidaysError = null;
      });
      _loadHolidaysIfNeeded();
    }
    setState(() => _panelOpen = false);
  }

  // ── Holiday loading ───────────────────────────────────────────────────────

  void _loadHolidaysIfNeeded() {
    final cc = ref.read(calCountryCodeProvider);
    if (cc == null) return;
    if (_loadedYear == _displayYear && _loadedCountry == cc) return;
    _doLoad(cc, force: false);
  }

  Future<void> _doLoad(String cc, {bool force = false}) async {
    if (!mounted) return;
    setState(() {
      _holidaysLoading = true;
      _holidaysError = null;
    });
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final events = force
          ? await HolidaysService.refreshHolidays(_displayYear, cc, prefs)
          : await HolidaysService.fetchHolidays(_displayYear, cc, prefs);
      if (mounted) {
        setState(() {
          _holidays = events;
          _holidaysLoading = false;
          _loadedYear = _displayYear;
          _loadedCountry = cc;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _holidaysError = e.toString().replaceFirst('Exception: ', '');
          _holidaysLoading = false;
        });
      }
    }
  }

  Future<void> _requestCountryAndLoad() async {
    if (!mounted) return;
    setState(() {
      _holidaysLoading = true;
      _holidaysError = null;
    });
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final cc = await HolidaysService.detectCountryCode(prefs);
      if (!mounted) return;
      if (cc != null) {
        ref.read(calCountryCodeProvider.notifier).set(cc);
        await _doLoad(cc);
      } else {
        setState(() => _holidaysLoading = false);
        await _showCountryPicker();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _holidaysError = e.toString().replaceFirst('Exception: ', '');
          _holidaysLoading = false;
        });
      }
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<void> _showCountryPicker() async {
    final accent = ref.read(accentColorProvider);
    final isLight = ref.read(widgetLightModeProvider);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _CountryPickerDialog(accent: accent, isLight: isLight),
    );
    if (result != null && mounted) {
      final prefs = ref.read(sharedPreferencesProvider);
      await HolidaysService.setCountryCode(prefs, result);
      ref.read(calCountryCodeProvider.notifier).set(result);
      await _doLoad(result);
    }
  }

  Future<void> _showAddEventDialog() async {
    final accent = ref.read(accentColorProvider);
    final isLight = ref.read(widgetLightModeProvider);
    final now = DateTime.now();
    DateTime selectedDate = DateTime(
      _displayYear,
      now.year == _displayYear ? now.month : 1,
      now.year == _displayYear ? now.day : 1,
    );
    final nameCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final bg = isLight ? Colors.white : const Color(0xFF1E1E1E);
          final textColor = _fg(isLight, 0.87);
          final hintColor = _fg(isLight, 0.35);
          return AlertDialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Add Event',
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(_displayYear),
                      lastDate: DateTime(_displayYear, 12, 31),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: ColorScheme.dark(primary: accent),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setS(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _fmtDate(selectedDate),
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.sora(fontSize: 13, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Event name',
                    hintStyle: GoogleFonts.sora(
                      fontSize: 13,
                      color: hintColor,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _fg(isLight, 0.18)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: accent),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.sora(color: _fg(isLight, 0.40)),
                ),
              ),
              TextButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  ref.read(userEventsProvider.notifier).add(
                    CalendarEvent(
                      date: selectedDate,
                      name: name,
                      isPublicHoliday: false,
                    ),
                  );
                  Navigator.pop(ctx);
                },
                child: Text(
                  'Save',
                  style: GoogleFonts.sora(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    nameCtrl.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin

    final mq = MediaQuery.of(context);
    final accent = ref.watch(accentColorProvider);
    final isLight = ref.watch(widgetLightModeProvider);
    final isRightHanded = ref.watch(rightHandedProvider);
    final cc = ref.watch(calCountryCodeProvider);
    final userEvents = ref.watch(userEventsProvider);
    final now = DateTime.now();

    final bgColor = isLight ? const Color(0xFFF2F2F2) : Colors.black;

    final holidayDays = _buildDayMap(
      _holidays.where((e) => e.date.year == _displayYear),
    );
    final userEventDays = _buildDayMap(
      userEvents.where((e) => e.date.year == _displayYear),
    );

    // Panel bottom offset: above navBar row + add-widget button + bottom padding
    final panelBottom = mq.padding.bottom + 124.0;
    final panelH = mq.size.height * 0.46;

    return ColoredBox(
      color: bgColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Main column ────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: mq.padding.top + 10),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: RepaintBoundary(
                    child: _YearCalendarGrid(
                      year: _displayYear,
                      today: now,
                      accent: accent,
                      isLight: isLight,
                      holidayDays: holidayDays,
                      userEventDays: userEventDays,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              _YearNavBar(
                year: _displayYear,
                currentYear: now.year,
                accent: accent,
                isLight: isLight,
                isRightHanded: isRightHanded,
                isPanelOpen: _panelOpen,
                onPrev: () {
                  setState(() {
                    _displayYear--;
                    _holidays = [];
                    _holidaysError = null;
                  });
                  _loadHolidaysIfNeeded();
                },
                onNext: () {
                  setState(() {
                    _displayYear++;
                    _holidays = [];
                    _holidaysError = null;
                  });
                  _loadHolidaysIfNeeded();
                },
                onHolidayToggle: () {
                  setState(() => _panelOpen = !_panelOpen);
                  if (_panelOpen) {
                    if (cc == null) {
                      _requestCountryAndLoad();
                    } else {
                      _loadHolidaysIfNeeded();
                    }
                  }
                },
                onTorchToggle: () =>
                    ref.read(widgetLightModeProvider.notifier).toggle(),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _AddWidgetButton(
                  isLight: isLight,
                  accent: accent,
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
          ),

          // ── Holiday panel (slides up above nav bar) ────────────────────
          Positioned(
            left: 14,
            right: 14,
            bottom: panelBottom,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              height: _panelOpen ? panelH : 0,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _fg(isLight, 0.10)),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isLight ? 0.12 : 0.40),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: _panelOpen
                  ? _buildPanelContent(accent, isLight, cc, userEvents)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Panel content ─────────────────────────────────────────────────────────

  Widget _buildPanelContent(
    Color accent,
    bool isLight,
    String? cc,
    List<CalendarEvent> userEvents,
  ) {
    final allHolidays = _holidays
        .where((e) => e.date.year == _displayYear)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final allUserEvents = userEvents
        .where((e) => e.date.year == _displayYear)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final textColor = _fg(isLight, 0.87);
    final subColor = _fg(isLight, 0.45);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 15,
                color: accent.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cc != null
                      ? 'Public Holidays \u00b7 $cc \u00b7 $_displayYear'
                      : 'Select your country',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (_holidaysLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                )
              else if (cc != null)
                GestureDetector(
                  onTap: () => _doLoad(cc, force: true),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: subColor,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: _showCountryPicker,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.public_rounded,
                    size: 16,
                    color: subColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: _fg(isLight, 0.08)),

        // Error banner
        if (_holidaysError != null)
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.red.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 14,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _holidaysError!,
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: Colors.red.shade300,
                    ),
                  ),
                ),
                if (cc != null)
                  GestureDetector(
                    onTap: () => _doLoad(cc, force: true),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // No country set — detect or pick
        if (cc == null && !_holidaysLoading)
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: _requestCountryAndLoad,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Detect country (one-time)',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Scrollable event list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              if (allHolidays.isNotEmpty) ...[
                _sectionLabel('Public Holidays', subColor),
                ...allHolidays.map(
                  (e) => _EventTile(
                    event: e,
                    accent: accent,
                    isLight: isLight,
                    onDelete: null,
                  ),
                ),
              ],
              if (allUserEvents.isNotEmpty) ...[
                _sectionLabel('My Events', subColor),
                ...allUserEvents.map(
                  (e) => _EventTile(
                    event: e,
                    accent: accent,
                    isLight: isLight,
                    onDelete: () =>
                        ref.read(userEventsProvider.notifier).remove(e.id),
                  ),
                ),
              ],
              if (allHolidays.isEmpty &&
                  allUserEvents.isEmpty &&
                  !_holidaysLoading &&
                  _holidaysError == null &&
                  cc != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: Text(
                    'No events for $_displayYear',
                    style: GoogleFonts.sora(fontSize: 12, color: subColor),
                  ),
                ),
            ],
          ),
        ),

        Divider(height: 1, color: _fg(isLight, 0.08)),

        // Add event row
        GestureDetector(
          onTap: _showAddEventDialog,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 15, color: accent),
                const SizedBox(width: 6),
                Text(
                  'Add my event',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label, Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
    child: Text(
      label.toUpperCase(),
      style: GoogleFonts.sora(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 1.2,
      ),
    ),
  );

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Map<int, Set<int>> _buildDayMap(Iterable<CalendarEvent> events) {
    final map = <int, Set<int>>{};
    for (final e in events) {
      map.putIfAbsent(e.date.month, () => {}).add(e.date.day);
    }
    return map;
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _fmtDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';
}

// ── Event tile ────────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.accent,
    required this.isLight,
    required this.onDelete,
  });

  final CalendarEvent event;
  final Color accent;
  final bool isLight;
  final VoidCallback? onDelete;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final dotColor =
        event.isPublicHoliday ? accent : _fg(isLight, 0.70);
    final dateStr = '${_months[event.date.month - 1]} ${event.date.day}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 42,
            child: Text(
              dateStr,
              style: GoogleFonts.sora(
                fontSize: 10,
                color: _fg(isLight, 0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.name,
              style: GoogleFonts.sora(
                fontSize: 11,
                color: _fg(isLight, 0.82),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: _fg(isLight, 0.30),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 3 × 4 year grid ───────────────────────────────────────────────────────────

class _YearCalendarGrid extends StatelessWidget {
  const _YearCalendarGrid({
    required this.year,
    required this.today,
    required this.accent,
    required this.isLight,
    required this.holidayDays,
    required this.userEventDays,
  });

  final int year;
  final DateTime today;
  final Color accent;
  final bool isLight;
  final Map<int, Set<int>> holidayDays;
  final Map<int, Set<int>> userEventDays;

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
                        isLight: isLight,
                        holidayDates:
                            holidayDays[row * 3 + col + 1] ?? const {},
                        userEventDates:
                            userEventDays[row * 3 + col + 1] ?? const {},
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
    required this.isLight,
    required this.holidayDates,
    required this.userEventDates,
  });

  final int month;
  final int year;
  final DateTime today;
  final Color accent;
  final bool isLight;
  final Set<int> holidayDates;
  final Set<int> userEventDates;

  static const _fullNames = [
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
  static const _dow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = year == today.year && month == today.month;

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
        final rowH = (h * daysRatio) / 6;

        final headerColor =
            isCurrentMonth ? accent : _fg(isLight, 0.55);

        final nameFontSize = (nameH * 0.62).clamp(7.0, 11.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Full month name ────────────────────────────────────────────
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
                              fontWeight: FontWeight.w500,
                              color: _fg(isLight, 0.55),
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
                    final isHoliday = valid && holidayDates.contains(dayNum);
                    final isUserEvent =
                        valid && userEventDates.contains(dayNum);
                    final showDot =
                        valid && !isToday && (isHoliday || isUserEvent);

                    return SizedBox(
                      width: cellW,
                      child: Center(
                        child: !valid
                            ? null
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isToday)
                                    _TodayBadge(
                                      day: dayNum,
                                      size: rowH * 0.72,
                                      accent: accent,
                                    )
                                  else
                                    Text(
                                      '$dayNum',
                                      style: GoogleFonts.sora(
                                        fontSize: (rowH * 0.42).clamp(
                                          6.5,
                                          11.0,
                                        ),
                                        fontWeight: FontWeight.w300,
                                        color: _fg(
                                          isLight,
                                          isCurrentMonth ? 0.72 : 0.55,
                                        ),
                                      ),
                                    ),
                                  if (showDot)
                                    Container(
                                      margin:
                                          const EdgeInsets.only(top: 1.0),
                                      width: 2.5,
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isHoliday
                                            ? accent
                                            : _fg(isLight, 0.65),
                                      ),
                                    ),
                                ],
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
        border: Border.all(color: accent.withValues(alpha: 0.75), width: 0.8),
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
    required this.isLight,
    required this.isRightHanded,
    required this.isPanelOpen,
    required this.onPrev,
    required this.onNext,
    required this.onHolidayToggle,
    required this.onTorchToggle,
  });

  final int year;
  final int currentYear;
  final Color accent;
  final bool isLight;
  final bool isRightHanded;
  final bool isPanelOpen;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onHolidayToggle;
  final VoidCallback onTorchToggle;

  @override
  Widget build(BuildContext context) {
    final isNow = year == currentYear;
    final yearColor = isNow
        ? accent.withValues(alpha: 0.85)
        : _fg(isLight, 0.55);

    final actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallButton(
          icon: isLight
              ? Icons.dark_mode_rounded
              : Icons.light_mode_rounded,
          onTap: onTorchToggle,
          isLight: isLight,
          accent: accent,
        ),
        const SizedBox(width: 6),
        _SmallButton(
          icon: isPanelOpen
              ? Icons.keyboard_arrow_down_rounded
              : Icons.keyboard_arrow_up_rounded,
          onTap: onHolidayToggle,
          isLight: isLight,
          accent: accent,
          active: isPanelOpen,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavChevron(
                  icon: Icons.chevron_left_rounded,
                  onTap: onPrev,
                  accent: accent,
                  isLight: isLight,
                ),
                const SizedBox(width: 20),
                Text(
                  '$year',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: yearColor,
                  ),
                ),
                const SizedBox(width: 20),
                _NavChevron(
                  icon: Icons.chevron_right_rounded,
                  onTap: onNext,
                  accent: accent,
                  isLight: isLight,
                ),
              ],
            ),
            Positioned(
              right: isRightHanded ? 0 : null,
              left: isRightHanded ? null : 0,
              child: actionButtons,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavChevron extends StatelessWidget {
  const _NavChevron({
    required this.icon,
    required this.onTap,
    required this.accent,
    required this.isLight,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _fg(isLight, 0.06),
        ),
        child: Icon(icon, size: 17, color: accent.withValues(alpha: 0.65)),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.icon,
    required this.onTap,
    required this.isLight,
    required this.accent,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isLight;
  final Color accent;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? accent.withValues(alpha: 0.15)
              : _fg(isLight, 0.07),
          border: active
              ? Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 0.8,
                )
              : null,
        ),
        child: Icon(
          icon,
          size: 15,
          color: active ? accent : _fg(isLight, 0.60),
        ),
      ),
    );
  }
}

// ── Add Widget button ─────────────────────────────────────────────────────────

class _AddWidgetButton extends StatelessWidget {
  const _AddWidgetButton({
    required this.isLight,
    required this.accent,
    required this.onTap,
  });

  final bool isLight;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _fg(isLight, 0.10)),
          color: _fg(isLight, 0.03),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 15, color: _fg(isLight, 0.30)),
            const SizedBox(width: 8),
            Text(
              'Add Widget',
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
                color: _fg(isLight, 0.30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Country picker dialog ─────────────────────────────────────────────────────

class _CountryPickerDialog extends StatefulWidget {
  const _CountryPickerDialog({required this.accent, required this.isLight});

  final Color accent;
  final bool isLight;

  @override
  State<_CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  static const _allCountries = [
    ('AD', 'Andorra'), ('AO', 'Angola'), ('AR', 'Argentina'),
    ('AT', 'Austria'), ('AU', 'Australia'),
    ('BB', 'Barbados'), ('BE', 'Belgium'), ('BG', 'Bulgaria'),
    ('BO', 'Bolivia'), ('BR', 'Brazil'), ('BS', 'Bahamas'),
    ('BW', 'Botswana'), ('BY', 'Belarus'), ('BZ', 'Belize'),
    ('CA', 'Canada'), ('CH', 'Switzerland'), ('CL', 'Chile'),
    ('CN', 'China'), ('CO', 'Colombia'), ('CR', 'Costa Rica'),
    ('CU', 'Cuba'), ('CY', 'Cyprus'), ('CZ', 'Czech Republic'),
    ('DE', 'Germany'), ('DK', 'Denmark'), ('DO', 'Dominican Republic'),
    ('EC', 'Ecuador'), ('EE', 'Estonia'), ('EG', 'Egypt'),
    ('ES', 'Spain'), ('FI', 'Finland'), ('FR', 'France'),
    ('GA', 'Gabon'), ('GB', 'United Kingdom'), ('GE', 'Georgia'),
    ('GH', 'Ghana'), ('GL', 'Greenland'), ('GR', 'Greece'),
    ('GT', 'Guatemala'), ('HN', 'Honduras'), ('HR', 'Croatia'),
    ('HU', 'Hungary'), ('ID', 'Indonesia'), ('IE', 'Ireland'),
    ('IL', 'Israel'), ('IN', 'India'), ('IS', 'Iceland'),
    ('IT', 'Italy'), ('JM', 'Jamaica'), ('JP', 'Japan'),
    ('KE', 'Kenya'), ('KR', 'South Korea'), ('LI', 'Liechtenstein'),
    ('LS', 'Lesotho'), ('LT', 'Lithuania'), ('LU', 'Luxembourg'),
    ('LV', 'Latvia'), ('MA', 'Morocco'), ('MC', 'Monaco'),
    ('MD', 'Moldova'), ('ME', 'Montenegro'), ('MK', 'North Macedonia'),
    ('MT', 'Malta'), ('MX', 'Mexico'), ('MZ', 'Mozambique'),
    ('NA', 'Namibia'), ('NG', 'Nigeria'), ('NI', 'Nicaragua'),
    ('NL', 'Netherlands'), ('NO', 'Norway'), ('NZ', 'New Zealand'),
    ('PA', 'Panama'), ('PE', 'Peru'), ('PH', 'Philippines'),
    ('PL', 'Poland'), ('PT', 'Portugal'), ('PY', 'Paraguay'),
    ('RO', 'Romania'), ('RS', 'Serbia'), ('RU', 'Russia'),
    ('SE', 'Sweden'), ('SI', 'Slovenia'), ('SK', 'Slovakia'),
    ('SM', 'San Marino'), ('SN', 'Senegal'), ('SV', 'El Salvador'),
    ('TN', 'Tunisia'), ('TR', 'Turkey'), ('UA', 'Ukraine'),
    ('US', 'United States'), ('UY', 'Uruguay'), ('VA', 'Vatican City'),
    ('VE', 'Venezuela'), ('ZA', 'South Africa'), ('ZW', 'Zimbabwe'),
  ];

  String _filter = '';

  List<(String, String)> get _filtered => _filter.isEmpty
      ? _allCountries
      : _allCountries
            .where(
              (c) =>
                  c.$2.toLowerCase().contains(_filter.toLowerCase()) ||
                  c.$1.toLowerCase().contains(_filter.toLowerCase()),
            )
            .toList();

  @override
  Widget build(BuildContext context) {
    final bg = widget.isLight ? Colors.white : const Color(0xFF1E1E1E);
    final textColor = _fg(widget.isLight, 0.87);
    final subColor = _fg(widget.isLight, 0.45);

    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Select Country',
        style: GoogleFonts.sora(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: GoogleFonts.sora(fontSize: 13, color: textColor),
              decoration: InputDecoration(
                hintText: 'Search\u2026',
                hintStyle: GoogleFonts.sora(fontSize: 13, color: subColor),
                prefixIcon:
                    Icon(Icons.search_rounded, size: 18, color: subColor),
                isDense: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _fg(widget.isLight, 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.accent),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final (code, name) = _filtered[i];
                  return InkWell(
                    onTap: () => Navigator.pop(context, code),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              code,
                              style: GoogleFonts.sora(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: widget.accent.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.sora(color: _fg(widget.isLight, 0.40)),
          ),
        ),
      ],
    );
  }
}
