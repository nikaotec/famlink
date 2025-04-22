import 'package:latlong2/latlong.dart';

class FamilyLocation {
  final String id;
  final String name;
  final String avatarUrl;
  final LatLng location;
  final List<LatLng> history;

  FamilyLocation({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.location,
    required this.history,
  });

  FamilyLocation copyWith({LatLng? location, List<LatLng>? history}) {
    return FamilyLocation(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      location: location ?? this.location,
      history: history ?? this.history,
    );
  }
}
