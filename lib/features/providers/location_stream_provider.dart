import 'dart:async';
import 'package:flutter/material.dart';

class LocationStreamProvider extends ChangeNotifier {
  StreamController<String> _controller = StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void updateLocation(String locationJson) {
    _controller.add(locationJson);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
