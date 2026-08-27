import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

/// Formats a byte count as a human-readable size string
/// (e.g. `512 B`, `3.4 MB`, `1.2 GB`).
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = -1;
  do {
    value /= 1024;
    unit++;
  } while (value >= 1024 && unit < units.length - 1);
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unit]}';
}

/// A bottom sheet that lists the downloaded offline map packets, shows the
/// total offline storage size, and offers actions to draw a new download area
/// or delete existing packets.
class OfflineManagerPanel extends StatelessWidget {
  const OfflineManagerPanel({
    super.key,
    required this.regions,
    required this.totalBytes,
    required this.onDrawArea,
    required this.onDelete,
  });

  /// The list of downloaded offline regions.
  final List<OfflineRegion> regions;

  /// Total offline database size in bytes (may be null if none downloaded).
  final int? totalBytes;

  /// Called to enter "draw download area" mode (closes this sheet).
  final VoidCallback onDrawArea;

  /// Called to delete a region by id.
  final void Function(int regionId) onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bytes = totalBytes;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Offline-kartat',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (bytes != null)
                  Text(
                    formatBytes(bytes),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (regions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Ei ladattuja karttapaketteja.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: regions.length,
                  itemBuilder: (context, index) {
                    final r = regions[index];
                    final name = r.metadata['name']?.toString() ??
                        'Alue ${r.id}';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.map_outlined),
                      title: Text(name),
                      subtitle: Text(_describe(regions[index])),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Poista paketti',
                        onPressed: () => onDelete(r.id),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onDrawArea,
              icon: const Icon(Icons.crop_free),
              label: const Text('Lataa uusi alue'),
            ),
          ],
        ),
      ),
    );
  }

  static String _describe(OfflineRegion r) {
    final b = r.bounds;
    final z = 'zoom ${r.minZoom.toStringAsFixed(0)}–${r.maxZoom.toStringAsFixed(0)}';
    final center = _formatCoord(
      (b.latitudeNorth + b.latitudeSouth) / 2,
      (b.longitudeWest + b.longitudeEast) / 2,
    );
    return '$z · $center';
  }

  static String _formatCoord(double lat, double lon) {
    String ns(double v) => v >= 0 ? '${v.toStringAsFixed(2)}°N' : '${(-v).toStringAsFixed(2)}°S';
    String ew(double v) => v >= 0 ? '${v.toStringAsFixed(2)}°E' : '${(-v).toStringAsFixed(2)}°W';
    return '${ns(lat)} ${ew(lon)}';
  }
}