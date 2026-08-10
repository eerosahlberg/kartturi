import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:maplibre/maplibre.dart';

import 'user_location_layer.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key, this.children = const []});

  /// Widgets to display on top of the map (e.g. [WidgetLayer]).
  final List<Widget> children;

  @override
  State<MapWidget> createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  MapController? _controller;
  Geographic? _initialCenter;

  @override
  void initState() {
    super.initState();
    _loadInitialCenter();
  }

  Future<void> _loadInitialCenter() async {
    try {
      final serviceEnabled =
          await geolocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
      }

      if (permission == geolocator.LocationPermission.denied ||
          permission == geolocator.LocationPermission.deniedForever) {
        return;
      }

      final position = await geolocator.Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _initialCenter = Geographic(
          lon: position.longitude,
          lat: position.latitude,
        );
      });
    } catch (_) {
      // Keep the default center if location cannot be resolved.
    }
  }

  /// Provides access to the underlying map controller for external camera control.
  MapController? get controller => _controller;

  /// Updates the GPU-native user location gizmo position and heading.
  Future<void> updateUserLocation({
    required double lon,
    required double lat,
    required double heading,
  }) async {
    final c = _controller;
    if (c == null) return;
    await UserLocationLayer.updateLocation(
      c,
      lon: lon,
      lat: lat,
      heading: heading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      options: MapOptions(
        initStyle: 'https://demotiles.maplibre.org/style.json',
        initZoom: 14,
        initCenter:
            _initialCenter ?? const Geographic(lon: 24.9354, lat: 60.1695),
        gestures: MapGestures.all(),
        minZoom: 10,
        maxZoom: 24,
      ),
      onMapCreated: (controller) async {
        _controller = controller;
        final styleJson = await rootBundle.loadString('assets/style.json');
        controller.setStyle(styleJson);
        await UserLocationLayer.addToMap(controller);
      },
      children: widget.children,
    );
  }
}
