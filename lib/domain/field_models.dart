import 'dart:math' as math;

class Site {
  const Site(this.latitude, this.longitude,
      {this.elevation = 0, this.name = 'Observing site'});
  final double latitude, longitude, elevation;
  final String name;
  bool get valid =>
      latitude.isFinite &&
      longitude.isFinite &&
      elevation.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      elevation >= -500 &&
      elevation <= 10000;
  Map<String, Object> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'elevation': elevation,
        'name': name
      };
  factory Site.fromJson(Map<String, dynamic> j) => Site(
      (j['latitude'] as num).toDouble(), (j['longitude'] as num).toDouble(),
      elevation: (j['elevation'] as num).toDouble(), name: j['name'] as String);
}

class CatalogObject {
  const CatalogObject(this.id, this.name, this.type,
      {this.ra = 0, this.dec = 0, this.sizeArcmin = 0, this.magnitude, this.constellation = ''});
  final String id, name, type;
  final double ra, dec, sizeArcmin;
  final double? magnitude;
  final String constellation;
  bool get isPlanet => type == 'Planet';
}

class SkyPosition {
  const SkyPosition(this.altitude, this.azimuth, this.ra, this.dec);
  final double altitude, azimuth, ra, dec;
  String get direction => const [
        'N',
        'NE',
        'E',
        'SE',
        'S',
        'SW',
        'W',
        'NW'
      ][((azimuth + 22.5) / 45).floor() % 8];
}

class SkySample {
  const SkySample(this.time, this.position, this.sunAltitude,
      this.moonSeparation, this.score);
  final DateTime time;
  final SkyPosition position;
  final double sunAltitude, moonSeparation;
  final int score;
}

class ImagingWindow {
  const ImagingWindow(this.start, this.end);
  final DateTime start, end;
  Duration get duration => end.difference(start);
}

class TargetPlan {
  const TargetPlan(
      {required this.object,
      required this.now,
      required this.samples,
      required this.score,
      required this.moonSeparation,
      required this.rise,
      required this.set,
      required this.transit,
      required this.windows});
  final CatalogObject object;
  final SkyPosition now;
  final List<SkySample> samples;
  final int score;
  final double moonSeparation;
  final DateTime? rise, set, transit;
  final List<ImagingWindow> windows;
  SkySample get peak => samples
      .reduce((a, b) => a.position.altitude > b.position.altitude ? a : b);
  int get nightScore => samples.map((s) => s.score).reduce(math.max);
  ImagingWindow? get bestWindow => windows.isEmpty
      ? null
      : windows.reduce((a, b) => a.duration > b.duration ? a : b);
}

class NightReport {
  const NightReport(
      this.time,
      this.start,
      this.end,
      this.targets,
      this.sun,
      this.moon,
      this.moonIllumination,
      this.moonPhase,
      this.events,
      this.darkness);
  final DateTime time, start, end;
  final List<TargetPlan> targets;
  final SkyPosition sun, moon;
  final double moonIllumination, moonPhase;
  final Map<String, DateTime?> events;
  final List<ImagingWindow> darkness;
}

class Equipment {
  const Equipment(
      this.name, this.width, this.height, this.focalLength, this.pixelSize);
  final String name;
  final double width, height, focalLength, pixelSize;
  bool get valid =>
      name.trim().isNotEmpty &&
      [width, height, focalLength, pixelSize].every((n) => n.isFinite && n > 0);
  double get horizontalFov =>
      2 * math.atan(width / (2 * focalLength)) * 180 / math.pi;
  double get verticalFov =>
      2 * math.atan(height / (2 * focalLength)) * 180 / math.pi;
  double get imageScale => 206.264806 * pixelSize / focalLength;
  Map<String, Object> toJson() => {
        'name': name,
        'width': width,
        'height': height,
        'focal': focalLength,
        'pixel': pixelSize
      };
  factory Equipment.fromJson(Map<String, dynamic> j) => Equipment(
      j['name'] as String,
      (j['width'] as num).toDouble(),
      (j['height'] as num).toDouble(),
      (j['focal'] as num).toDouble(),
      (j['pixel'] as num).toDouble());
}

String clockTime(DateTime? t) {
  if (t == null) return 'No event in this period';
  final l = t.toLocal();
  final hour12 = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final period = l.hour >= 12 ? 'PM' : 'AM';
  return '${l.month}/${l.day} $hour12:${l.minute.toString().padLeft(2, '0')} $period';
}

String durationText(Duration d) =>
    '${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m';
