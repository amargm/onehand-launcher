import 'package:flutter/services.dart';

const _channel = MethodChannel('com.onehand.onehand_launcher/appwidgets');

/// Metadata returned from the native side for an available widget provider.
class AvailableAppWidget {
  final String label;
  final String pkg;
  final String cls;
  final Uint8List? preview;
  final int minWidth;
  final int minHeight;

  const AvailableAppWidget({
    required this.label,
    required this.pkg,
    required this.cls,
    this.preview,
    required this.minWidth,
    required this.minHeight,
  });

  factory AvailableAppWidget.fromMap(Map<Object?, Object?> m) =>
      AvailableAppWidget(
        label: m['label'] as String? ?? '',
        pkg: m['pkg'] as String? ?? '',
        cls: m['cls'] as String? ?? '',
        preview: m['preview'] as Uint8List?,
        minWidth: (m['minWidth'] as num? ?? 320).toInt(),
        minHeight: (m['minHeight'] as num? ?? 160).toInt(),
      );
}

/// Returns all widget providers installed on the device.
Future<List<AvailableAppWidget>> getAvailableWidgets() async {
  final raw =
      await _channel.invokeListMethod<Map<Object?, Object?>>('getAvailableWidgets');
  return (raw ?? []).map(AvailableAppWidget.fromMap).toList();
}

/// Attempts to bind [pkg]/[cls] as a new widget.
///
/// Returns the allocated `appWidgetId` on success (>= 0).
/// Returns a large negative value if the bind permission prompt was launched;
/// the user will see a system dialog and the widget should be re-added after.
Future<int> bindWidget(String pkg, String cls) async {
  final id = await _channel.invokeMethod<int>('bindWidget', {
    'pkg': pkg,
    'cls': cls,
  });
  return id ?? -1;
}

/// Releases the [appWidgetId] and frees its resources.
Future<void> deleteWidget(int appWidgetId) async {
  await _channel.invokeMethod<void>('deleteWidget', {
    'appWidgetId': appWidgetId,
  });
}
