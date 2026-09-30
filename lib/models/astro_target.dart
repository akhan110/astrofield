import 'package:flutter/material.dart';

class AstroTarget {
  const AstroTarget({
    required this.catalog,
    required this.name,
    required this.type,
    required this.constellation,
    required this.score,
    required this.altitude,
    required this.azimuth,
    required this.bestWindow,
    required this.magnitude,
    required this.accent,
    required this.icon,
    this.isFavorite = false,
  });

  final String catalog;
  final String name;
  final String type;
  final String constellation;
  final int score;
  final double altitude;
  final String azimuth;
  final String bestWindow;
  final double magnitude;
  final Color accent;
  final IconData icon;
  final bool isFavorite;

  String get bestWindowDuration {
    final parts = bestWindow.split('-').map((part) => part.trim()).toList();
    if (parts.length != 2) return 'Unavailable';

    final start = _minutesSinceMidnight(parts[0]);
    final end = _minutesSinceMidnight(parts[1]);
    if (start == null || end == null) return 'Unavailable';

    final totalMinutes = (end - start + 24 * 60) % (24 * 60);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  static int? _minutesSinceMidnight(String value) {
    final trimmed = value.trim();
    final isPm = trimmed.toUpperCase().endsWith('PM');
    final isAm = trimmed.toUpperCase().endsWith('AM');
    final clean = trimmed.replaceAll(RegExp(r'[a-zA-Z]'), '').trim();
    final parts = clean.split(':');
    if (parts.length != 2) return null;

    var hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) return null;
    if (minute < 0 || minute > 59) return null;

    if (isPm || isAm) {
      if (hour < 1 || hour > 12) return null;
      if (isPm && hour != 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
    } else {
      if (hour < 0 || hour > 23) return null;
    }
    return hour * 60 + minute;
  }

  static String constellationFor(String id) {
    const map = {
      'M42': 'Orion',
      'M45': 'Taurus',
      'M31': 'Andromeda',
      'M33': 'Triangulum',
      'M1': 'Taurus',
      'NGC 2237': 'Monoceros',
      'B33': 'Orion',
      'M81': 'Ursa Major',
      'M82': 'Ursa Major',
      'M51': 'Canes Venatici',
      'M101': 'Ursa Major',
      'M13': 'Hercules',
      'M8': 'Sagittarius',
      'M20': 'Sagittarius',
      'M16': 'Serpens',
      'M17': 'Sagittarius',
      'M27': 'Vulpecula',
      'M57': 'Lyra',
      'NGC 7000': 'Cygnus',
      'NGC 869': 'Perseus',
      'NGC 5139': 'Centaurus',
      'NGC 104': 'Tucana',
      'NGC 3372': 'Carina',
      'NGC 253': 'Sculptor',
      'NGC 5128': 'Centaurus',
    };
    return map[id] ?? 'Solar System';
  }

  static Color accentFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('galaxy')) return const Color(0xFF8C52FF);
    if (t.contains('cluster')) return const Color(0xFF00E5A3);
    if (t.contains('planet')) return const Color(0xFFFFB020);
    if (t.contains('supernova')) return const Color(0xFF8FD4FF);
    return const Color(0xFF4D8BFF);
  }

  static IconData iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('galaxy')) return Icons.all_inclusive_rounded;
    if (t.contains('cluster')) return Icons.auto_awesome_rounded;
    if (t.contains('planet')) return Icons.circle;
    if (t.contains('supernova')) return Icons.flare_rounded;
    return Icons.blur_on_rounded;
  }

  factory AstroTarget.fromCatalogObject(dynamic obj, {bool isFavorite = false}) {
    final id = obj.id as String;
    final name = obj.name as String;
    final type = obj.type as String;
    final mag = (obj.magnitude as num?)?.toDouble() ?? 0.0;
    final cName = (obj.constellation as String? ?? '').trim();
    return AstroTarget(
      catalog: id,
      name: name,
      type: type,
      constellation: cName.isNotEmpty ? cName : constellationFor(id),
      score: 85,
      altitude: 45.0,
      azimuth: 'SE',
      bestWindow: '10:00 PM - 03:00 AM',
      magnitude: mag,
      accent: accentFor(type),
      icon: iconFor(type),
      isFavorite: isFavorite,
    );
  }

  factory AstroTarget.fromTargetPlan(dynamic plan, {bool isFavorite = false}) {
    final obj = plan.object;
    final id = obj.id as String;
    final name = obj.name as String;
    final type = obj.type as String;
    final now = plan.now;
    final mag = (obj.magnitude as num?)?.toDouble() ?? 0.0;
    final window = plan.bestWindow;
    final cName = (obj.constellation as String? ?? '').trim();
    String windowText = 'Unavailable';
    if (window != null) {
      final s = window.start.toLocal();
      final e = window.end.toLocal();
      final sh = s.hour % 12 == 0 ? 12 : s.hour % 12;
      final sp = s.hour >= 12 ? 'PM' : 'AM';
      final eh = e.hour % 12 == 0 ? 12 : e.hour % 12;
      final ep = e.hour >= 12 ? 'PM' : 'AM';
      windowText =
          '$sh:${s.minute.toString().padLeft(2, '0')} $sp - $eh:${e.minute.toString().padLeft(2, '0')} $ep';
    }
    return AstroTarget(
      catalog: id,
      name: name,
      type: type,
      constellation: cName.isNotEmpty ? cName : constellationFor(id),
      score: plan.score as int,
      altitude: now.altitude as double,
      azimuth: now.direction as String,
      bestWindow: windowText,
      magnitude: mag,
      accent: accentFor(type),
      icon: iconFor(type),
      isFavorite: isFavorite,
    );
  }
}
