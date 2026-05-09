package com.onehand.onehand_launcher

import android.app.WallpaperManager
import android.app.role.RoleManager
import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothHeadset
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private val appsChannel      = "com.onehand.onehand_launcher/apps"
    private val launcherChannel  = "com.onehand.onehand_launcher/launcher"
    private val headphoneChannel = "com.onehand.onehand_launcher/headphone_events"

    // Off-main-thread executor for icon-loading operations.
    private val executor = Executors.newCachedThreadPool()

    // Handler for posting delayed Bluetooth disconnect checks.
    private val mainHandler = Handler(Looper.getMainLooper())

    // EventChannel sink — null when Flutter is not listening.
    private var headphoneEventSink: EventChannel.EventSink? = null

    // Fires on wired plug/unplug and BT A2DP / SCO connect/disconnect.
    //
    // BT events carry the new profile state in EXTRA_STATE:
    //   STATE_CONNECTED (2)    → push true immediately (AudioManager already updated).
    //   STATE_DISCONNECTED (0) → delay 300 ms so AudioManager finishes removing the
    //                            device before we query it.
    //   CONNECTING / DISCONNECTING → ignored; wait for the final state.
    // Wired events always call isHeadphoneConnected() directly (instant).
    private val audioReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED,
                BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED -> {
                    val state = intent.getIntExtra(
                        BluetoothProfile.EXTRA_STATE,
                        BluetoothProfile.STATE_DISCONNECTED,
                    )
                    when (state) {
                        BluetoothProfile.STATE_CONNECTED -> {
                            headphoneEventSink?.success(true)
                        }
                        BluetoothProfile.STATE_DISCONNECTED -> {
                            // AudioManager can lag on BT disconnect — wait briefly.
                            mainHandler.postDelayed({
                                headphoneEventSink?.success(isHeadphoneConnected())
                            }, 300L)
                        }
                        // CONNECTING / DISCONNECTING → wait for final state.
                    }
                }
                else -> headphoneEventSink?.success(isHeadphoneConnected())
            }
        }
    }

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
    }

    // ── Receiver lifecycle ───────────────────────────────────────────────────
    // Register when the activity is foregrounded; unregister on pause.
    // This means no wakeups while the launcher is behind another app.
    override fun onResume() {
        super.onResume()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_HEADSET_PLUG)                        // wired
            addAction(BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED)     // BT stereo
            addAction(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)  // BT mono/SCO
        }
        registerReceiver(audioReceiver, filter)
        // Sync state in case it changed while we were paused.
        headphoneEventSink?.success(isHeadphoneConnected())
    }

    override fun onPause() {
        super.onPause()
        try { unregisterReceiver(audioReceiver) } catch (_: Exception) {}
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
