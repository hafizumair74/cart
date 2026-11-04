package com.devdock.tvlauncher

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : AppCompatActivity() {

    private val clockHandler = Handler(Looper.getMainLooper())
    private lateinit var adapter: AppAdapter

    private val clockTick = object : Runnable {
        override fun run() {
            val now = Date()
            findViewById<TextView>(R.id.clock).text =
                SimpleDateFormat("h:mm a", Locale.getDefault()).format(now)
            findViewById<TextView>(R.id.dateLine).text =
                SimpleDateFormat("EEE, d MMM yyyy", Locale.getDefault()).format(now)
            clockHandler.postDelayed(this, 30_000)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        WallpaperLoader.loadRandom(findViewById(R.id.wallpaper))

        val span = if (resources.displayMetrics.widthPixels > 1800) 5 else 4
        val grid = findViewById<RecyclerView>(R.id.appGrid)
        grid.layoutManager = GridLayoutManager(this, span)
        adapter = AppAdapter(emptyList()) { launch(it) }
        grid.adapter = adapter
        grid.itemAnimator = null

        adapter.submit(resolveApps())
        clockHandler.post(clockTick)
    }

    override fun onResume() {
        super.onResume()
        findViewById<ImageView>(R.id.wallpaper).let { WallpaperLoader.loadRandom(it) }
    }

    override fun onDestroy() {
        clockHandler.removeCallbacks(clockTick)
        super.onDestroy()
    }

    private fun launch(entry: AppEntry) {
        val intent = packageManager.getLaunchIntentForPackage(entry.packageName)
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }

    private fun resolveApps(): List<AppEntry> {
        val pm = packageManager
        val wanted = loadWantedPackages(pm)
        val seen = mutableSetOf<String>()
        val result = mutableListOf<AppEntry>()

        for (pkg in wanted) {
            if (pkg in seen || pkg == packageName) continue
            val launch = pm.getLaunchIntentForPackage(pkg) ?: continue
            if (launch.`package` != pkg && pm.queryIntentActivities(launch, 0).isEmpty()) continue
            try {
                val ai = pm.getApplicationInfo(pkg, 0)
                val label = pm.getApplicationLabel(ai).toString()
                val icon = pm.getApplicationIcon(pkg)
                result.add(AppEntry(label, pkg, icon))
                seen.add(pkg)
            } catch (_: PackageManager.NameNotFoundException) {
            }
        }

        if (result.isEmpty()) {
            val main = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER)
            val apps = pm.queryIntentActivities(main, PackageManager.MATCH_ALL)
            apps.take(12).forEach { ri ->
                val pkg = ri.activityInfo.packageName
                if (pkg == packageName || pkg in seen) return@forEach
                val label = ri.loadLabel(pm).toString()
                result.add(AppEntry(label, pkg, ri.loadIcon(pm)))
                seen.add(pkg)
            }
        }
        return result
    }

    private fun loadWantedPackages(pm: PackageManager): List<String> {
        val json = assets.open("default_apps.json").bufferedReader().use { it.readText() }
        val arr = JSONArray(json)
        val hints = mutableListOf<String>()
        for (i in 0 until arr.length()) {
            hints.add(arr.getJSONObject(i).getString("package"))
        }

        val installed = pm.getInstalledApplications(PackageManager.MATCH_ALL).map { it.packageName }
        val matched = linkedSetOf<String>()

        for (hint in hints) {
            if (installed.contains(hint)) matched.add(hint)
            installed.filter { it.contains(hint, ignoreCase = true) }.forEach { matched.add(it) }
        }

        val custom = java.io.File("/sdcard/Download/DevTV/devdock_apps.json")
        if (custom.isFile) {
            val customArr = JSONArray(custom.readText())
            for (i in 0 until customArr.length()) {
                val pkg = customArr.getString(i)
                if (installed.contains(pkg)) matched.add(pkg)
            }
        }
        return matched.toList()
    }
}
