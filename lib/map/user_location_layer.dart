import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

/// Manages the GPU-native user location gizmo as a MapLibre layer.
///
/// Renders the gizmo as a sprite image and displays it via a GeoJSON source
/// + symbol layer, so it stays perfectly synchronized with the map engine's
/// rendering loop (no Flutter overlay lag).
class UserLocationLayer {
  static const String _sourceId = 'user-location-source';
  static const String _layerId = 'user-location-layer';
  static const String _iconId = 'user-location-icon';

  /// Source + layer for the blue see-through accuracy circle.
  static const String _accuracySourceId = 'user-location-accuracy-source';
  static const String _accuracyLayerId = 'user-location-accuracy-layer';

  /// The style instance the gizmo was last added to. When the style reloads
  /// a new [StyleController] is created, so the gizmo must be re-added.
  static StyleController? _addedStyle;

  /// Registers the gizmo sprite image and adds the GeoJSON source + symbol
  /// layer to the map. Safe to call more than once: it is a no-op if the
  /// gizmo is already present on the current style, and re-adds it if the
  /// style has been reloaded. Call after the style has loaded.
  static Future<void> addToMap(MapController controller) async {
    final style = controller.style;
    if (style == null) return;

    // Already added to this exact style instance -> nothing to do.
    if (identical(style, _addedStyle)) return;

    // 1. Render the gizmo as a sprite image.
    await style.addImageFromCanvas(
      id: _iconId,
      width: 128,
      height: 128,
      painter: _paintGizmo,
    );

    // 2. Add the accuracy circle source + fill layer (drawn beneath the
    //    gizmo so the dot stays on top).
    await style.addSource(
      GeoJsonSource(id: _accuracySourceId, data: _accuracyPolygon(0, 0, 0)),
    );
    await style.addLayer(
      FillStyleLayer(
        id: _accuracyLayerId,
        sourceId: _accuracySourceId,
        paint: {
          'fill-color': const Color(0xFF2196F3).toHexString(),
          'fill-opacity': 0.15,
          'fill-outline-color': const Color(0xFF2196F3).toHexString(),
          'fill-outline-opacity': 0.4,
        },
      ),
    );

    // 3. Add the GeoJSON source with an initial (empty) point.
    await style.addSource(
      GeoJsonSource(id: _sourceId, data: _featureCollection(0, 0, 0)),
    );

    // 4. Add the symbol layer bound to the source.
    await style.addLayer(
      SymbolStyleLayer(
        id: _layerId,
        sourceId: _sourceId,
        layout: {
          'icon-image': _iconId,
          'icon-allow-overlap': true,
          'icon-ignore-placement': true,
          'icon-rotation-alignment': 'map',
          'icon-rotate': ['get', 'heading'],
          'icon-size': 0.5,
        },
      ),
    );

    _addedStyle = style;
  }

  /// Updates the gizmo position, heading and accuracy circle without
  /// recreating the layers.
  ///
  /// [lon]/[lat] are in WGS84 degrees. [heading] is the compass bearing in
  /// degrees (0 = north, clockwise). [accuracy] is the horizontal GPS
  /// accuracy in meters; the see-through circle's diameter equals it.
  static Future<void> updateLocation(
    MapController controller, {
    required double lon,
    required double lat,
    required double heading,
    required double accuracy,
  }) async {
    final style = controller.style;
    if (style == null) return;

    // Accuracy circle: diameter = accuracy, so radius = accuracy / 2.
    final radius = accuracy / 2.0;
    await style.updateGeoJsonSource(
      id: _accuracySourceId,
      data: _accuracyPolygon(lon, lat, radius),
    );

    await style.updateGeoJsonSource(
      id: _sourceId,
      data: _featureCollection(lon, lat, heading),
    );
  }

  /// Builds a GeoJSON FeatureCollection with a single Point feature.
  /// Coordinates are in standard GeoJSON order: [longitude, latitude].
  static String _featureCollection(double lon, double lat, double heading) {
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [lon, lat],
          },
          'properties': {'heading': heading},
        },
      ],
    });
  }

  /// Builds a GeoJSON FeatureCollection with a single Polygon feature
  /// approximating a circle of [radius] meters around [lon]/[lat].
  static String _accuracyPolygon(double lon, double lat, double radius) {
    if (radius <= 0) {
      // Degenerate/empty circle: emit an empty feature collection.
      return jsonEncode({'type': 'FeatureCollection', 'features': []});
    }

    final center = Geographic(lon: lon, lat: lat);
    const segments = 36;
    final ring = <List<double>>[];
    for (var i = 0; i < segments; i++) {
      final bearing = i * (360.0 / segments);
      final p = center.spherical.destinationPoint(
        distance: radius,
        bearing: bearing,
      );
      ring.add([p.lon, p.lat]);
    }
    // Close the linear ring.
    ring.add(ring.first);

    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [ring],
          },
          'properties': {},
        },
      ],
    });
  }

  /// Paints the gizmo (blue dot + white border + direction arrow) onto a
  /// canvas to produce the sprite image.
  static void _paintGizmo(ui.Canvas canvas) {
    final center = const Offset(64, 64);

    // White border circle.
    canvas.drawCircle(center, 28, Paint()..color = Colors.white);

    // Inner blue dot.
    canvas.drawCircle(center, 20, Paint()..color = Colors.blueAccent);

    // Direction arrow (points up = north by default; rotated via icon-rotate).
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(64, 30)
      ..lineTo(72, 58)
      ..lineTo(64, 52)
      ..lineTo(56, 58)
      ..close();
    canvas.drawPath(path, arrowPaint);
  }
}
