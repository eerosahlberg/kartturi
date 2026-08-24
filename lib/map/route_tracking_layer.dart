import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

/// Holds the state for GPS route tracking and builds the declarative
/// [PolylineLayer] widget that renders the travelled path on the map.
///
/// The path is drawn the same way route measurement works: a [PolylineLayer]
/// is passed to [MapLibreMap.layers], which the package's [LayerManager]
/// keeps in sync automatically on every style (re)load.
class RouteTrackingLayer {
  /// The recorded track points in WGS84 [lon, lat] pairs, in order.
  final List<Geographic> _points = [];

  /// Recent (position, time) samples used to interpolate the current speed.
  final List<_Sample> _samples = [];

  /// Whether tracking is currently active (recording points).
  bool _tracking = false;

  /// Whether tracking is paused (not recording, but not ended).
  bool _paused = false;

  /// Distance between two WGS84 positions in meters (great-circle).
  static double distanceMeters(Geographic a, Geographic b) =>
      a.spherical.distanceTo(b);

  /// Total travelled distance in meters, summing consecutive point distances.
  double totalMeters() {
    var sum = 0.0;
    for (var i = 1; i < _points.length; i++) {
      sum += distanceMeters(_points[i - 1], _points[i]);
    }
    return sum;
  }

  int get pointCount => _points.length;
  bool get isTracking => _tracking;
  bool get isPaused => _paused;

  /// Starts a new tracking session, clearing any previous track.
  void start() {
    _points.clear();
    _samples.clear();
    _tracking = true;
    _paused = false;
  }

  /// Pauses recording. The track stays visible but no new points are added.
  void pause() {
    if (!_tracking) return;
    _paused = true;
  }

  /// Resumes recording after a pause.
  void resume() {
    if (!_tracking) return;
    _paused = false;
  }

  /// Ends the tracking session, keeping the drawn path visible.
  void end() {
    _tracking = false;
    _paused = false;
  }

  /// Records a new GPS position while tracking is active and not paused.
  void addPoint(Geographic point, {DateTime? time}) {
    if (!_tracking || _paused) return;

    // Ignore duplicate positions (same coordinate reported twice).
    if (_points.isNotEmpty) {
      final last = _points.last;
      if (last.lon == point.lon && last.lat == point.lat) return;
    }

    final now = time ?? DateTime.now();
    _points.add(point);
    _samples.add(_Sample(point, now));

    // Keep only the last few samples for speed interpolation.
    if (_samples.length > 5) _samples.removeAt(0);
  }

  /// Current speed in km/h, interpolated over the last few samples.
  ///
  /// Uses the distance travelled between the oldest and newest retained
  /// samples divided by the elapsed time, which smooths out GPS jitter.
  double speedKmh() {
    if (_samples.length < 2) return 0;
    final first = _samples.first;
    final last = _samples.last;
    final dt = last.time.difference(first.time).inMilliseconds / 1000.0;
    if (dt <= 0) return 0;
    final dist = distanceMeters(first.point, last.point);
    return (dist / dt) * 3.6; // m/s -> km/h
  }

  /// The declarative layer to render the travelled path on the map.
  List<Layer> buildLayers() {
    return [
      if (_points.length >= 2)
        PolylineLayer(
          polylines: [Feature<LineString>(geometry: LineString.from(_points))],
          color: const Color(0xFF1E88E5),
          width: 4,
        ),
    ];
  }
}

/// A single (position, timestamp) sample used for speed interpolation.
class _Sample {
  final Geographic point;
  final DateTime time;

  _Sample(this.point, this.time);
}
