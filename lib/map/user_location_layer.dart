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

  /// Registers the gizmo sprite image and adds the GeoJSON source + symbol
  /// layer to the map. Call once after the style has loaded.
  static Future<void> addToMap(MapController controller) async {
    final style = controller.style;
    if (style == null) return;

    // 1. Render the gizmo as a sprite image.
    await style.addImageFromCanvas(
      id: _iconId,
      width: 128,
      height: 128,
      painter: _paintGizmo,
    );

    // 2. Add the GeoJSON source with an initial (empty) point.
    await style.addSource(
      GeoJsonSource(id: _sourceId, data: _featureCollection(0, 0, 0)),
    );

    // 3. Add the symbol layer bound to the source.
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
  }

  /// Updates the gizmo position and heading without recreating the layer.
  ///
  /// [lon]/[lat] are in WGS84 degrees. [heading] is the compass bearing in
  /// degrees (0 = north, clockwise).
  static Future<void> updateLocation(
    MapController controller, {
    required double lon,
    required double lat,
    required double heading,
  }) async {
    final style = controller.style;
    if (style == null) return;
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
