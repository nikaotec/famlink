import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  final Stream<String> locationStream;

  const MapPage({Key? key, required this.locationStream}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();

    widget.locationStream.listen((locationJson) {
      final data = jsonDecode(locationJson);
      final lat = data['lat'];
      final lng = data['lng'];

      final newLocation = LatLng(lat, lng);

      setState(() => _currentLocation = newLocation);

      _mapController.move(newLocation, _mapController.camera.zoom);
    });
  }

  final locationStreamController = StreamController<String>.broadcast();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation ?? LatLng(0, 0),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.app',
          ),
          if (_currentLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation!,
                  width: 80,
                  height: 80,
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        Timer.periodic(Duration(seconds: 3), (_) {
            final randomLat =
                -23.561000 + (0.001 * (0.5 - (DateTime.now().second % 2)));
            final randomLng =
                -46.625000 + (0.001 * (0.5 - (DateTime.now().second % 2)));
            locationStreamController.add(
              jsonEncode({"lat": randomLat, "lng": randomLng}),
            );
          });
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
