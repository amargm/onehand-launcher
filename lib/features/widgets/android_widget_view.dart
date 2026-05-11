import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Embeds an Android app widget identified by [appWidgetId].
///
/// The [width] and [height] values (in logical pixels) are passed as creation
/// params so the native side can size the AppWidgetHostView correctly.
class AndroidWidgetView extends StatelessWidget {
  const AndroidWidgetView({
    super.key,
    required this.appWidgetId,
    required this.width,
    required this.height,
  });

  final int appWidgetId;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: AndroidView(
        viewType: 'appwidget_view',
        layoutDirection: TextDirection.ltr,
        creationParams: <String, dynamic>{
          'appWidgetId': appWidgetId,
          // Pass dp values — the native side converts using its own density.
          'widthDp': width.toInt(),
          'heightDp': height.toInt(),
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
