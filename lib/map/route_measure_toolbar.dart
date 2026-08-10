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

/// A column of buttons for route measurement, intended to be stacked above
/// the GPS button (bottom-right of the map).
///
/// - Idle: shows a single "start measuring" button.
/// - While measuring (`measuring == true`): shows undo, clear and finish
///   buttons above the start button.
class RouteMeasureToolbar extends StatelessWidget {
  const RouteMeasureToolbar({
    super.key,
    required this.measuring,
    required this.hasMeasurement,
    required this.onStart,
    required this.onUndo,
    required this.onClear,
    required this.onFinish,
  });

  /// Whether the user is currently placing measurement points.
  final bool measuring;

  /// Whether at least one measurement point has been placed.
  final bool hasMeasurement;

  /// Called to start measuring.
  final VoidCallback onStart;

  /// Called to remove the most recently added point.
  final VoidCallback onUndo;

  /// Called to remove all points and exit measuring mode.
  final VoidCallback onClear;

  /// Called to finish the measurement and exit measuring mode.
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (measuring) ...[
            _button(
              context,
              icon: Icons.undo,
              tooltip: 'Kumoa viimeisin piste',
              onPressed: hasMeasurement ? onUndo : null,
            ),
            const SizedBox(height: 8),
            _button(
              context,
              icon: Icons.delete_sweep,
              tooltip: 'Tyhjennä mittaus',
              onPressed: hasMeasurement ? onClear : null,
            ),
            const SizedBox(height: 8),
            _button(
              context,
              icon: Icons.check,
              highlighted: true,
              tooltip: 'Lopeta mittaus',
              onPressed: onFinish,
            ),
            const SizedBox(height: 8),
          ],
          _button(
            context,
            icon: Icons.rule,
            tooltip: measuring ? 'Mittaus käynnissä' : 'Aloita mittaus',
            highlighted: !measuring,
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
      heroTag: 'route-measure-$tooltip',
      backgroundColor: background,
      foregroundColor: foreground,
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}

/// A small chip showing the live measured distance, intended to be shown at
/// the top-left of the map. Tapping it clears the measurement.
class RouteMeasureDistanceChip extends StatelessWidget {
  const RouteMeasureDistanceChip({
    super.key,
    required this.distanceMeters,
    this.onClear,
  });

  /// The measured distance in meters.
  final double distanceMeters;

  /// Optional callback fired when the chip is tapped (e.g. to clear).
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.inverseSurface,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onClear,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.straighten,
                size: 18,
                color: colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 8),
              Text(
                formatDistance(distanceMeters),
                style: TextStyle(
                  color: colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
