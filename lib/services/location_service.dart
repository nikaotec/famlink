// lib/src/services/location_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Timer? _timer;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void startSendingLocation() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final position = await Geolocator.getCurrentPosition();
        final avatar =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        await FirebaseFirestore.instance
            .collection('locations')
            .doc(user.uid)
            .set({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'email': user.email,
              'avatar': avatar['avatar'],
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    });
  }

  Future<void> saveLocation(String uid, double lat, double lng) async {
    await _firestore.collection("locations").doc(uid).set({
      'lat': lat,
      'lng': lng,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void listenToLocation(
    String uid,
    Function(Map<String, dynamic>) onLocationUpdate,
  ) {
    _firestore.collection("locations").doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        onLocationUpdate(snapshot.data()!);
      }
    });
  }

  void stop() => _timer?.cancel();
}
