package com.onehand.onehand_launcher

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.TextView
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
        } catch (_: Exception) {
            unavailableWidgetView(context)
        }
    } else {
        unavailableWidgetView(context)
    }

    override fun getView(): View = view

    override fun dispose() {
        // AppWidgetHostView cleanup is handled by AppWidgetHostManager.deleteWidget()
        // called from the Flutter side before this view is disposed.
    }
}

private fun unavailableWidgetView(context: Context): View {
    val density = context.resources.displayMetrics.density
    val message = TextView(context).apply {
        text = "Widget unavailable\nRemove it and add it again"
        contentDescription = "App widget unavailable. Remove it and add it again."
        setTextColor(Color.WHITE)
        setTextSize(12f)
        gravity = Gravity.CENTER
        setPadding(
            (12 * density).toInt(),
            (12 * density).toInt(),
            (12 * density).toInt(),
            (12 * density).toInt(),
        )
    }

    return FrameLayout(context).apply {
        setBackgroundColor(Color.rgb(38, 38, 42))
        importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES
        addView(
            message,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
    }
}
