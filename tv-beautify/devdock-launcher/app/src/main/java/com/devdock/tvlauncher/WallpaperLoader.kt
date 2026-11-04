package com.devdock.tvlauncher

import android.graphics.BitmapFactory
import android.widget.ImageView
import java.io.File
import kotlin.random.Random

object WallpaperLoader {
    private val wallDir = File("/sdcard/Download/DevTV/walls")

    fun loadRandom(into: ImageView) {
        val files = wallDir.listFiles { f ->
            f.isFile && f.name.endsWith(".jpg", ignoreCase = true)
        }?.sortedBy { it.name }.orEmpty()

        val file = when {
            files.isNotEmpty() -> files[Random.nextInt(files.size)]
            else -> null
        }

        if (file != null) {
            val bmp = BitmapFactory.decodeFile(file.absolutePath)
            if (bmp != null) {
                into.setImageBitmap(bmp)
                return
            }
        }
        into.setImageResource(android.R.color.black)
    }
}
