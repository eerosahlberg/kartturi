import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:maplibre/maplibre.dart';
import 'package:path_provider/path_provider.dart';

import '../config.dart';

/// Wraps the maplibre [OfflineManager] to download map regions for offline
/// use and to manage already-downloaded packets.
///
/// The offline data lives in a single native SQLite database pointed to by the
/// manager; the map automatically falls back to offline tiles whenever a tile
/// for the current view has been downloaded.
class OfflineService {
  OfflineService._();
  static final OfflineService instance = OfflineService._();

  OfflineManager? _manager;
  bool _managerFailed = false;

  /// Whether offline downloads are supported on this platform (Android/iOS).
  bool get isSupported => OfflineManager.isSupported;

  /// Lazily creates the native offline manager.
  Future<OfflineManager?> _ensureManager() async {
    if (_manager != null) return _manager;
    if (_managerFailed || !OfflineManager.isSupported) return null;
    try {
      _manager = await OfflineManager.createInstance();
    } catch (e) {
      debugPrint('OfflineService: failed to create OfflineManager: $e');
      _managerFailed = true;
      return null;
    }
    return _manager;
  }

  /// Lists all downloaded offline regions.
  Future<List<OfflineRegion>> listRegions() async {
    final manager = await _ensureManager();
    if (manager == null) return const [];
    return manager.listOfflineRegions();
  }

  /// Deletes an offline region by id.
  Future<void> deleteRegion(int regionId) async {
    final manager = await _ensureManager();
    if (manager == null) return;
    await manager.deleteRegion(regionId: regionId);
  }

  /// Starts downloading the tiles inside [bounds] from [minZoom] to [maxZoom]
  /// and returns a progress stream. Pairs with [name] stored in region
  /// metadata for later identification.
  Stream<DownloadProgress> downloadRegion(
    LngLatBounds bounds, {
    required String name,
    double minZoom = AppConfig.kTileMinZoom,
    double maxZoom = AppConfig.kTileMaxZoom,
  }) async* {
    final manager = await _ensureManager();
    if (manager == null) return;

    yield* manager.downloadRegion(
      mapStyleUrl: AppConfig.kStyleUrl,
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: maxZoom,
      pixelDensity: 1.0,
      metadata: {'name': name},
    );
  }

  /// Total size in bytes of the offline database on disk, or `null` if the
  /// database file does not exist yet.
  Future<int?> offlineDatabaseBytes() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/mbgl-offline.db');
    if (!await file.exists()) return null;
    return await file.length();
  }

  /// Releases the native offline manager.
  void dispose() {
    _manager?.dispose();
    _manager = null;
  }
}