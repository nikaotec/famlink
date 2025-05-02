package com.avs.famlink

import android.content.Context
import android.util.Log
import org.webrtc.*

object WebRTCManager {
    private const val TAG = "WebRTCManager"

    private lateinit var peerConnectionFactory: PeerConnectionFactory
    private var peerConnection: PeerConnection? = null
    private var dataChannel: DataChannel? = null

    fun initialize(context: Context) {
        if (::peerConnectionFactory.isInitialized) return

        val options = PeerConnectionFactory.InitializationOptions.builder(context)
            .setEnableInternalTracer(true)
            .createInitializationOptions()
        PeerConnectionFactory.initialize(options)

        val encoderFactory = DefaultVideoEncoderFactory(
            EglBase.create().eglBaseContext, true, true
        )
        val decoderFactory = DefaultVideoDecoderFactory(EglBase.create().eglBaseContext)

        peerConnectionFactory = PeerConnectionFactory.builder()
            .setVideoEncoderFactory(encoderFactory)
            .setVideoDecoderFactory(decoderFactory)
            .createPeerConnectionFactory()

        createPeerConnection()
    }

    private fun createPeerConnection() {
        val iceServers = listOf(
            PeerConnection.IceServer.builder("stun:stun.l.google.com:19302").createIceServer()
        )

        val rtcConfig = PeerConnection.RTCConfiguration(iceServers)
        peerConnection = peerConnectionFactory.createPeerConnection(rtcConfig, object : PeerConnection.Observer {
            override fun onIceCandidate(candidate: IceCandidate) {
                Log.d(TAG, "ICE gerado: $candidate")
                // Flutter agora é responsável por enviar isso
                NativeBridge.sendIceCandidateToFlutter(candidate)
            }

            override fun onDataChannel(channel: DataChannel) {
                channel.registerObserver(dataChannelObserver)
            }

            override fun onSignalingChange(p0: PeerConnection.SignalingState) {}
            override fun onIceConnectionChange(p0: PeerConnection.IceConnectionState) {}
            override fun onIceConnectionReceivingChange(p0: Boolean) {}
            override fun onIceGatheringChange(p0: PeerConnection.IceGatheringState) {}
            override fun onIceCandidatesRemoved(p0: Array<out IceCandidate>) {}
            override fun onAddStream(p0: MediaStream) {}
            override fun onRemoveStream(p0: MediaStream) {}
            override fun onRenegotiationNeeded() {}
            override fun onAddTrack(p0: RtpReceiver?, p1: Array<out MediaStream>?) {}
        })

        dataChannel = peerConnection?.createDataChannel("location", DataChannel.Init())
        dataChannel?.registerObserver(dataChannelObserver)
    }

    private val dataChannelObserver = object : DataChannel.Observer {
        override fun onBufferedAmountChange(p0: Long) {}
        override fun onStateChange() {
            Log.d(TAG, "Estado do DataChannel: ${dataChannel?.state()}")
        }

        override fun onMessage(buffer: DataChannel.Buffer?) {
            val bytes = ByteArray(buffer?.data?.remaining() ?: 0)
            buffer?.data?.get(bytes)
            val message = String(bytes)
            Log.d(TAG, "Recebido via DataChannel: $message")
            // enviar pro Flutter?
        }
    }

    fun createOffer(callback: (SessionDescription) -> Unit) {
        val constraints = MediaConstraints()
        peerConnection?.createOffer(object : SdpObserverAdapter() {
            override fun onCreateSuccess(desc: SessionDescription) {
                peerConnection?.setLocalDescription(this, desc)
                callback(desc)
            }

            override fun onSetSuccess() {
                super.onSetSuccess()
            }

            override fun onCreateFailure(error: String?) {
                super.onCreateFailure(error)
            }
        }, constraints)
    }

    fun createAnswer(callback: (SessionDescription) -> Unit) {
        val constraints = MediaConstraints()
        peerConnection?.createAnswer(object : SdpObserverAdapter() {
            override fun onCreateSuccess(desc: SessionDescription) {
                peerConnection?.setLocalDescription(this, desc)
                callback(desc)
            }

            override fun onSetSuccess() {
                super.onSetSuccess()
            }

            override fun onCreateFailure(error: String?) {
                super.onCreateFailure(error)
            }
        }, constraints)
    }

    fun setRemoteDescription(type: SessionDescription.Type, sdp: String) {
        val desc = SessionDescription(type, sdp)
        peerConnection?.setRemoteDescription(object : SdpObserverAdapter() {}, desc)
    }

    fun addIceCandidate(mid: String, index: Int, candidate: String) {
        peerConnection?.addIceCandidate(IceCandidate(mid, index, candidate))
    }

    fun sendLocation(lat: Double, lon: Double) {
        val msg = "$lat,$lon"
        val buffer = DataChannel.Buffer(java.nio.ByteBuffer.wrap(msg.toByteArray()), false)
        if (dataChannel?.state() == DataChannel.State.OPEN) {
            dataChannel?.send(buffer)
        } else {
            Log.w(TAG, "DataChannel fechado")
        }
    }

    fun cleanup() {
        dataChannel?.close()
        peerConnection?.close()
        dataChannel = null
        peerConnection = null
    }

    fun getInstance(): WebRTCManager = this
}
