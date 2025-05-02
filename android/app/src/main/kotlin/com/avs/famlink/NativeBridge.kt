package com.avs.famlink

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.webrtc.IceCandidate
import org.webrtc.SessionDescription

object NativeBridge {
    private const val LOCATION_CHANNEL = "com.avs.famlink/locationUpdates"
    private const val COMMAND_CHANNEL = "com.avs.famlink/commands"
    private const val ERROR_CHANNEL = "com.avs.famlink/errors"

    private const val TAG = "NativeBridge"

    private lateinit var mainActivity: MainActivity

    @Volatile
    var eventSink: EventChannel.EventSink? = null
    private var errorSink: EventChannel.EventSink? = null

    fun setup(flutterEngine: FlutterEngine, activity: MainActivity) {
        mainActivity = activity
        setupLocationChannel(flutterEngine)
        setupCommandChannel(flutterEngine)
        setupErrorChannel(flutterEngine)
    }

    private fun setupLocationChannel(flutterEngine: FlutterEngine) {
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun setupCommandChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COMMAND_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "startService" -> {
                            mainActivity.startLocationTracking()
                            result.success(true)
                        }
                        "stopService" -> {
                            LocationForegroundService.stopService(mainActivity)
                            result.success(true)
                        }
                        "connectToRoom" -> {
                            val roomId = call.argument<String>("roomId")
                            if (roomId != null) {
                                WebRTCManager.getInstance().initialize(mainActivity.applicationContext)
                                result.success(true)
                            } else {
                                result.error("INVALID_ARGUMENTS", "roomId is null", null)
                            }
                        }
                        "setRemoteDescription" -> {
                            val type = call.argument<String>("type")
                            val sdp = call.argument<String>("sdp")
                            if (type != null && sdp != null) {
                                val descType = SessionDescription.Type.fromCanonicalForm(type)
                                WebRTCManager.getInstance().setRemoteDescription(descType, sdp)
                                result.success(true)
                            } else {
                                result.error("INVALID_ARGUMENTS", "type or sdp is null", null)
                            }
                        }
                        "addIceCandidate" -> {
                            val mid = call.argument<String>("sdpMid")
                            val index = call.argument<Int>("sdpMLineIndex")
                            val candidate = call.argument<String>("candidate")
                            if (mid != null && index != null && candidate != null) {
                                WebRTCManager.getInstance().addIceCandidate(mid, index, candidate)
                                result.success(true)
                            } else {
                                result.error("INVALID_ARGUMENTS", "ICE fields are null", null)
                            }
                        }
                        "sendLocation" -> {
                            val lat = call.argument<Double>("lat")
                            val lon = call.argument<Double>("lon")
                            if (lat != null && lon != null) {
                                WebRTCManager.getInstance().sendLocation(lat, lon)
                                result.success(true)
                            } else {
                                result.error("INVALID_ARGUMENTS", "Latitude or longitude is null", null)
                            }
                        }
                        "createOffer" -> {
                            WebRTCManager.getInstance().createOffer { desc ->
                                val resultMap = mapOf(
                                    "type" to desc.type.canonicalForm(),
                                    "sdp" to desc.description
                                )
                                result.success(resultMap)
                            }
                        }
                        "createAnswer" -> {
                            WebRTCManager.getInstance().createAnswer { desc ->
                                val resultMap = mapOf(
                                    "type" to desc.type.canonicalForm(),
                                    "sdp" to desc.description
                                )
                                result.success(resultMap)
                            }
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Erro ao lidar com método ${call.method}", e)
                    result.error("EXCEPTION", e.message, null)
                    sendErrorToFlutter("MethodCallError", e.message ?: "Erro desconhecido")
                }
            }
    }

    private fun setupErrorChannel(flutterEngine: FlutterEngine) {
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, ERROR_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    errorSink = events
                }

                override fun onCancel(arguments: Any?) {
                    errorSink = null
                }
            }
        )
    }

    fun sendLocationToFlutter(lat: Double, lon: Double) {
        try {
            val location = mapOf(
                "lat" to lat,
                "lon" to lon,
                "timestamp" to System.currentTimeMillis()
            )
            eventSink?.success(location)
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao enviar localização", e)
            sendErrorToFlutter("LocationSendError", e.message ?: "Erro")
        }
    }

    fun sendErrorToFlutter(code: String, message: String) {
        try {
            errorSink?.success(
                mapOf(
                    "code" to code,
                    "message" to message,
                    "timestamp" to System.currentTimeMillis()
                )
            )
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao enviar erro", e)
        }
    }

    fun sendIceCandidateToFlutter(candidate: IceCandidate) {
        try {
            val ice = mapOf(
                "sdpMid" to candidate.sdpMid,
                "sdpMLineIndex" to candidate.sdpMLineIndex,
                "candidate" to candidate.sdp
            )
            // Você pode criar um canal separado ou usar COMMAND_CHANNEL para isso também
            // Por agora, apenas loga. Envie ao Flutter se necessário
            Log.d(TAG, "ICE candidate para enviar ao Flutter: $ice")
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao enviar ICE para Flutter", e)
        }
    }
}
