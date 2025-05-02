package com.avs.famlink

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat

class NotificationHelper(private val context: Context) {
    fun buildNotification(text: String): Notification {
        val channelId = "famlink_channel"
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "FamLink", NotificationManager.IMPORTANCE_LOW)
            manager.createNotificationChannel(channel)
        }
        return NotificationCompat.Builder(context, channelId)
            .setContentTitle("FamLink Ativo")
            .setContentText(text)
            .setSmallIcon(R.drawable.launch_background)
            .build()
    }
}
