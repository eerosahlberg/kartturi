import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

/// Holds the two opposite corners of a rectangle the user is drawing to
/// select an area for offline download, and builds the declarative layers that
/// render it on the map.
///
/// The rectangle is rendered with a [PolygonLayer] (semi-transparent fill) and
/// a [CircleLayer] marking each corner, passed to [MapLibreMap.layers].
class OfflineAreaLayer {
  /// The first corner of the rectangle (WGS84), set on the first tap.
  Geographic? _cornerA;

  /// The second (opposite) corner, set on the second tap.
  Geographic? _cornerB;

  /// Records the first corner.
  void setFirstCorner(Geographic corner) {
    _cornerA = corner;
    _cornerB = null;
  }

  /// Records the second corner, producing a complete rectangle.
  void setSecondCorner(Geographic corner) => _cornerB = corner;

  /// Clears the current selection.
  void clear() {
    _cornerA = null;
    _cornerB = null;
  }

  /// Whether a rectangle has been fully defined (both corners present).
  bool get isComplete => _cornerA != null && _cornerB != null;

  /// Whether any corner has been placed.
  bool get hasSelection => _cornerA != null;

  /// The four rectangle corners in screen/geo order (clockwise, closed), or an
  /// empty list if the rectangle is not complete.
  List<Geographic> get corners {
    final a = _cornerA;
    final b = _cornerB;
    if (a == null || b == null) return const [];
    return [
      Geographic(lon: a.lon, lat: a.lat),
      Geographic(lon: b.lon, lat: a.lat),
      Geographic(lon: b.lon, lat: b.lat),
      Geographic(lon: a.lon, lat: b.lat),
    ];
  }

  /// Builds the declarative layers to render the drawn rectangle (and its
  /// placed corners) on the map.
  List<Layer> buildLayers() {
    final layers = <Layer>[];

    // Fully defined rectangle -> show the filled polygon.
    if (isComplete) {
      final ring = corners;
      if (ring.isNotEmpty) {
        // Build a closed linear ring (first point repeated at the end).
        final closed = [...ring, ring.first];
        layers.add(
          PolygonLayer(
            polygons: [
              Feature<Polygon>(
                geometry: Polygon.from([closed]),
              ),
            ],
            color: const Color(0x332196F3), // semi-transparent blue fill
            outlineColor: const Color(0xCC2196F3), // visible blue outline
          ),
        );
      }
    }

    // Mark each placed corner with a small circle.
    final placed = <Geographic>[
      ?_cornerA,
      ?_cornerB,
    ];
    if (placed.isNotEmpty) {
      layers.add(
        CircleLayer(
          points: [for (final p in placed) Feature<Point>(geometry: Point(p))],
          color: const Color(0xFF2196F3),
          radius: 6,
          strokeColor: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    return layers;
  }
}