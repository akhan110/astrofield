import 'package:geoengine/geoengine.dart' as astro;
import '../domain/field_models.dart';
import 'astronomy_engine.dart';

class CatalogPositionRequest {
  const CatalogPositionRequest(this.site, this.time, this.rows);
  final Site site;
  final DateTime time;
  final List<Map<String, Object?>> rows;
}

List<Map<String, Object?>> calculateCatalogPositions(
    CatalogPositionRequest request) {
  final result = <Map<String, Object?>>[];
  final engine = LocalAstronomyEngine();
  final localSidereal =
      (astro.siderealTime(astro.AstroTime(request.time.toUtc())) +
              request.site.longitude / 15) %
          24;
  for (final row in request.rows) {
    final position = engine.positionJ2000((row['ra_deg'] as num).toDouble(),
        (row['dec_deg'] as num).toDouble(), request.time, request.site);
    // Difference in sidereal hours converted to elapsed civil minutes.
    final siderealHours = (position.ra - localSidereal + 24) % 24;
    final transitMinutes = siderealHours / 1.00273790935 * 60;
    result.add({
      'object_id': row['id'] as String,
      'altitude': position.altitude,
      'azimuth': position.azimuth,
      'transit_minutes': transitMinutes
    });
  }
  return result;
}
