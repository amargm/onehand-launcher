package com.onehand.onehand_launcher

import android.app.WallpaperManager
import android.app.role.RoleManager
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.HapticFeedbackConstants
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private val appsChannel        = "com.onehand.onehand_launcher/apps"
    private val launcherChannel    = "com.onehand.onehand_launcher/launcher"
    private val headphoneChannel   = "com.onehand.onehand_launcher/headphone_events"
    private val packageChannel     = "com.onehand.onehand_launcher/package_events"
    private val appWidgetsChannel  = "com.onehand.onehand_launcher/appwidgets"

    // AppWidget host — lazily initialised in configureFlutterEngine
    private lateinit var appWidgetHostManager: AppWidgetHostManager

    // Request code for the BIND_APPWIDGET permission intent
    private val REQUEST_BIND_APPWIDGET = 1027

    // Off-main-thread executor for icon-loading operations.
    private val executor = Executors.newCachedThreadPool()

    // Handler for posting delayed Bluetooth disconnect checks.
    private val mainHandler = Handler(Looper.getMainLooper())

    // EventChannel sink — null when Flutter is not listening.
    private var headphoneEventSink: EventChannel.EventSink? = null

    // EventChannel sink for package install/remove events.
    private var packageEventSink: EventChannel.EventSink? = null

    // Fires when a package is installed, removed, or replaced.
    // Sends "ACTION:packageName" so Flutter can distinguish uninstalls from
    // updates and skip the removal toast for app-update events.
    // ACTION_PACKAGE_* intents require addDataScheme("package") to fire.
    private val packageReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val pkg = intent.data?.schemeSpecificPart ?: return
            val prefix = when (intent.action) {
                Intent.ACTION_PACKAGE_REMOVED -> {
                    // EXTRA_REPLACING=true means the package is being updated,
                    // not fully uninstalled — treat as CHANGED, not REMOVED.
                    val replacing = intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)
                    if (replacing) "CHANGED:" else "REMOVED:"
                }
                Intent.ACTION_PACKAGE_ADDED -> "ADDED:"
                else -> "CHANGED:"
            }
            packageEventSink?.success("$prefix$pkg")
        }
    }

    // Detects ALL audio device changes — wired, USB-C, and Bluetooth A2DP/SCO —
    // without requiring BLUETOOTH_CONNECT or any other Bluetooth permission.
    // On Android 12+ the old BroadcastReceiver approach
    // (BluetoothA2dp/HeadsetProfile ACTION_CONNECTION_STATE_CHANGED) is silently
    // dropped unless the app holds BLUETOOTH_CONNECT at runtime.
    // AudioDeviceCallback (API 23+) has no such restriction.
    private var audioDeviceCallback: AudioDeviceCallback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Apps channel ──────────────────────────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            appsChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    // Run on background thread: querying PackageManager and
                    // PNG-compressing 100+ icons blocks the main thread.
                    executor.execute {
                        try {
                            val apps = getInstalledApps()
                            runOnUiThread { result.success(apps) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "openApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        try {
                            openApp(pkg)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARG", "packageName is null", null)
                    }
                }
                "getMediaApps" -> {
                    executor.execute {
                        try {
                            val apps = getMediaApps()
                            runOnUiThread { result.success(apps) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "uninstallApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        startActivity(
                            Intent(Intent.ACTION_DELETE, Uri.parse("package:$pkg"))
                        )
                        result.success(null)
                    } else {
                        result.error("INVALID_ARG", "packageName is null", null)
                    }
                }
                "setWallpaper" -> {
                    // Bytes come from Dart (downloaded via http package).
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes != null) {
                        executor.execute {
                            try {
                                val wm = WallpaperManager.getInstance(applicationContext)
                                wm.setStream(bytes.inputStream())
                                runOnUiThread { result.success(null) }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("WALLPAPER_FAILED", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARG", "bytes is null", null)
                    }
                }
                "openBrowserSearch" -> {
                    // Fire ACTION_WEB_SEARCH with an empty query so the default
                    // browser (or search app) opens with its search bar focused
                    // and the keyboard raised.
                    try {
                        val intent = Intent(Intent.ACTION_WEB_SEARCH).apply {
                            putExtra(android.app.SearchManager.QUERY, "")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        if (intent.resolveActivity(packageManager) != null) {
                            startActivity(intent)
                        } else {
                            // Fallback: open the default browser's homepage
                            startActivity(
                                Intent(Intent.ACTION_VIEW, android.net.Uri.parse("https://www.google.com"))
                                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            )
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("OPEN_FAILED", e.message, null)
                    }
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        try {
                            startActivity(
                                Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url))
                                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            )
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARG", "url is null", null)
                    }
                }
                "forceHaptic" -> {
                    // Bypass silent / DND / vibrate-only system settings.
                    // FLAG_IGNORE_GLOBAL_SETTING forces the feedback regardless
                    // of the device's current sound/vibration profile.
                    try {
                        window.decorView.performHapticFeedback(
                            HapticFeedbackConstants.VIRTUAL_KEY,
                            HapticFeedbackConstants.FLAG_IGNORE_GLOBAL_SETTING,
                        )
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("HAPTIC_FAILED", e.message, null)
                    }
                }
                "openAppInfo" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        try {
                            startActivity(
                                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                    .setData(Uri.parse("package:$pkg"))
                                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            )
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARG", "packageName is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // ── Launcher channel ──────────────────────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            launcherChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDefaultLauncher" -> result.success(isDefaultLauncher())
                "requestDefaultLauncher" -> {
                    requestDefaultLauncher()
                    result.success(null)
                }
                "isHeadphoneConnected" -> result.success(isHeadphoneConnected())
                else -> result.notImplemented()
            }
        }

        // ── Headphone event channel ──────────────────────────────────────────
        // Dart subscribes once; we push true/false whenever the
        // BroadcastReceiver fires. Initial value sent in onListen so
        // Flutter gets current state without waiting for first event.
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            headphoneChannel,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                headphoneEventSink = sink
                // Push current state immediately.
                sink.success(isHeadphoneConnected())
            }
            override fun onCancel(arguments: Any?) {
                headphoneEventSink = null
            }
        })

        // ── Package change event channel ─────────────────────────────────────
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            packageChannel,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                packageEventSink = sink
            }
            override fun onCancel(arguments: Any?) {
                packageEventSink = null
            }
        })

        // ── AppWidget channel ─────────────────────────────────────────────────
        appWidgetHostManager = AppWidgetHostManager(applicationContext)

        // Register the PlatformView factory so Flutter can embed host views
        flutterEngine.platformViewsController.registry
            .registerViewFactory(
                "appwidget_view",
                AppWidgetViewFactory(appWidgetHostManager),
            )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            appWidgetsChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "getAvailableWidgets" -> {
                    executor.execute {
                        try {
                            val widgets = appWidgetHostManager.getAvailableWidgets()
                            runOnUiThread { result.success(widgets) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("ERROR", e.message, null) }
                        }
                    }
                }

                "bindWidget" -> {
                    val pkg = call.argument<String>("pkg") ?: run {
                        result.error("INVALID_ARG", "pkg is null", null); return@setMethodCallHandler
                    }
                    val cls = call.argument<String>("cls") ?: run {
                        result.error("INVALID_ARG", "cls is null", null); return@setMethodCallHandler
                    }
                    val rawId = appWidgetHostManager.allocateAndBind(pkg, cls)
                    if (rawId >= 0) {
                        // Bound successfully — check if widget needs configuration
                        val info = AppWidgetManager.getInstance(applicationContext)
                            .getAppWidgetInfo(rawId)
                        if (info?.configure != null) {
                            // Launch configure activity; Flutter will get id via
                            // onActivityResult forwarded through the channel
                            val configIntent = Intent(AppWidgetManager.ACTION_APPWIDGET_CONFIGURE).apply {
                                component = info.configure
                                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, rawId)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivityForResult(configIntent, rawId)
                        }
                        result.success(rawId)
                    } else {
                        // Need permission — fire the bind intent
                        val needsPermId = -rawId
                        val bindIntent = Intent(AppWidgetManager.ACTION_APPWIDGET_BIND).apply {
                            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, needsPermId)
                            putExtra(AppWidgetManager.EXTRA_APPWIDGET_PROVIDER,
                                ComponentName(pkg, cls))
                        }
                        startActivityForResult(bindIntent, REQUEST_BIND_APPWIDGET)
                        // Return the pending id so Flutter can track it
                        result.success(-needsPermId - 100000) // sentinel: negative large
                    }
                }

                "deleteWidget" -> {
                    val id = call.argument<Int>("appWidgetId") ?: run {
                        result.error("INVALID_ARG", "appWidgetId is null", null); return@setMethodCallHandler
                    }
                    appWidgetHostManager.deleteWidget(id)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    // ── Receiver / callback lifecycle ────────────────────────────────────────
    // packageReceiver: onStart/onStop — stays registered during brief overlaps
    //   such as the system uninstall dialog so ACTION_PACKAGE_REMOVED is never
    //   missed even when the launcher is temporarily backgrounded by that dialog.
    // audioDeviceCallback: onResume/onPause — only needed while launcher is
    //   visible; current state is synced on every resume.

    override fun onStart() {
        super.onStart()
        if (::appWidgetHostManager.isInitialized) appWidgetHostManager.startListening()
        val pkgFilter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addDataScheme("package")
        }
        registerReceiver(packageReceiver, pkgFilter)
    }

    override fun onStop() {
        super.onStop()
        if (::appWidgetHostManager.isInitialized) appWidgetHostManager.stopListening()
        try { unregisterReceiver(packageReceiver) } catch (_: Exception) {}
    }

    override fun onResume() {
        super.onResume()
        // Register AudioDeviceCallback for real-time headphone/BT detection.
        // Covers wired, USB-C, Bluetooth A2DP and SCO — no permissions needed.
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioDeviceCallback = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(addedDevices: Array<AudioDeviceInfo>) {
                headphoneEventSink?.success(isHeadphoneConnected())
            }
            override fun onAudioDevicesRemoved(removedDevices: Array<AudioDeviceInfo>) {
                // Small delay: AudioManager may not have finalised the removal yet.
                mainHandler.postDelayed({
                    headphoneEventSink?.success(isHeadphoneConnected())
                }, 300L)
            }
        }
        am.registerAudioDeviceCallback(audioDeviceCallback, mainHandler)
        // Push current state in case it changed while we were paused.
        headphoneEventSink?.success(isHeadphoneConnected())
    }

    override fun onPause() {
        super.onPause()
        mainHandler.removeCallbacksAndMessages(null)
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioDeviceCallback?.let { am.unregisterAudioDeviceCallback(it) }
        audioDeviceCallback = null
    }

    // ── App list ───────────────────────────────────────────────────────────
    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        @Suppress("DEPRECATION")
        val activities = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(
                intent,
                PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_ALL.toLong()),
            )
        } else {
            pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)
        }

        return activities
            .filter { it.activityInfo.packageName != packageName }
            .map { info ->
                val icon = try { info.loadIcon(pm) } catch (_: Exception) { null }
                mapOf(
                    "packageName" to info.activityInfo.packageName,
                    "appName"     to info.loadLabel(pm).toString(),
                    "icon"        to icon?.toBytes(),
                )
            }
            .sortedBy { (it["appName"] as String).lowercase() }
    }

    private fun openApp(packageName: String) {
        val intent = packageManager.getLaunchIntentForPackage(packageName) ?: return
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    // ── Default launcher ───────────────────────────────────────────────────
    private fun isDefaultLauncher(): Boolean {
        val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        @Suppress("DEPRECATION")
        val resolveInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.resolveActivity(
                homeIntent,
                PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_DEFAULT_ONLY.toLong()),
            )
        } else {
            packageManager.resolveActivity(homeIntent, PackageManager.MATCH_DEFAULT_ONLY)
        }
        return resolveInfo?.activityInfo?.packageName == packageName
    }

    private fun requestDefaultLauncher() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ — in-app role request dialog
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_HOME)
                && !roleManager.isRoleHeld(RoleManager.ROLE_HOME)
            ) {
                startActivityForResult(
                    roleManager.createRequestRoleIntent(RoleManager.ROLE_HOME),
                    REQUEST_CODE_SET_DEFAULT_HOME,
                )
                return
            }
        }
        // Android 8-9 — open system home-app settings page
        try {
            startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
        } catch (_: Exception) {
            // Fallback: show the generic app-chooser
            startActivity(
                Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                },
            )
        }
    }

    // ── Headphone / audio-out detection ────────────────────────────────────
    //
    // Covers:
    //   TYPE_WIRED_HEADPHONES  — 3.5 mm headphones (no mic)
    //   TYPE_WIRED_HEADSET     — 3.5 mm headset (with mic)
    //   TYPE_USB_HEADSET       — USB-C headset (API 26)
    //   TYPE_USB_DEVICE        — generic USB audio device (API 23)
    //   TYPE_USB_ACCESSORY     — USB audio accessory (API 23)
    //   TYPE_BLUETOOTH_A2DP    — BT stereo (music)
    //   TYPE_BLUETOOTH_SCO     — BT mono (calls / headsets)
    private fun isHeadphoneConnected(): Boolean {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.getDevices(AudioManager.GET_DEVICES_OUTPUTS).any { device ->
                device.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                device.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                device.type == AudioDeviceInfo.TYPE_USB_HEADSET ||
                device.type == AudioDeviceInfo.TYPE_USB_DEVICE ||
                device.type == AudioDeviceInfo.TYPE_USB_ACCESSORY ||
                device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
            }
        } else {
            @Suppress("DEPRECATION")
            am.isWiredHeadsetOn || am.isBluetoothA2dpOn
        }
    }

    // ── Media apps (music / audio players) ────────────────────────────────
    private fun getMediaApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val seen = mutableSetOf<String>()
        val apps = mutableListOf<Map<String, Any?>>()

        fun queryAndAdd(intent: android.content.Intent) {
            try {
                val list = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.queryIntentActivities(
                        intent,
                        PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_ALL.toLong()),
                    )
                } else {
                    @Suppress("DEPRECATION")
                    pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)
                }
                for (info in list) {
                    val pkg = info.activityInfo.packageName
                    if (pkg != packageName && seen.add(pkg)) {
                        val icon = try { info.loadIcon(pm) } catch (_: Exception) { null }
                        apps.add(mapOf(
                            "packageName" to pkg,
                            "appName"     to info.loadLabel(pm).toString(),
                            "icon"        to icon?.toBytes(),
                        ))
                    }
                }
            } catch (_: Exception) { /* ignore individual query failures */ }
        }

        // 1. Apps registered as music players
        queryAndAdd(android.content.Intent(android.content.Intent.ACTION_MAIN).apply {
            addCategory(android.content.Intent.CATEGORY_APP_MUSIC)
        })
        // 2. Apps that can open audio files
        queryAndAdd(android.content.Intent(android.content.Intent.ACTION_VIEW).apply {
            type = "audio/*"
        })

        return apps.take(8)
    }

    // ── Helpers ────────────────────────────────────────────────────────────
    /**
     * Renders this Drawable into a 64×64 px PNG byte array.
     *
     * 64 px matches the largest icon display size in the UI (56 dp) while
     * keeping data volume small — avoids sending 192×192 adaptive-icon bitmaps
     * (which would be ~150 KB each) across the platform channel.
     */
    private fun Drawable.toBytes(sizePx: Int = 64): ByteArray {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        setBounds(0, 0, sizePx, sizePx)
        draw(canvas)
        return ByteArrayOutputStream().also { out ->
            bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        }.toByteArray()
    }

    companion object {
        private const val REQUEST_CODE_SET_DEFAULT_HOME = 1001
    }
}
