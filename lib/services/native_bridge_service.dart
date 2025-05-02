import 'dart:async';
import 'package:flutter/services.dart';

class NativeBridgeService {
  // Canais de comunicação
  static const MethodChannel _channel = 
      const MethodChannel('com.avs.famlink/commands');
  static const EventChannel _locationEventChannel = 
      const EventChannel('com.avs.famlink/locationUpdates');
  static const EventChannel _errorEventChannel = 
      const EventChannel('com.avs.famlink/errors');

  // Streams
  static Stream<Map<String, double>>? _locationStream;
  static Stream<Map<String, dynamic>>? _errorStream;

  /// Inicia o serviço nativo de localização + WebRTC
  static Future<bool> startService() async {
    try {
      await _channel.invokeMethod('startService');
      return true;
    } on PlatformException catch (e) {
      print('Failed to start service: ${e.message}');
      return false;
    }
  }

  /// Para o serviço nativo
  static Future<bool> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
      return true;
    } on PlatformException catch (e) {
      print('Failed to stop service: ${e.message}');
      return false;
    }
  }

  /// Envia localização para o canal nativo (WebRTC)
  static Future<bool> sendLocation(double latitude, double longitude) async {
    try {
      await _channel.invokeMethod('sendLocation', {
        'lat': latitude,  // Alterado para 'lat' para corresponder ao nativo
        'lon': longitude, // Alterado para 'lon' para corresponder ao nativo
      });
      return true;
    } on PlatformException catch (e) {
      print('Failed to send location: ${e.message}');
      return false;
    }
  }

  /// Escuta localizações recebidas via WebRTC
  static Stream<Map<String, double>> get locationStream {
    _locationStream ??= _locationEventChannel
        .receiveBroadcastStream()
        .handleError((error) => print('Location stream error: $error'))
        .map<Map<String, double>>((dynamic event) {
          final map = event as Map<dynamic, dynamic>;
          return {
            'latitude': map['lat'] as double,
            'longitude': map['lon'] as double,
          };
        });
    return _locationStream!;
  }

  /// Escuta erros do nativo
  static Stream<Map<String, dynamic>> get errorStream {
    _errorStream ??= _errorEventChannel
        .receiveBroadcastStream()
        .handleError((error) => print('Error stream error: $error'))
        .map<Map<String, dynamic>>((dynamic event) => 
            event as Map<String, dynamic>);
    return _errorStream!;
  }
}