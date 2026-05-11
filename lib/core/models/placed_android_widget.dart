import 'dart:convert';

/// Represents a widget slot that the user has pinned to the Widgets screen.
class PlacedAndroidWidget {
  final int appWidgetId;
  final String pkg;
  final String cls;
  final String label;
  final int minWidth;
  final int minHeight;

  const PlacedAndroidWidget({
    required this.appWidgetId,
    required this.pkg,
    required this.cls,
    required this.label,
    required this.minWidth,
    required this.minHeight,
  });

  Map<String, dynamic> toJson() => {
        'appWidgetId': appWidgetId,
        'pkg': pkg,
        'cls': cls,
        'label': label,
        'minWidth': minWidth,
        'minHeight': minHeight,
      };

  factory PlacedAndroidWidget.fromJson(Map<String, dynamic> j) =>
      PlacedAndroidWidget(
        appWidgetId: (j['appWidgetId'] as num).toInt(),
        pkg: j['pkg'] as String,
        cls: j['cls'] as String,
        label: j['label'] as String,
        minWidth: (j['minWidth'] as num? ?? 320).toInt(),
        minHeight: (j['minHeight'] as num? ?? 160).toInt(),
      );

  /// Encodes a list for SharedPreferences storage.
  static String encodeList(List<PlacedAndroidWidget> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  /// Decodes a list from SharedPreferences storage.
  static List<PlacedAndroidWidget> decodeList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => PlacedAndroidWidget.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
