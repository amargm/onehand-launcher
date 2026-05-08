package com.onehand.onehand_launcher

import android.app.role.RoleManager
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    private val appsChannel   = "com.onehand.onehand_launcher/apps"
    private val launcherChannel = "com.onehand.onehand_launcher/launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Apps channel ──────────────────────────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            appsChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        result.success(getInstalledApps())
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "openApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        openApp(pkg)
                        result.success(null)
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
                else -> result.notImplemented()
            }
        }
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

    // ── Helpers ────────────────────────────────────────────────────────────
    private fun Drawable.toBytes(): ByteArray {
        val bitmap = if (this is BitmapDrawable) {
            this.bitmap
        } else {
            val bmp = Bitmap.createBitmap(
                intrinsicWidth.coerceAtLeast(1),
                intrinsicHeight.coerceAtLeast(1),
                Bitmap.Config.ARGB_8888,
            )
            val canvas = Canvas(bmp)
            setBounds(0, 0, canvas.width, canvas.height)
            draw(canvas)
            bmp
        }
        return ByteArrayOutputStream().also {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }.toByteArray()
    }

    companion object {
        private const val REQUEST_CODE_SET_DEFAULT_HOME = 1001
    }
}


class MainActivity : FlutterActivity() {

    private val channel = "com.onehand.onehand_launcher/apps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        result.success(getInstalledApps())
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "openApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        openApp(pkg)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARG", "packageName is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        @Suppress("DEPRECATION")
        val activities = pm.queryIntentActivities(intent, 0)

        return activities
            .filter { it.activityInfo.packageName != packageName }
            .map { info ->
                val icon = try { info.loadIcon(pm) } catch (_: Exception) { null }
                mapOf(
                    "packageName" to info.activityInfo.packageName,
                    "appName" to info.loadLabel(pm).toString(),
                    "icon" to icon?.toBytes(),
                )
            }
            .sortedBy { (it["appName"] as String).lowercase() }
    }

    private fun openApp(packageName: String) {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
            ?: return
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun Drawable.toBytes(): ByteArray {
        val bitmap = if (this is BitmapDrawable) {
            this.bitmap
        } else {
            val bmp = Bitmap.createBitmap(
                intrinsicWidth.coerceAtLeast(1),
                intrinsicHeight.coerceAtLeast(1),
                Bitmap.Config.ARGB_8888,
            )
            val canvas = Canvas(bmp)
            setBounds(0, 0, canvas.width, canvas.height)
            draw(canvas)
            bmp
        }
        return ByteArrayOutputStream().also {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }.toByteArray()
    }
}
