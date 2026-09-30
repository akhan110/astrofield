import 'dart:math' as math;
import 'package:geoengine/geoengine.dart' as astro;
import '../data/catalog.dart';
import '../domain/field_models.dart';
import '../models/astro_object.dart';

abstract class AstronomyEngine {
  NightReport calculate(Site site, DateTime time, double minimumAltitude);
}

class LocalAstronomyEngine implements AstronomyEngine {
  SkyPosition positionJ2000(
      double raDeg, double decDeg, DateTime time, Site site) {
    astro.defineStar(astro.Body.Star1, raDeg / 15, decDeg, 1000000);
    return position(astro.Body.Star1, time, site);
  }

  SkyPosition positionForObject(AstroObject object, Site site, DateTime time) {
    return positionJ2000(object.raDeg, object.decDeg, time, site);
  }

  TargetPlan planObject(
      AstroObject object, Site site, DateTime time, double threshold) {
    final catalog = CatalogObject(
        object.designation, object.displayName, object.type.name,
        ra: object.raDeg / 15,
        dec: object.decDeg,
        sizeArcmin: object.majorAxisArcmin ?? 0,
        magnitude: object.magnitude,
        constellation: object.constellation ?? '');
    final report = calculateFor(site, time, threshold, [catalog]);
    return report.targets.single;
  }

  NightReport calculateFor(Site site, DateTime time, double threshold,
          List<CatalogObject> objects) =>
      _calculate(site, time, threshold, objects);
  astro.Body _body(CatalogObject object) {
    if (object.isPlanet) {
      return astro.Body.values.firstWhere((b) => b.name == object.id);
    }
    astro.defineStar(astro.Body.Star1, object.ra, object.dec, 1000000);
    return astro.Body.Star1;
  }

  SkyPosition position(astro.Body body, DateTime time, Site site) {
    final observer =
        astro.Observer(site.latitude, site.longitude, site.elevation);
    final eq = astro.equator(body, time.toUtc(), observer, true, true);
    final h = astro.HorizontalCoordinates.horizon(
        time.toUtc(), observer, eq.ra, eq.dec);
    return SkyPosition(h.altitude, h.azimuth, eq.ra, eq.dec);
  }

  static double separation(SkyPosition a, SkyPosition b) {
    final d = math.pi / 180;
    return math.acos((math.sin(a.dec * d) * math.sin(b.dec * d) +
                math.cos(a.dec * d) *
                    math.cos(b.dec * d) *
                    math.cos((a.ra - b.ra) * 15 * d))
            .clamp(-1.0, 1.0)) /
        d;
  }

  // Transparent heuristic, not a measured probability or a weather forecast.
  static int imagingScore(
      double altitude,
      double sunAltitude,
      double moonAltitude,
      double moonFraction,
      double separation,
      double threshold,
      bool planet) {
    if (altitude < threshold || sunAltitude > (planet ? -6 : -18)) return 0;
    final height = math.sin(altitude * math.pi / 180).clamp(0.0, 1.0);
    final moonPenalty = planet || moonAltitude <= 0
        ? 0.0
        : .6 * moonFraction * (1 - separation / 180);
    return (100 * height * (1 - moonPenalty)).round().clamp(0, 100);
  }

  @override
  NightReport calculate(Site site, DateTime time, double minimumAltitude) {
    return _calculate(site, time, minimumAltitude, fieldCatalog);
  }

