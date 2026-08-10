import 'package:flutter/material.dart';

import 'screens/map_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KartturiApp());
}

class KartturiApp extends StatelessWidget {
  const KartturiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kartturi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const MapScreen(),
    );
  }
}
