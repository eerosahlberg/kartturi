/// Application configuration constants.
///
/// These centralize values shared across the map widget and the offline
/// download feature. Values that may differ per environment (tile server,
/// API key, CDN base) are injected at build time via `--dart-define` so they
/// are not hardcoded in source.
class AppConfig {
  AppConfig._();

  /// The minimum zoom level the tile API provides.
  static const double kTileMinZoom = 12;

  /// The maximum zoom level the tile API provides. Zooming beyond this returns
  /// blank/white tiles.
  static const double kTileMaxZoom = 14;

  /// Base URL of the local tile server. Override with
  /// `--dart-define=TILE_SERVER_BASE=...`.
  static const String kTileServerBase = String.fromEnvironment(
    'TILE_SERVER_BASE',
    defaultValue: 'http://192.168.1.228:8080',
  );

  /// Base URL of the CDN that hosts the sprite, glyphs and the minimal offline
  /// style. Override with `--dart-define=CDN_BASE=...`.
  static const String kCdnBase = String.fromEnvironment(
    'CDN_BASE',
    defaultValue: 'https://d36acwop1r7ali.cloudfront.net',
  );

  /// URL of the minimal offline style document hosted on the CDN. The native
  /// offline manager fetches this to discover the tile sources, glyphs and
  /// sprite to download. It contains only the sources (no layer styling), so
  /// it stays small and does not duplicate the full style.
  static const String kStyleUrl = '$kCdnBase/offline_style.json';
}