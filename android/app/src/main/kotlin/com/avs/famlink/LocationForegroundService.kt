package com.avs.famlink

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class LocationForegroundService : Service() {
    private lateinit var webRTCManager: WebRTCManager
    private lateinit var locationService: LocationService
    private lateinit var notificationManager: NotificationManager
    private var isServiceRunning = false

    companion object {
        private const val CHANNEL_ID = "location_service_channel"
        private const val NOTIFICATION_ID = 101
        private const val CHANNEL_NAME = "Location Service"
        private const val TAG = "LocationForegroundSvc"

        fun startService(context: Context) {
            if (!hasRequiredPermissions(context)) {
                Log.w(TAG, "Attempted to start service without permissions")
                return
            }



            val intent = Intent(context, LocationForegroundService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start service", e)
            }
        }

        fun stopService(context: Context) {
            val intent = Intent(context, LocationForegroundService::class.java)
            context.stopService(intent)
        }

        private fun hasRequiredPermissions(context: Context): Boolean {
            val fineLocation = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED

            val backgroundLocation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_BACKGROUND_LOCATION
                ) == PackageManager.PERMISSION_GRANTED
            } else {
                true
            }

            return fineLocation && backgroundLocation
        }
    }

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        initializeServices()
    }

    private fun initializeServices() {
        try {
            webRTCManager = WebRTCManager.getInstance().apply {
                initialize(applicationContext)
            }

            locationService = LocationService(applicationContext) { lat, lon ->
                handleLocationUpdate(lat, lon)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Initialization failed", e)
            stopSelf()
        }
    }

    private fun handleLocationUpdate(lat: Double, lon: Double) {
        try {
            webRTCManager.sendLocation(lat, lon)
            updateNotification(lat, lon)
            NativeBridge.sendLocationToFlutter(lat, lon)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing location", e)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!hasRequiredPermissions()) {
            stopSelf()
            return START_NOT_STICKY
        }

        if (!isServiceRunning) {
            startForegroundService()
            isServiceRunning = true
        }

        return START_STICKY
    }

    private fun startForegroundService() {
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())

        try {
            locationService.start()
            Log.d(TAG, "Location updates started")
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception", e)
            stopSelf()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start location updates", e)
            stopSelf()
        }
    }

    private fun hasRequiredPermissions(): Boolean {
        return hasRequiredPermissions(this)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background location tracking"
                notificationManager.createNotificationChannel(this)
            }
        }
    }

    private fun buildNotification(lat: Double? = null, lon: Double? = null): Notification {
        val locationText = if (lat != null && lon != null) {
            "Lat: ${"%.6f".format(lat)}, Lon: ${"%.6f".format(lon)}"
        } else {
            "Obtendo localização..."
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Monitoramento Ativo")
            .setContentText(locationText)
            .setSmallIcon(com.google.android.gms.base.R.drawable.common_google_signin_btn_icon_light)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    private fun updateNotification(lat: Double, lon: Double) {
        notificationManager.notify(NOTIFICATION_ID, buildNotification(lat, lon))
    }

    override fun onDestroy() {
        super.onDestroy()
        cleanupResources()
        isServiceRunning = false
        Log.d(TAG, "Service destroyed")
    }

    private fun cleanupResources() {
        try {
            locationService.stop()
            webRTCManager.cleanup()
        } catch (e: Exception) {
            Log.e(TAG, "Cleanup error", e)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}