  NightReport _calculate(Site site, DateTime time, double minimumAltitude,
      List<CatalogObject> objects) {
    if (!site.valid) throw ArgumentError('Invalid observing location');
    final utc = time.toUtc();
    final observer =
        astro.Observer(site.latitude, site.longitude, site.elevation);
    // Solar-noon to solar-noon: independent of phone timezone and DST.
    final solar = utc.add(Duration(seconds: (site.longitude * 240).round()));
    var noon = DateTime.utc(solar.year, solar.month, solar.day, 12);
    if (solar.hour < 12) noon = noon.subtract(const Duration(days: 1));
    final start =
        noon.subtract(Duration(seconds: (site.longitude * 240).round()));
    final end = start.add(const Duration(days: 1));
    final times =
        List.generate(145, (i) => start.add(Duration(minutes: i * 10)));
    final suns = times.map((t) => position(astro.Body.Sun, t, site)).toList();
    final moons = times.map((t) => position(astro.Body.Moon, t, site)).toList();
    final fractions = times
        .map((t) =>
            astro.IlluminationInfo.getBodyIllumination(astro.Body.Moon, t)
                .phaseFraction)
        .toList();
    final sun = position(astro.Body.Sun, utc, site);
    final moon = position(astro.Body.Moon, utc, site);
    final fraction =
        astro.IlluminationInfo.getBodyIllumination(astro.Body.Moon, utc)
            .phaseFraction;
    final targets = <TargetPlan>[];
    for (final object in objects) {
      final body = _body(object);
      final now = position(body, utc, site);
      final sep = separation(now, moon);
      final samples = <SkySample>[];
      for (var i = 0; i < times.length; i++) {
        final p = position(body, times[i], site);
        final s = separation(p, moons[i]);
        samples.add(SkySample(
            times[i],
            p,
            suns[i].altitude,
            s,
            imagingScore(p.altitude, suns[i].altitude, moons[i].altitude,
                fractions[i], s, minimumAltitude, object.isPlanet)));
      }
      final rise =
          astro.searchRiseSet(body, observer, 1, start, 1)?.date.toUtc();
      final set =
          astro.searchRiseSet(body, observer, -1, start, 1)?.date.toUtc();
      // Hour angle is undefined at the geographic poles; sampled peak remains available.
      final transit = site.latitude.abs() > 89.99
          ? null
          : astro.searchHourAngle(body, observer, 0, start).time.date.toUtc();
      targets.add(TargetPlan(
          object: object,
          now: now,
          samples: samples,
          score: imagingScore(now.altitude, sun.altitude, moon.altitude,
              fraction, sep, minimumAltitude, object.isPlanet),
          moonSeparation: sep,
          rise: rise,
          set: set,
          transit: transit,
          windows: _windows(times, samples.map((s) => s.score > 0).toList())));
    }
    final events = <String, DateTime?>{
      'Sunset':
          astro.searchRiseSet(astro.Body.Sun, observer, -1, start, 1)?.date,
      'Sunrise':
          astro.searchRiseSet(astro.Body.Sun, observer, 1, start, 1)?.date,
      'Moonrise':
          astro.searchRiseSet(astro.Body.Moon, observer, 1, start, 1)?.date,
      'Moonset':
          astro.searchRiseSet(astro.Body.Moon, observer, -1, start, 1)?.date,
    };
    for (final entry
        in {'Civil': -6.0, 'Nautical': -12.0, 'Astronomical': -18.0}.entries) {
      events['${entry.key} dusk'] = astro
          .searchAltitude(astro.Body.Sun, observer, -1, start, 1, entry.value)
          ?.date;
      events['${entry.key} dawn'] = astro
          .searchAltitude(astro.Body.Sun, observer, 1, start, 1, entry.value)
          ?.date;
    }
    return NightReport(
        utc,
        start,
        end,
        targets,
        sun,
        moon,
        fraction,
        astro.moonPhase(utc),
        events,
        _windows(times, suns.map((p) => p.altitude <= -18).toList()));
  }

  static List<ImagingWindow> _windows(List<DateTime> times, List<bool> valid) {
    final result = <ImagingWindow>[];
    DateTime? start;
    for (var i = 0; i < times.length; i++) {
      if (valid[i]) start ??= times[i];
      if (start != null && (!valid[i] || i == times.length - 1)) {
        // Conservative sample bounds: never count a failing sample as usable.
        final end = valid[i] ? times[i] : times[i - 1];
        if (end.isAfter(start)) result.add(ImagingWindow(start, end));
        start = null;
      }
    }
    return result;
  }
}

class CalculationRequest {
  const CalculationRequest(this.site, this.time, this.minimumAltitude);
  final Site site;
  final DateTime time;
  final double minimumAltitude;
}

NightReport calculateNight(CalculationRequest request) => LocalAstronomyEngine()
    .calculate(request.site, request.time, request.minimumAltitude);
