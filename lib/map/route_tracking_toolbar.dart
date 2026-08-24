import 'package:flutter/material.dart';

/// Formats a distance in meters as a human-readable string, switching to
/// kilometers with one decimal once the distance exceeds 1 km (e.g. `850 m`
/// and `2.4 km`).
String formatDistance(double meters) {
  if (meters >= 1000) {
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(km >= 100 ? 0 : 1)} km';
  }
  return '${meters.round()} m';
}

/// A column of buttons for GPS route tracking, intended to be stacked above
/// the GPS button (bottom-right of the map).
///
/// - Idle: shows a single "start tracking" button.
/// - Tracking: shows pause and stop buttons.
/// - Paused: shows resume and stop buttons.
class RouteTrackingToolbar extends StatelessWidget {
  const RouteTrackingToolbar({
    super.key,
    required this.tracking,
    required this.paused,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  /// Whether a tracking session is currently active (recording or paused).
  final bool tracking;

  /// Whether the active session is paused.
  final bool paused;

  /// Called to start a new tracking session.
  final VoidCallback onStart;

  /// Called to pause the active session.
  final VoidCallback onPause;

  /// Called to resume a paused session.
  final VoidCallback onResume;

  /// Called to end the active session.
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tracking) ...[
            _button(
              context,
              icon: paused ? Icons.play_arrow : Icons.pause,
              tooltip: paused ? 'Jatka seurantaa' : 'Keskeytä seuranta',
              onPressed: paused ? onResume : onPause,
            ),
            const SizedBox(height: 8),
            _button(
              context,
              icon: Icons.stop,
              highlighted: true,
              tooltip: 'Lopeta seuranta',
              onPressed: onStop,
            ),
            const SizedBox(height: 8),
          ],
          _button(
            context,
            icon: Icons.route,
            tooltip: tracking ? 'Seuranta käynnissä' : 'Aloita seuranta',
            highlighted: !tracking,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }

  Widget _button(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool highlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = highlighted ? colorScheme.primary : colorScheme.surface;
    final foreground = highlighted
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    return FloatingActionButton.small(
      heroTag: 'route-tracking-$tooltip',
      backgroundColor: background,
      foregroundColor: foreground,
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}

/// A small panel showing the live tracking info (speed and total distance),
/// intended to be shown at the top-right of the map.
class RouteTrackingInfoPanel extends StatelessWidget {
  const RouteTrackingInfoPanel({
    super.key,
    required this.speedKmh,
    required this.distanceMeters,
    required this.paused,
  });

  /// The current interpolated speed in km/h.
  final double speedKmh;

  /// The total travelled distance in meters.
  final double distanceMeters;

  /// Whether the session is currently paused.
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.inverseSurface,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  paused ? Icons.pause : Icons.speed,
                  size: 18,
                  color: colorScheme.onInverseSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  '${speedKmh.toStringAsFixed(1)} km/h',
                  style: TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.straighten,
                  size: 16,
                  color: colorScheme.onInverseSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  formatDistance(distanceMeters),
                  style: TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
