import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import '../models/astro_object.dart';
import 'catalog_schema.dart';
import '../domain/field_models.dart';
import '../services/catalog_position_service.dart';

enum CatalogSort { designation, name, magnitude, size, altitude, transit }

class CatalogFilter {
  const CatalogFilter(
      {this.query = '',
      this.types = const [],
      this.constellation,
      this.maxMagnitude,
      this.minAltitude,
      this.visibleNow = false,
      this.savedOnly = false,
      this.cacheKey,
      this.sort = CatalogSort.designation});
  final String query;
  final List<AstroObjectType> types;
  final String? constellation;
  final double? maxMagnitude, minAltitude;
  final bool visibleNow, savedOnly;
  final String? cacheKey;
  final CatalogSort sort;
}

class AstroObjectRepository {
  AstroObjectRepository._(this.db);
  final Database db;
  static final Map<String, Future<void>> _positionJobs = {};
  static Future<AstroObjectRepository>? _shared;
  static Future<AstroObjectRepository> shared() =>
      _shared ??= open().catchError((Object error) {
        _shared = null;
        throw error;
      });
  static Future<AstroObjectRepository> open({String? testPath}) async {
    if (testPath != null ||
        (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.windows ||
                defaultTargetPlatform == TargetPlatform.linux))) {
      ffi.sqfliteFfiInit();
    }
    final factory = (testPath != null ||
            (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.windows ||
                    defaultTargetPlatform == TargetPlatform.linux)))
        ? ffi.databaseFactoryFfi
        : databaseFactory;
    final base = testPath ??
        p.join(
            await factory.getDatabasesPath(), 'astrofield_catalog_v1.sqlite');
    if (testPath == null && !await File(base).exists()) {
      await Directory(p.dirname(base)).create(recursive: true);
      final bytes = await rootBundle.load('assets/catalog/astrofield.sqlite');
      await File(base).writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          flush: true);
    }
    final db = await factory.openDatabase(base,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (d, _) async {
              await createCatalogSchema(d);
            },
            onOpen: (d) async {
              await d.execute('PRAGMA foreign_keys=ON');
              await d.execute(
                  'CREATE TABLE IF NOT EXISTS observation_cache (cache_key TEXT NOT NULL, object_id TEXT NOT NULL, altitude REAL NOT NULL, azimuth REAL NOT NULL, transit_minutes REAL NOT NULL, PRIMARY KEY(cache_key,object_id))');
              await d.execute(
                  'CREATE INDEX IF NOT EXISTS idx_observation_alt ON observation_cache(cache_key,altitude)');
              await d.execute(
                  'CREATE INDEX IF NOT EXISTS idx_observation_transit ON observation_cache(cache_key,transit_minutes)');
              await d.execute(
                  'CREATE TABLE IF NOT EXISTS observation_cache_metadata (cache_key TEXT PRIMARY KEY, completed_at TEXT NOT NULL)');
            }));
    return AstroObjectRepository._(db);
  }

  Future<void> close() => db.close();

  static String cacheKey(Site site, DateTime time) =>
      '${site.latitude.toStringAsFixed(5)}:${site.longitude.toStringAsFixed(5)}:${site.elevation.round()}:${time.toUtc().millisecondsSinceEpoch ~/ 300000}';

  Future<void> ensureObservationCache(Site site, DateTime time) async {
    final key = cacheKey(site, time);
    final existing = await db.rawQuery(
        'SELECT 1 FROM observation_cache_metadata WHERE cache_key=? LIMIT 1',
        [key]);
    if (existing.isNotEmpty) return;
    final job = _positionJobs[key];
    if (job != null) return job;
    final result = _buildObservationCache(site, time, key);
    _positionJobs[key] = result;
    try {
      await result;
    } finally {
      _positionJobs.remove(key);
    }
  }

  Future<void> _buildObservationCache(
      Site site, DateTime time, String key) async {
    var offset = 0;
    while (true) {
      final rows = await db.rawQuery(
          'SELECT id,ra_deg,dec_deg FROM astro_objects ORDER BY id LIMIT 500 OFFSET ?',
          [offset]);
      if (rows.isEmpty) break;
      final positions = await compute(
          calculateCatalogPositions, CatalogPositionRequest(site, time, rows));
      final batch = db.batch();
      for (final position in positions) {
        batch.insert('observation_cache', {'cache_key': key, ...position},
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      offset += rows.length;
    }
    await db.insert(
        'observation_cache_metadata',
        {
          'cache_key': key,
          'completed_at': DateTime.now().toUtc().toIso8601String()
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
    final keys = await db.rawQuery(
        'SELECT cache_key FROM observation_cache_metadata ORDER BY completed_at DESC LIMIT 2');
    final keep = keys.map((r) => r['cache_key'] as String).toList();
    if (keep.isNotEmpty) {
      await db.rawDelete(
          'DELETE FROM observation_cache WHERE cache_key NOT IN (${List.filled(keep.length, '?').join(',')})',
          keep);
    }
    if (keep.isNotEmpty) {
      await db.rawDelete(
          'DELETE FROM observation_cache_metadata WHERE cache_key NOT IN (${List.filled(keep.length, '?').join(',')})',
          keep);
    }
  }

  static String _fts(String value) => value
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((s) => s.isNotEmpty)
      .map((s) => '$s*')
      .join(' ');
  ({String where, List<Object?> args}) _where(CatalogFilter filter) {
    final parts = <String>[];
    final args = <Object?>[];
    final q = filter.query.trim();
    if (q.isNotEmpty) {
      final normalized = normalizeCatalogQuery(q);
      final fts = _fts(q);
      parts.add(
          '(o.id IN (SELECT object_id FROM object_aliases WHERE normalized_alias = ? OR normalized_alias LIKE ?) OR o.id IN (SELECT object_id FROM object_search WHERE object_search MATCH ?) OR lower(o.constellation) LIKE ? OR lower(o.object_type) LIKE ?)');
      args.addAll([
        normalized,
        '$normalized%',
        fts,
        '%${q.toLowerCase()}%',
        '%${q.toLowerCase()}%'
      ]);
    }
    if (filter.types.isNotEmpty) {
      parts.add(
          'o.object_type IN (${List.filled(filter.types.length, '?').join(',')})');
      args.addAll(filter.types.map((t) => t.name));
    }
    if (filter.constellation != null) {
      parts.add('o.constellation=?');
      args.add(filter.constellation);
    }
    if (filter.maxMagnitude != null) {
      parts.add('o.magnitude <= ?');
      args.add(filter.maxMagnitude);
    }
    if (filter.savedOnly) {
      parts.add('EXISTS (SELECT 1 FROM favorites f WHERE f.object_id=o.id)');
    }
    if (filter.cacheKey != null &&
        (filter.visibleNow || filter.minAltitude != null)) {
      parts.add(
          'o.id IN (SELECT object_id FROM observation_cache WHERE cache_key=? AND altitude>=?)');
      args.addAll([filter.cacheKey, filter.minAltitude ?? 0.0]);
    }
    return (
      where: parts.isEmpty ? '' : 'WHERE ${parts.join(' AND ')}',
      args: args
    );
  }

  Future<int> countObjects(CatalogFilter filter) async {
    final w = _where(filter);
    final result = await db.rawQuery(
        'SELECT COUNT(*) AS n FROM astro_objects o ${w.where}', w.args);
    return (result.first['n'] as int?) ?? 0;
  }

  Future<List<AstroObject>> searchObjects(CatalogFilter filter,
      {int limit = 50, int offset = 0}) async {
    if (limit < 1 || limit > 100 || offset < 0) {
      throw ArgumentError('Invalid pagination');
    }
    final w = _where(filter);
    final q = normalizeCatalogQuery(filter.query.trim());
    final rank = q.isEmpty
        ? 'CASE WHEN 1=1 THEN 0 END'
        : '''CASE
      WHEN EXISTS(SELECT 1 FROM catalog_identifiers ci WHERE ci.object_id=o.id AND ci.normalized_designation=?) THEN 0
      WHEN lower(o.common_name)=? THEN 1
      WHEN EXISTS(SELECT 1 FROM object_aliases a WHERE a.object_id=o.id AND a.normalized_alias=?) THEN 2
      WHEN EXISTS(SELECT 1 FROM object_aliases a WHERE a.object_id=o.id AND a.normalized_alias LIKE ?) THEN 3
      ELSE 4 END''';
    final order = switch (filter.sort) {
      CatalogSort.name =>
        'o.common_name COLLATE NOCASE, o.primary_name COLLATE NOCASE',
      CatalogSort.magnitude =>
        'o.magnitude IS NULL, o.magnitude, o.primary_name COLLATE NOCASE',
      CatalogSort.size =>
        'o.major_axis_arcmin IS NULL, o.major_axis_arcmin DESC, o.primary_name COLLATE NOCASE',
      CatalogSort.altitude when filter.cacheKey != null =>
        '(SELECT altitude FROM observation_cache WHERE object_id=o.id AND cache_key=?) DESC, o.primary_name COLLATE NOCASE',
      CatalogSort.transit when filter.cacheKey != null =>
        '(SELECT transit_minutes FROM observation_cache WHERE object_id=o.id AND cache_key=?), o.primary_name COLLATE NOCASE',
      _ =>
        '''CASE WHEN o.primary_name GLOB 'M[0-9]*' THEN 0 WHEN o.primary_name LIKE 'NGC%' THEN 1 WHEN o.primary_name LIKE 'IC%' THEN 2 ELSE 3 END,
           CASE WHEN o.primary_name GLOB 'M[0-9]*' THEN CAST(substr(o.primary_name,2) AS INTEGER)
                WHEN o.primary_name LIKE 'NGC%' THEN CAST(substr(o.primary_name,4) AS INTEGER)
                WHEN o.primary_name LIKE 'IC%' THEN CAST(substr(o.primary_name,3) AS INTEGER) ELSE 0 END,
           o.primary_name COLLATE NOCASE''',
    };
    final args = <Object?>[
      ...w.args,
      if (q.isNotEmpty) ...[q, filter.query.trim().toLowerCase(), q, '$q%'],
      if (filter.cacheKey != null &&
          (filter.sort == CatalogSort.altitude ||
              filter.sort == CatalogSort.transit))
        filter.cacheKey,
      limit,
      offset
    ];
    final rows = await db.rawQuery(
        'SELECT o.* FROM astro_objects o ${w.where} ORDER BY $rank, $order LIMIT ? OFFSET ?',
        args);
    return _hydrate(rows);
  }

  Future<List<AstroObject>> _hydrate(List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return [];
    final ids = rows.map((r) => r['id'] as String).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final aliasRows = await db.rawQuery(
        'SELECT object_id,alias FROM object_aliases WHERE object_id IN ($placeholders)',
        ids);
    final idRows = await db.rawQuery(
        'SELECT object_id,catalog,designation FROM catalog_identifiers WHERE object_id IN ($placeholders)',
        ids);
    final aliases = <String, List<String>>{},
        identifiers = <String, List<CatalogIdentifier>>{};
    for (final a in aliasRows) {
      aliases
          .putIfAbsent(a['object_id'] as String, () => [])
          .add(a['alias'] as String);
    }
    for (final a in idRows) {
      identifiers.putIfAbsent(a['object_id'] as String, () => []).add(
          CatalogIdentifier(
              a['catalog'] as String, a['designation'] as String));
    }
    return rows
        .map((r) => AstroObject.fromRow(r,
            aliases: aliases[r['id']] ?? [],
            identifiers: identifiers[r['id']] ?? []))
        .toList();
  }

  Future<AstroObject?> getById(String value) async {
    final key = normalizeCatalogQuery(value);
    final rows = await db.rawQuery(
        'SELECT o.* FROM astro_objects o WHERE o.id=? OR o.id IN (SELECT object_id FROM object_aliases WHERE normalized_alias=?) LIMIT 1',
        [value, key]);
    final objects = await _hydrate(rows);
    return objects.firstOrNull;
  }

  Future<List<String>> getAliases(String id) async =>
      (await db.query('object_aliases',
              columns: ['alias'], where: 'object_id=?', whereArgs: [id]))
          .map((r) => r['alias'] as String)
          .toList();
  Future<List<CatalogIdentifier>> getCatalogIdentifiers(String id) async =>
      (await db.query('catalog_identifiers',
              columns: ['catalog', 'designation'],
              where: 'object_id=?',
              whereArgs: [id]))
          .map((r) => CatalogIdentifier(
              r['catalog'] as String, r['designation'] as String))
          .toList();
  Future<bool> isFavorite(String id) async => (await db
          .rawQuery('SELECT 1 FROM favorites WHERE object_id=? LIMIT 1', [id]))
      .isNotEmpty;
  Future<void> setFavorite(String id, bool saved) async {
    if (saved) {
      await db.insert(
          'favorites',
          {
            'object_id': id,
            'created_at': DateTime.now().toUtc().toIso8601String()
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete('favorites', where: 'object_id=?', whereArgs: [id]);
    }
  }

  Future<Set<String>> favoriteIds() async =>
      (await db.query('favorites', columns: ['object_id']))
          .map((r) => r['object_id'] as String)
          .toSet();
  Future<List<String>> constellations() async => (await db.rawQuery(
          'SELECT DISTINCT constellation FROM astro_objects WHERE constellation IS NOT NULL ORDER BY constellation'))
      .map((r) => r['constellation'] as String)
      .toList();
}
