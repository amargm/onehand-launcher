import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/placed_android_widget.dart';
import '../../core/providers/app_widgets_provider.dart';
import '../../core/services/app_widget_service.dart';

/// Shows a bottom sheet that lets the user pick an Android app widget to add.
///
/// On selection the widget is bound and – if successful – added to the
/// [placedAndroidWidgetsProvider].
Future<void> showAndroidWidgetPicker(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _WidgetPickerSheet(),
  );
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _WidgetPickerSheet extends ConsumerStatefulWidget {
  const _WidgetPickerSheet();

  @override
  ConsumerState<_WidgetPickerSheet> createState() => _WidgetPickerSheetState();
}

class _WidgetPickerSheetState extends ConsumerState<_WidgetPickerSheet> {
  List<AvailableAppWidget>? _widgets;
  String? _error;
  bool _loading = true;
  int? _binding; // appWidgetId currently being bound

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await getAvailableWidgets();
      if (mounted) setState(() { _widgets = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pick(AvailableAppWidget aw) async {
    if (_binding != null) return;
    setState(() => _binding = -1);
    try {
      final id = await bindWidget(aw.pkg, aw.cls);
      if (!mounted) return;
      if (id >= 0) {
        ref.read(placedAndroidWidgetsProvider.notifier).add(
              PlacedAndroidWidget(
                appWidgetId: id,
                pkg: aw.pkg,
                cls: aw.cls,
                label: aw.label,
                minWidth: aw.minWidth,
                minHeight: aw.minHeight,
              ),
            );
        Navigator.of(context).pop();
      } else {
        // Bind permission dialog was shown by native side; close picker and
        // tell the user to retry.
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Grant the widget permission, then add the widget again.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _binding = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add widget: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Add App Widget',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody(controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController sc) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load widgets:\n$_error',
              textAlign: TextAlign.center),
        ),
      );
    }
    final widgets = _widgets ?? [];
    if (widgets.isEmpty) {
      return const Center(child: Text('No widgets found'));
    }
    return ListView.separated(
      controller: sc,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widgets.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) => _WidgetTile(
        widget: widgets[i],
        busy: _binding != null,
        onTap: () => _pick(widgets[i]),
      ),
    );
  }
}

// ── Single tile ───────────────────────────────────────────────────────────────

class _WidgetTile extends StatelessWidget {
  const _WidgetTile({
    required this.widget,
    required this.busy,
    required this.onTap,
  });

  final AvailableAppWidget widget;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: busy ? null : onTap,
      leading: _Preview(preview: widget.preview),
      title: Text(
        widget.label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        widget.pkg,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Text(
        '${widget.minWidth}×${widget.minHeight}',
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({this.preview});
  final Uint8List? preview;

  @override
  Widget build(BuildContext context) {
    if (preview != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(preview!, width: 48, height: 48, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.widgets_outlined),
    );
  }
}
