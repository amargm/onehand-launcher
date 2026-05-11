package com.onehand.onehand_launcher

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetHostView
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Build
import java.io.ByteArrayOutputStream

/**
 * Manages the lifecycle of hosted Android app widgets.
 *
 * HOST_ID is an arbitrary stable integer — must never change between app
 * launches so that previously allocated appWidgetIds remain valid.
 */
class AppWidgetHostManager(private val context: Context) {

    companion object {
        const val HOST_ID = 1026
    }

    val host: AppWidgetHost = AppWidgetHost(context, HOST_ID)
    private val manager: AppWidgetManager = AppWidgetManager.getInstance(context)

    // ── Lifecycle ─────────────────────────────────────────────────────────

    fun startListening() = host.startListening()
    fun stopListening()  = host.stopListening()

    // ── Widget discovery ──────────────────────────────────────────────────

    /**
     * Returns metadata for every installed widget provider.
     * Preview image is encoded as PNG bytes (128 px) if available.
     */
    fun getAvailableWidgets(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val providers: List<AppWidgetProviderInfo> =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                manager.getInstalledProvidersForProfile(
                    android.os.Process.myUserHandle()
                )
            } else {
                @Suppress("DEPRECATION")
                manager.installedProviders
            }

        return providers.mapNotNull { info ->
            try {
                val label = info.loadLabel(pm) ?: return@mapNotNull null
                val pkg   = info.provider.packageName
                val cls   = info.provider.className

                val previewBytes: ByteArray? = try {
                    if (info.previewImage != 0) {
                        val drawable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            pm.getDrawable(pkg, info.previewImage, null)
                        } else {
                            @Suppress("DEPRECATION")
                            pm.getDrawable(pkg, info.previewImage, null)
                        }
                        drawable?.toBytes(128)
                    } else {
                        // Fall back to app icon
                        pm.getApplicationIcon(pkg).toBytes(64)
                    }
                } catch (_: Exception) { null }

                mapOf(
                    "label"     to label,
                    "pkg"       to pkg,
                    "cls"       to cls,
                    "preview"   to previewBytes,
                    "minWidth"  to info.minWidth,
                    "minHeight" to info.minHeight,
                )
            } catch (_: Exception) { null }
        }.sortedBy { (it["label"] as? String)?.lowercase() ?: "" }
    }

    // ── Widget bind ───────────────────────────────────────────────────────

    /**
     * Allocates a new appWidgetId and attempts to bind it to the given
     * provider without user interaction.
     *
     * Returns the allocated appWidgetId (>= 0) on success.
     * Returns -1 if the bind was refused (permission not yet granted) — the
     * caller must then launch ACTION_APPWIDGET_BIND intent to prompt the user.
     */
    fun allocateAndBind(pkg: String, cls: String): Int {
        val appWidgetId = host.allocateAppWidgetId()
        val provider = android.content.ComponentName(pkg, cls)
        val bound = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            manager.bindAppWidgetIdIfAllowed(appWidgetId, provider)
        } else {
            false
        }
        return if (bound) appWidgetId else {
            // Return the allocated id so the caller can pass it to the
            // bind-permission intent; it will be freed on failure.
            -appWidgetId  // negative signals "needs permission, use abs() as id"
        }
    }

    /** Release a previously allocated appWidgetId. */
    fun deleteWidget(appWidgetId: Int) {
        try { host.deleteAppWidgetId(appWidgetId) } catch (_: Exception) {}
    }

    // ── View factory ──────────────────────────────────────────────────────

    /**
     * Creates and returns an [AppWidgetHostView] for the given id.
     * Must be called on the main thread.
     */
    fun createHostView(appWidgetId: Int, widthDp: Int, heightDp: Int): AppWidgetHostView {
        val view = host.createView(context, appWidgetId,
            manager.getAppWidgetInfo(appWidgetId)) as AppWidgetHostView
        val density = context.resources.displayMetrics.density
        val w = (widthDp * density).toInt()
        val h = (heightDp * density).toInt()
        view.setAppWidget(appWidgetId, manager.getAppWidgetInfo(appWidgetId))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            view.updateAppWidgetSize(android.os.Bundle(), listOf(
                android.util.SizeF(widthDp.toFloat(), heightDp.toFloat())
            ))
        } else {
            @Suppress("DEPRECATION")
            view.updateAppWidgetSize(android.os.Bundle(), widthDp, heightDp, widthDp, heightDp)
        }
        view.measure(
            android.view.View.MeasureSpec.makeMeasureSpec(w, android.view.View.MeasureSpec.EXACTLY),
            android.view.View.MeasureSpec.makeMeasureSpec(h, android.view.View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, w, h)
        return view
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private fun Drawable.toBytes(sizePx: Int): ByteArray {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        setBounds(0, 0, sizePx, sizePx)
        draw(canvas)
        return ByteArrayOutputStream().also { out ->
            bmp.compress(Bitmap.CompressFormat.PNG, 85, out)
        }.toByteArray()
    }
}
