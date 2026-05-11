package com.onehand.onehand_launcher

import android.content.Context
import android.view.View
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Registers the "appwidget_view" PlatformView type.
 * Creation params (from Flutter):
 *   { "appWidgetId": Int, "widthDp": Int, "heightDp": Int }
 */
class AppWidgetViewFactory(
    private val hostManager: AppWidgetHostManager,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any> ?: emptyMap()
        val appWidgetId = (params["appWidgetId"] as? Int) ?: -1
        val widthDp     = (params["widthDp"]     as? Int) ?: 320
        val heightDp    = (params["heightDp"]    as? Int) ?: 160

        return AppWidgetPlatformView(context, hostManager, appWidgetId, widthDp, heightDp)
    }
}

private class AppWidgetPlatformView(
    context: Context,
    hostManager: AppWidgetHostManager,
    appWidgetId: Int,
    widthDp: Int,
    heightDp: Int,
) : PlatformView {

    private val view: View = if (appWidgetId >= 0) {
        try {
            hostManager.createHostView(appWidgetId, widthDp, heightDp)
        } catch (e: Exception) {
            // If the widget host view fails (widget removed / provider gone),
            // return an empty transparent view rather than crashing.
            android.widget.FrameLayout(context)
        }
    } else {
        android.widget.FrameLayout(context)
    }

    override fun getView(): View = view

    override fun dispose() {
        // AppWidgetHostView cleanup is handled by AppWidgetHostManager.deleteWidget()
        // called from the Flutter side before this view is disposed.
    }
}
