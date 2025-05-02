import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:famlink/services/native_bridge_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MapPage extends StatefulWidget {
  final String? avatarUrl;
  final String? userName;

  const MapPage({Key? key, this.avatarUrl, this.userName}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  StreamSubscription<Map<String, double>>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocationService();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    NativeBridgeService.stopService();
    super.dispose();
  }

  Future<void> _initializeLocationService() async {
    try {
      final started = await NativeBridgeService.startService();
      if (!started) {
        _showError('Falha ao iniciar serviço de localização');
        return;
      }

      _locationSubscription = NativeBridgeService.locationStream.listen(
        _handleLocationUpdate,
        onError: (error) => _showError('Erro na localização: $error'),
      );
    } catch (e) {
      _showError('Erro ao inicializar serviço: $e');
    }
  }

  void _handleLocationUpdate(Map<String, double> location) {
    final lat = location['latitude'];
    final lon = location['longitude'];

    if (lat == null || lon == null) return;

    final newLocation = LatLng(lat, lon);

    if (!mounted) return;

    setState(() {
      _currentLocation = newLocation;
    });

    // Atualização direta da posição do mapa
    _mapController.move(newLocation, _mapController.camera.zoom);
  }

  void _centerMapOnUser() {
    if (_currentLocation != null) {
      // Versão com animação suave
      _mapController.move(
        _currentLocation!,
        _mapController.camera.zoom,
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildAvatarMarker() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child:
            widget.avatarUrl != null
                ? CachedNetworkImage(
                  imageUrl: widget.avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => const CircularProgressIndicator(),
                  errorWidget:
                      (context, url, error) => const Icon(Icons.person),
                )
                : Container(
                  color: Colors.blue,
                  child: Center(
                    child: Text(
                      widget.userName?.substring(0, 1) ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(-23.561000, -46.625000),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.avs.famlink',
          ),
          if (_currentLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation!,
                  width: 80,
                  height: 80,
                  child: _buildAvatarMarker(),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerMapOnUser,
        child: const Icon(Icons.my_location),
        tooltip: 'Centralizar no usuário',
      ),
    );
  }
}
