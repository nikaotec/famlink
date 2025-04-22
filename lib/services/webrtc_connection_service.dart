// lib/services/webrtc_connection_service.dart

import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCConnectionService {
  late RTCPeerConnection peerConnection;
  RTCDataChannel? dataChannel;

  Future<void> initConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    peerConnection = await createPeerConnection(config);
  }

  Future<void> createOffer(Function(String sdp) onSdpCreated) async {
    RTCSessionDescription offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);
    onSdpCreated(jsonEncode(offer.toMap()));
  }

  Future<void> createAnswer(
    String remoteSdp,
    Function(String sdp) onAnswerCreated,
  ) async {
    final session = jsonDecode(remoteSdp);
    await peerConnection.setRemoteDescription(
      RTCSessionDescription(session['sdp'], session['type']),
    );

    RTCSessionDescription answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);
    onAnswerCreated(jsonEncode(answer.toMap()));
  }

  Future<void> setRemoteDescription(String sdp) async {
    final session = jsonDecode(sdp);
    await peerConnection.setRemoteDescription(
      RTCSessionDescription(session['sdp'], session['type']),
    );
  }

  Future<void> createDataChannel(
    Function(RTCDataChannel channel) onOpen,
  ) async {
    RTCDataChannelInit init = RTCDataChannelInit();
    init.ordered = true;
    dataChannel = await peerConnection.createDataChannel(
      "locationChannel",
      init,
    );
    onOpen(dataChannel!);
  }

  void listenForMessages(Function(Map<String, dynamic>) onLocationReceived) {
    dataChannel?.onMessage = (message) {
      final data = jsonDecode(message.text);
      onLocationReceived(data);
    };
  }

  void sendLocation(double lat, double lng) {
    final data = jsonEncode({
      "lat": lat,
      "lng": lng,
      "timestamp": DateTime.now().toIso8601String(),
    });

    if (dataChannel != null &&
        dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      dataChannel!.send(RTCDataChannelMessage(data));
    } else {
      print("⚠️ Canal não está aberto.");
    }
  }
}
