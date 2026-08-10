import 'package:flutter/material.dart';

/// A GPS location gizmo with a direction arrow.
///
/// Displays a blue dot with a white border and a direction arrow that
/// rotates according to the compass/bearing direction.
class UserLocationGizmo extends StatelessWidget {
  /// Device bearing in degrees (0 = north, clockwise).
  final double bearing;

  const UserLocationGizmo({super.key, this.bearing = 0.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // White border
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          // Inner blue gizmo ball
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent,
            ),
          ),
          // Direction arrow, rotated by bearing (points to compass direction)
          Transform.rotate(
            angle: bearing * (3.141592653589793 / 180.0),
            child: const Icon(Icons.navigation, size: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
