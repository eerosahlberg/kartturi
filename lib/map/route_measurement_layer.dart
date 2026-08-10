import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

/// Holds the state for route measurement and builds the declarative
/// [CircleLayer] / [PolylineLayer] widgets that render the tapped points and
/// the connecting line.
///
/// These layers are passed to [MapLibreMap.layers], which the package's
/// [LayerManager] keeps in sync automatically on every style (re)load — so
/// the points and line always render without manual source/layer management.
class RouteMeasurementLayer {
  /// The current measurement points in WGS84 [lon, lat] pairs, in tap order.
  final List<Geographic> _points = [];

  /// Distance between two WGS84 positions in meters (great-circle).
  static double distanceMeters(Geographic a, Geographic b) =>
      a.spherical.distanceTo(b);

  /// Total path length in meters, summing consecutive point distances.
  double totalMeters() {
    var sum = 0.0;
    for (var i = 1; i < _points.length; i++) {
      sum += distanceMeters(_points[i - 1], _points[i]);
    }
    return sum;
  }

  int get pointCount => _points.length;

  /// Adds a measurement point.
  void addPoint(Geographic point) => _points.add(point);

  /// Removes the most recently added point.
  void removeLastPoint() {
    if (_points.isNotEmpty) _points.removeLast();
  }

  /// Clears all measurement points.
  void clear() => _points.clear();

  /// The declarative layers to render the measurement on the map.
  ///
  /// A [PolylineLayer] renders the connecting line (only when there are at
  /// least two points, since a LineString needs >= 2 positions) and a
  /// [CircleLayer] renders each tapped point.
  List<Layer> buildLayers() {
    return [
      if (_points.length >= 2)
        PolylineLayer(
          polylines: [Feature<LineString>(geometry: LineString.from(_points))],
          color: const Color(0xFFE53935),
          width: 4,
        ),
      CircleLayer(
        points: [for (final p in _points) Feature<Point>(geometry: Point(p))],
        color: const Color(0xFFE53935),
        radius: 6,
        strokeColor: Colors.white,
        strokeWidth: 2,
      ),
    ];
  }
}
