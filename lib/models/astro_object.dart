enum AstroObjectType {
  galaxy,
  emissionNebula,
  reflectionNebula,
  planetaryNebula,
  darkNebula,
  openCluster,
  globularCluster,
  supernovaRemnant,
  star,
  doubleStar,
  other;
}

class CatalogIdentifier {
  const CatalogIdentifier(this.catalog, this.designation);
  final String catalog;
  final String designation;
}

class AstroObject {
  const AstroObject(
      {required this.id,
      required this.primaryName,
      required this.type,
      required this.raDeg,
      required this.decDeg,
      this.commonName,
      this.constellation,
      this.magnitude,
      this.surfaceBrightness,
      this.majorAxisArcmin,
      this.minorAxisArcmin,
      this.positionAngleDeg,
      this.distanceLy,
      this.redshift,
      this.notes,
      this.sourceCatalog,
      this.sourceVersion,
      this.aliases = const [],
      this.identifiers = const []});
  final String id, primaryName;
  final String? commonName, constellation, notes, sourceCatalog, sourceVersion;
  final AstroObjectType type;
  final double raDeg, decDeg;
  final double? magnitude,
      surfaceBrightness,
      majorAxisArcmin,
      minorAxisArcmin,
      positionAngleDeg,
      distanceLy,
      redshift;
  final List<String> aliases;
  final List<CatalogIdentifier> identifiers;
  String get displayName =>
      commonName?.isNotEmpty == true ? commonName! : primaryName;
  String get designation => primaryName;
  factory AstroObject.fromRow(Map<String, Object?> r,
          {List<String> aliases = const [],
          List<CatalogIdentifier> identifiers = const []}) =>
      AstroObject(
        id: r['id'] as String,
        primaryName: r['primary_name'] as String,
        commonName: r['common_name'] as String?,
        type: AstroObjectType.values.byName(r['object_type'] as String),
        constellation: r['constellation'] as String?,
        raDeg: (r['ra_deg'] as num).toDouble(),
        decDeg: (r['dec_deg'] as num).toDouble(),
        magnitude: (r['magnitude'] as num?)?.toDouble(),
        surfaceBrightness: (r['surface_brightness'] as num?)?.toDouble(),
        majorAxisArcmin: (r['major_axis_arcmin'] as num?)?.toDouble(),
        minorAxisArcmin: (r['minor_axis_arcmin'] as num?)?.toDouble(),
        positionAngleDeg: (r['position_angle_deg'] as num?)?.toDouble(),
        distanceLy: (r['distance_ly'] as num?)?.toDouble(),
        redshift: (r['redshift'] as num?)?.toDouble(),
        notes: r['notes'] as String?,
        sourceCatalog: r['source_catalog'] as String?,
        sourceVersion: r['source_version'] as String?,
        aliases: aliases,
        identifiers: identifiers,
      );
}

String normalizeCatalogQuery(String input) {
  var value = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  value = value.replaceFirst(RegExp(r'^messier(?=\d)'), 'm');
  value = value.replaceFirst(RegExp(r'^barnard(?=\d)'), 'b');
  value = value.replaceFirst(RegExp(r'^sharpless(?=\d)'), 'sh2');
  return value;
}
