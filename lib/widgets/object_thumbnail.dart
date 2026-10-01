import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const Map<int, int> _ngcToMessier = {
  1952: 1, 7089: 2, 5272: 3, 6121: 4, 5904: 5, 6405: 6, 6475: 7, 6523: 8,
  6333: 9, 6254: 10, 6705: 11, 6218: 12, 6205: 13, 6402: 14, 7078: 15,
  6611: 16, 6618: 17, 6613: 18, 6273: 19, 6514: 20, 6531: 21, 6656: 22,
  6494: 23, 6694: 26, 6853: 27, 6626: 28, 6913: 29, 7099: 30, 224: 31,
  221: 32, 598: 33, 1039: 34, 2168: 35, 1960: 36, 2099: 37, 1912: 38,
  7092: 39, 2287: 41, 1976: 42, 1982: 43, 2632: 44, 2437: 46, 2422: 47,
  2548: 48, 4472: 49, 2323: 50, 5194: 51, 7654: 52, 5024: 53, 6715: 54,
  6809: 55, 6779: 56, 6720: 57, 4579: 58, 4621: 59, 4649: 60, 4303: 61,
  6266: 62, 5055: 63, 4826: 64, 3623: 65, 3627: 66, 2682: 67, 4590: 68,
  6637: 69, 6681: 70, 6838: 71, 6981: 72, 6994: 73, 628: 74, 6864: 75,
  650: 76, 1068: 77, 2068: 78, 1904: 79, 6093: 80, 3031: 81, 3034: 82,
  5236: 83, 4374: 84, 4382: 85, 4406: 86, 4486: 87, 4501: 88, 4552: 89,
  4569: 90, 4548: 91, 6341: 92, 2447: 93, 4736: 94, 3351: 95, 3368: 96,
  3587: 97, 4192: 98, 4254: 99, 4321: 100, 5457: 101, 581: 103, 4594: 104,
  3379: 105, 4258: 106, 6171: 107, 3556: 108, 3992: 109, 205: 110,
};

const Map<int, int> _icToMessier = {
  4715: 24,
  4725: 25,
};

/// Resolves an asset thumbnail path for a celestial object, if available.
String? resolveObjectThumbnail({String? id, String? catalog, String? name}) {
  final candidates = [id, catalog, name];
  for (final candidate in candidates) {
    if (candidate == null || candidate.trim().isEmpty) continue;
    // Check direct M designation like M42, M 42, Messier 42
    final mMatch = RegExp(r'\b(?:M|Messier)\s*(\d{1,3})\b', caseSensitive: false)
        .firstMatch(candidate);
    if (mMatch != null) {
      final num = int.tryParse(mMatch.group(1)!);
      if (num != null && num >= 1 && num <= 110) {
        return 'assets/catalog/thumbnails/M$num.jpg';
      }
    }
    // Check NGC cross references
    final ngcMatch =
        RegExp(r'\bNGC\s*(\d+)\b', caseSensitive: false).firstMatch(candidate);
    if (ngcMatch != null) {
      final ngcNum = int.tryParse(ngcMatch.group(1)!);
      if (ngcNum != null && _ngcToMessier.containsKey(ngcNum)) {
        final m = _ngcToMessier[ngcNum]!;
        return 'assets/catalog/thumbnails/M$m.jpg';
      }
    }
    // Check IC cross references
    final icMatch =
        RegExp(r'\bIC\s*(\d+)\b', caseSensitive: false).firstMatch(candidate);
    if (icMatch != null) {
      final icNum = int.tryParse(icMatch.group(1)!);
      if (icNum != null && _icToMessier.containsKey(icNum)) {
        final m = _icToMessier[icNum]!;
        return 'assets/catalog/thumbnails/M$m.jpg';
      }
    }
  }
  return null;
}

/// A thumbnail widget that renders high-quality astrophotography DSS2 cutouts
/// with smooth rounded borders and graceful icon placeholder fallback.
class ObjectThumbnail extends StatelessWidget {
  const ObjectThumbnail({
    super.key,
    this.id,
    this.catalog,
    this.name,
    this.size = 46.0,
    this.borderRadius = 12.0,
    this.accentColor,
    this.fallbackIcon = Icons.auto_awesome,
    this.isCircle = false,
  });

  final String? id;
  final String? catalog;
  final String? name;
  final double size;
  final double borderRadius;
  final Color? accentColor;
  final IconData fallbackIcon;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    final thumbnail = resolveObjectThumbnail(id: id, catalog: catalog, name: name);
    final accent = accentColor ?? AppColors.primary;
    final radius = isCircle ? BorderRadius.circular(size / 2) : BorderRadius.circular(borderRadius);

    Widget placeholder() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: radius,
            border: Border.all(
              color: accent.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              fallbackIcon,
              color: accent,
              size: size * 0.48,
            ),
          ),
        );

    if (thumbnail == null) {
      return placeholder();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: isCircle ? BorderRadius.circular(size / 2) : BorderRadius.circular(borderRadius - 1),
        child: Image.asset(
          thumbnail,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 2).toInt(),
          cacheHeight: (size * 2).toInt(),
          errorBuilder: (_, __, ___) => placeholder(),
        ),
      ),
    );
  }
}
