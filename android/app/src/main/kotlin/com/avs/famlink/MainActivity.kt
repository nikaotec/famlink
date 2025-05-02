package com.avs.famlink

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    companion object {
        private const val LOCATION_PERMISSION_REQUEST_CODE = LocationPermissionHelper.LOCATION_PERMISSION_REQUEST_CODE
        private const val BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE = LocationPermissionHelper.BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE
    }


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NativeBridge.setup(flutterEngine, this)
    }

    fun startLocationTracking() {
        if (LocationPermissionHelper.hasForegroundLocationPermissions(this)) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                !LocationPermissionHelper.hasBackgroundLocationPermission(this)) {

                LocationPermissionHelper.requestBackgroundLocationPermission(this)
            } else {
                LocationForegroundService.startService(this)
            }
        } else {
            if (LocationPermissionHelper.shouldShowPermissionRationale(this)) {
                LocationPermissionHelper.showPermissionRationaleDialog(this) {
                    LocationPermissionHelper.requestForegroundLocationPermissions(this)
                }
            } else {
                LocationPermissionHelper.requestForegroundLocationPermissions(this)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        when (requestCode) {
            LOCATION_PERMISSION_REQUEST_CODE -> {
                val granted = grantResults.all { it == android.content.pm.PackageManager.PERMISSION_GRANTED }
                if (granted) {
                    startLocationTracking()
                } else {
                    LocationPermissionHelper.showPermissionDeniedDialog(this)
                }
            }

            BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE -> {
                if (grantResults.isNotEmpty() &&
                    grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED
                ) {
                    LocationForegroundService.startService(this)
                } else {
                    LocationPermissionHelper.showPermissionDeniedDialog(this)
                }
            }
        }
    }

    override fun onDestroy() {
        NativeBridge.eventSink = null
        super.onDestroy()
    }


}
