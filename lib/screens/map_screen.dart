import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:maplibre/maplibre.dart';

import '../map/map_widget.dart';
import '../map/route_measure_toolbar.dart';
import '../map/route_measurement_layer.dart';
import '../map/route_tracking_layer.dart';
import '../map/route_tracking_toolbar.dart';
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

  /// The horizontal GPS accuracy in meters (diameter of the accuracy circle).
  double _accuracy = 0;

  /// Current compass heading in degrees (0 = north), from the device compass.
  double _bearing = 0.0;

  /// Backs the on-map route measurement visuals and distance calculation.
  final RouteMeasurementLayer _measurement = RouteMeasurementLayer();

  /// Whether the user is currently placing measurement points on the map.
  bool _measuring = false;

  /// Backs the on-map GPS route tracking visuals and distance/speed calc.
  final RouteTrackingLayer _tracking = RouteTrackingLayer();

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
      accuracy: _accuracy,
    );
  }

  void _startLocationUpdates() {
    // Update GPS location every second.
    //
    // Use AndroidSettings.intervalDuration to control the update frequency
    // (default is 5000ms). Do NOT set `timeLimit` here: it is a *timeout*
    // that closes the stream when no update arrives within the duration,
    // which would stop continuous GPS updates.
    _positionSub?.cancel();
    _positionSub =
        geo.Geolocator.getPositionStream(
          locationSettings: geo.AndroidSettings(
            accuracy: geo.LocationAccuracy.high,
            intervalDuration: Duration(seconds: 1),
          ),
        ).listen((position) {
          if (!mounted) return;
          final loc = Geographic(
            lon: position.longitude,
            lat: position.latitude,
          );
          setState(() {
            _userLocation = loc;
            _accuracy = position.accuracy;
            // Record the position into the active tracking session (no-op
            // when not tracking or paused).
            _tracking.addPoint(loc);
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

  /// Starts route measurement: enters measuring mode so map taps place points.
  void _startMeasuring() {
    setState(() => _measuring = true);
  }

  /// Called on every map event. While measuring, a tap on the map adds a
  /// measurement point at the tapped geographic location.
  void _onMapEvent(MapEvent event) {
    if (event is! MapEventClick) return;
    if (!_measuring) return;

    setState(() {
      _measurement.addPoint(event.point);
    });
  }

  /// Removes the most recently added measurement point.
  void _undoLastPoint() {
    setState(() => _measurement.removeLastPoint());
  }

  /// Clears all measurement points and exits measuring mode.
  void _clearMeasurement() {
    setState(() {
      _measurement.clear();
      _measuring = false;
    });
  }

  /// Finishes the measurement, keeping the drawn line + points visible but
  /// no longer continuing to add points on tap.
  void _finishMeasuring() {
    if (!_measuring) return;
    setState(() => _measuring = false);
  }

  /// Starts a new GPS route tracking session.
  void _startTracking() {
    setState(() => _tracking.start());
  }

  /// Pauses the active tracking session.
  void _pauseTracking() {
    setState(() => _tracking.pause());
  }

  /// Resumes a paused tracking session.
  void _resumeTracking() {
    setState(() => _tracking.resume());
  }

  /// Ends the active tracking session, keeping the drawn path visible.
  void _stopTracking() {
    setState(() => _tracking.end());
  }

  @override
  Widget build(BuildContext context) {
    final hasMeasurement = _measurement.pointCount > 0;
    final tracking = _tracking.isTracking;
    final hasTrack = _tracking.pointCount > 0;

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: _mapWidgetKey,
            onEvent: _onMapEvent,
            layers: [..._measurement.buildLayers(), ..._tracking.buildLayers()],
          ),
          // Live measured distance readout, top-left.
          if (hasMeasurement)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: RouteMeasureDistanceChip(
                    distanceMeters: _measurement.totalMeters(),
                    onClear: _clearMeasurement,
                  ),
                ),
              ),
            ),
          // Live tracking info (speed + distance), top-right.
          if (tracking || hasTrack)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: RouteTrackingInfoPanel(
                    speedKmh: _tracking.speedKmh(),
                    distanceMeters: _tracking.totalMeters(),
                    paused: _tracking.isPaused,
                  ),
                ),
              ),
            ),
        ],
      ),
      // Route measurement + tracking buttons above the GPS button.
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          RouteMeasureToolbar(
            measuring: _measuring,
            hasMeasurement: hasMeasurement,
            onStart: _startMeasuring,
            onUndo: _undoLastPoint,
            onClear: _clearMeasurement,
            onFinish: _finishMeasuring,
          ),
          const SizedBox(height: 8),
          RouteTrackingToolbar(
            tracking: tracking,
            paused: _tracking.isPaused,
            onStart: _startTracking,
            onPause: _pauseTracking,
            onResume: _resumeTracking,
            onStop: _stopTracking,
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _centerOnUserLocation,
            tooltip: 'Oma sijainti',
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
