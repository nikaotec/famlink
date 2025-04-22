// lib/screens/connection_screen.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:famlink/services/webrtc_connection_service.dart';
import 'package:uuid/uuid.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _roomIdController = TextEditingController();
  final _webRTC = WebRTCConnectionService();
  String? _roomId;
  String _status = "Aguardando...";

  @override
  void initState() {
    super.initState();
    _webRTC.initConnection();
  }

  Future<void> createRoom() async {
    final roomId = const Uuid().v4().substring(0, 6); // sala simples
    _roomId = roomId;

    try{

    

    await _webRTC.createDataChannel((channel) {
      channel.onMessage = (msg) {
        final data = jsonDecode(msg.text);
        print("📍 Localização recebida: $data");
      };
    });

    await _webRTC.createOffer((offerSdp) async {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
        'offer': offerSdp,
      });

      // Espera pela resposta
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .snapshots()
          .listen((snapshot) async {
            final data = snapshot.data();
            if (data != null && data['answer'] != null) {
              await _webRTC.setRemoteDescription(data['answer']);
              setState(() => _status = "📡 Conectado!");
            }
          });

      setState(() => _status = "Sala criada: $roomId");
    });

    } catch (e) {
      setState(() => _status = "❌ Erro ao criar sala: $e");
    }
  }

  Future<void> joinRoom() async {
    final roomId = _roomIdController.text.trim();
    final snapshot =
        await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();

    if (!snapshot.exists) {
      setState(() => _status = "❌ Sala não encontrada");
      return;
    }

    final data = snapshot.data();
    if (data == null || data['offer'] == null) {
      setState(() => _status = "❌ Oferta inválida");
      return;
    }

    await _webRTC.initConnection();

    // escutar canal
    _webRTC.peerConnection.onDataChannel = (channel) {
      channel.onMessage = (msg) {
        final data = jsonDecode(msg.text);
        print("📍 Localização recebida: $data");
      };
    };

    await _webRTC.createAnswer(data['offer'], (answerSdp) async {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'answer': answerSdp,
      });

      setState(() {
        _roomId = roomId;
        _status = "📡 Conectado!";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Conectar Dispositivos")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("📶 Status: $_status"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: createRoom,
              child: const Text("Criar Sala"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _roomIdController,
              decoration: const InputDecoration(labelText: "ID da Sala"),
            ),
            ElevatedButton(
              onPressed: joinRoom,
              child: const Text("Entrar na Sala"),
            ),
            if (_roomId != null) Text("ID da sala: $_roomId"),
          ],
        ),
      ),
    );
  }
}
