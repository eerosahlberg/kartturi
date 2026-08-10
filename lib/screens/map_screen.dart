import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:maplibre/maplibre.dart';

import '../map/map_widget.dart';
import '../permissions/location_permission_handler.dart';
import '../services/location_service.dart';

/// The maximum zoom level the tile API provides. Zooming beyond this
/// returns blank/white tiles.
const double _maxZoom = 14.0;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GlobalKey<MapWidgetState> _mapWidgetKey = GlobalKey();

  /// The user's real GPS position (used to place the gizmo on the map).
  Geographic? _userLocation;

  /// Current compass heading in degrees (0 = north), from the device compass.
  double _bearing = 0.0;

  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<geo.Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    // Query the GPS location and move the map to it once the map is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnUserLocation();
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  /// Pushes the latest location + heading to the GPU-native map layer.
  void _pushLocationUpdate() {
    final loc = _userLocation;
    if (loc == null) return;
    _mapWidgetKey.currentState?.updateUserLocation(
      lon: loc.lon,
      lat: loc.lat,
      heading: _bearing,
    );
  }

  void _startLocationUpdates() {
    // Update GPS location every second.
    _positionSub?.cancel();
    _positionSub =
        geo.Geolocator.getPositionStream(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            timeLimit: Duration(seconds: 1),
          ),
        ).listen((position) {
          if (!mounted) return;
          setState(() {
            _userLocation = Geographic(
              lon: position.longitude,
              lat: position.latitude,
            );
          });
          _pushLocationUpdate();
        });

    // Rotate the arrow using the device's internal compass.
    _compassSub?.cancel();
    _compassSub = FlutterCompass.events?.listen((event) {
      final heading = event.heading;
      if (heading == null || !mounted) return;
      setState(() {
        _bearing = heading;
      });
      _pushLocationUpdate();
    });
  }

  Future<void> _centerOnUserLocation() async {
    // Check and request permission if needed.
    final hasPermission = await LocationPermissionHandler.hasPermission();
    if (!hasPermission) {
      final granted = await LocationPermissionHandler.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sijaintilupa tarvitaan paikannukseen.'),
            ),
          );
        }
        return;
      }
    }

    // Get current position.
    final position = await LocationService.getCurrentPosition();
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sijaintia ei voitu määrittää.')),
        );
      }
      return;
    }

    final userLocation = Geographic(
      lon: position.longitude,
      lat: position.latitude,
    );

    // Show the gizmo at the real GPS location and start live updates.
    if (mounted) {
      setState(() {
        _userLocation = userLocation;
      });
      _startLocationUpdates();
      _pushLocationUpdate();
    }

    // Animate camera to user location, clamped to the API max zoom.
    // Wait for the map controller to become available (it is created
    // asynchronously after the map widget builds).
    final controller = await _waitForController();
    if (controller != null) {
      await controller.animateCamera(center: userLocation, zoom: _maxZoom);
    }
  }

  /// Waits until the map controller is available, with a timeout.
  Future<MapController?> _waitForController() async {
    for (var i = 0; i < 50; i++) {
      final controller = _mapWidgetKey.currentState?.controller;
      if (controller != null) return controller;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapWidget(key: _mapWidgetKey),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUserLocation,
        tooltip: 'Oma sijainti',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
