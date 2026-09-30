import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> createCatalogSchema(DatabaseExecutor db) async {
  await db.execute('PRAGMA foreign_keys=ON');
  await db.execute('CREATE TABLE IF NOT EXISTS astro_objects (id TEXT PRIMARY KEY, primary_name TEXT NOT NULL, common_name TEXT, object_type TEXT NOT NULL, constellation TEXT, ra_deg REAL NOT NULL CHECK(ra_deg>=0 AND ra_deg<360), dec_deg REAL NOT NULL CHECK(dec_deg>=-90 AND dec_deg<=90), magnitude REAL, surface_brightness REAL, major_axis_arcmin REAL, minor_axis_arcmin REAL, position_angle_deg REAL, distance_ly REAL, redshift REAL, notes TEXT, source_catalog TEXT NOT NULL, source_version TEXT NOT NULL)');
  await db.execute('CREATE TABLE IF NOT EXISTS object_aliases (id INTEGER PRIMARY KEY, object_id TEXT NOT NULL REFERENCES astro_objects(id) ON DELETE CASCADE, alias TEXT NOT NULL, normalized_alias TEXT NOT NULL, UNIQUE(object_id, normalized_alias))');
  await db.execute('CREATE TABLE IF NOT EXISTS catalog_identifiers (id INTEGER PRIMARY KEY, object_id TEXT NOT NULL REFERENCES astro_objects(id) ON DELETE CASCADE, catalog TEXT NOT NULL, designation TEXT NOT NULL, number TEXT, normalized_designation TEXT NOT NULL, UNIQUE(object_id, normalized_designation))');
  await db.execute('CREATE TABLE IF NOT EXISTS object_photometry (object_id TEXT PRIMARY KEY REFERENCES astro_objects(id) ON DELETE CASCADE, magnitude_v REAL, magnitude_b REAL, surface_brightness REAL)');
  await db.execute('CREATE TABLE IF NOT EXISTS object_metadata (object_id TEXT PRIMARY KEY REFERENCES astro_objects(id) ON DELETE CASCADE, source_catalog TEXT NOT NULL, source_version TEXT NOT NULL, source_identifier TEXT)');
  await db.execute('CREATE TABLE IF NOT EXISTS favorites (object_id TEXT PRIMARY KEY REFERENCES astro_objects(id) ON DELETE CASCADE, created_at TEXT NOT NULL)');
  await db.execute('CREATE TABLE IF NOT EXISTS planned_targets (object_id TEXT PRIMARY KEY REFERENCES astro_objects(id) ON DELETE CASCADE, created_at TEXT NOT NULL)');
  for (final statement in [
    'CREATE INDEX IF NOT EXISTS idx_objects_ra ON astro_objects(ra_deg)',
    'CREATE INDEX IF NOT EXISTS idx_objects_dec ON astro_objects(dec_deg)',
    'CREATE INDEX IF NOT EXISTS idx_objects_type ON astro_objects(object_type)',
    'CREATE INDEX IF NOT EXISTS idx_objects_const ON astro_objects(constellation)',
    'CREATE INDEX IF NOT EXISTS idx_objects_mag ON astro_objects(magnitude)',
    'CREATE INDEX IF NOT EXISTS idx_alias_normalized ON object_aliases(normalized_alias)',
    'CREATE INDEX IF NOT EXISTS idx_identifier_normalized ON catalog_identifiers(normalized_designation)',
  ]) {await db.execute(statement);}
  await db.execute('CREATE VIRTUAL TABLE IF NOT EXISTS object_search USING fts5(object_id UNINDEXED, search_text, tokenize="unicode61 remove_diacritics 2")');
}
