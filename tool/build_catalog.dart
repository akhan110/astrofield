// Run from the Flutter project root: dart run tool/build_catalog.dart
// Input: assets/catalog/openngc.csv (OpenNGC master CSV).
// Output: assets/catalog/astrofield.sqlite, copied on first app launch.
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:astrofield_ui/data/catalog_schema.dart';
import 'package:astrofield_ui/models/astro_object.dart';

const sourceVersion = 'OpenNGC master downloaded 2026-09-30';
const constellations = <String, String>{
  'And': 'Andromeda',
  'Aqr': 'Aquarius',
  'Aql': 'Aquila',
  'Ara': 'Ara',
  'Ari': 'Aries',
  'Aur': 'Auriga',
  'Boo': 'Boötes',
  'Cae': 'Caelum',
  'Cam': 'Camelopardalis',
  'Cnc': 'Cancer',
  'CVn': 'Canes Venatici',
  'CMa': 'Canis Major',
  'CMi': 'Canis Minor',
  'Cap': 'Capricornus',
  'Car': 'Carina',
  'Cas': 'Cassiopeia',
  'Cen': 'Centaurus',
  'Cep': 'Cepheus',
  'Cet': 'Cetus',
  'Cha': 'Chamaeleon',
  'Cir': 'Circinus',
  'Col': 'Columba',
  'Com': 'Coma Berenices',
  'CrA': 'Corona Australis',
  'CrB': 'Corona Borealis',
  'Crv': 'Corvus',
  'Crt': 'Crater',
  'Cru': 'Crux',
  'Cyg': 'Cygnus',
  'Del': 'Delphinus',
  'Dor': 'Dorado',
  'Dra': 'Draco',
  'Equ': 'Equuleus',
  'Eri': 'Eridanus',
  'For': 'Fornax',
  'Gem': 'Gemini',
  'Gru': 'Grus',
  'Her': 'Hercules',
  'Hor': 'Horologium',
  'Hya': 'Hydra',
  'Hyi': 'Hydrus',
  'Ind': 'Indus',
  'Lac': 'Lacerta',
  'Leo': 'Leo',
  'LMi': 'Leo Minor',
  'Lep': 'Lepus',
  'Lib': 'Libra',
  'Lup': 'Lupus',
  'Lyn': 'Lynx',
  'Lyr': 'Lyra',
  'Men': 'Mensa',
  'Mic': 'Microscopium',
  'Mon': 'Monoceros',
  'Mus': 'Musca',
  'Nor': 'Norma',
  'Oct': 'Octans',
  'Oph': 'Ophiuchus',
  'Ori': 'Orion',
  'Pav': 'Pavo',
  'Peg': 'Pegasus',
  'Per': 'Perseus',
  'Phe': 'Phoenix',
  'Pic': 'Pictor',
  'Psc': 'Pisces',
  'PsA': 'Piscis Austrinus',
  'Pup': 'Puppis',
  'Pyx': 'Pyxis',
  'Ret': 'Reticulum',
  'Sge': 'Sagitta',
  'Sgr': 'Sagittarius',
  'Sco': 'Scorpius',
  'Scl': 'Sculptor',
  'Sct': 'Scutum',
  'Ser': 'Serpens',
  'Sex': 'Sextans',
  'Tau': 'Taurus',
  'Tel': 'Telescopium',
  'Tri': 'Triangulum',
  'TrA': 'Triangulum Australe',
  'Tuc': 'Tucana',
  'UMa': 'Ursa Major',
  'UMi': 'Ursa Minor',
  'Vel': 'Vela',
  'Vir': 'Virgo',
  'Vol': 'Volans',
  'Vul': 'Vulpecula'
};

double? number(String? value) =>
    value == null || value.isEmpty ? null : double.tryParse(value);
double? ra(String value) {
  final p = value.split(':');
  if (p.length != 3) return null;
  final h = double.tryParse(p[0]),
      m = double.tryParse(p[1]),
      s = double.tryParse(p[2]);
  return h == null || m == null || s == null
      ? null
      : (h + m / 60 + s / 3600) * 15;
}

double? dec(String value) {
  final p = value.replaceFirst(RegExp(r'^[+-]'), '').split(':');
  if (p.length != 3) return null;
  final d = double.tryParse(p[0]),
      m = double.tryParse(p[1]),
      s = double.tryParse(p[2]);
  return d == null || m == null || s == null
      ? null
      : (value.startsWith('-') ? -1 : 1) * (d + m / 60 + s / 3600);
}

AstroObjectType typeFor(String code) => switch (code) {
      'G' || 'GPair' || 'GTrpl' || 'GGroup' => AstroObjectType.galaxy,
      'PN' => AstroObjectType.planetaryNebula,
      'Dn' => AstroObjectType.darkNebula,
      'RfN' => AstroObjectType.reflectionNebula,
      'EmN' || 'Neb' || 'HII' || 'Cl+N' => AstroObjectType.emissionNebula,
      'OCl' => AstroObjectType.openCluster,
      'GCl' => AstroObjectType.globularCluster,
      'SNR' => AstroObjectType.supernovaRemnant,
      '*' => AstroObjectType.star,
      '**' => AstroObjectType.doubleStar,
      _ => AstroObjectType.other
    };

Future<void> main() async {
  sqfliteFfiInit();
  final source = File('assets/catalog/openngc.csv');
  if (!await source.exists()) throw StateError('Missing ${source.path}');
  final output = File('assets/catalog/astrofield.sqlite');
  if (await output.exists()) await output.delete();
  final db = await databaseFactoryFfi.openDatabase(output.absolute.path);
  try {
    await createCatalogSchema(db);
    final lines = source
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    final converter = const CsvToListConverter(
        fieldDelimiter: ';', shouldParseNumbers: false, eol: '\n');
    List<String>? header;
    var count = 0;
    await db.transaction((txn) async {
      await for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final cells = converter
            .convert(line)
            .single
            .map((e) => e.toString().trim())
            .toList();
        if (header == null) {
          header = cells;
          continue;
        }
        String get(String key) {
          final i = header!.indexOf(key);
          return i < 0 || i >= cells.length ? '' : cells[i];
        }

        final id = get('Name').replaceFirstMapped(
            RegExp(r'^([A-Z]+)0+(?=\d)'), (m) => m.group(1)!);
        final a = ra(get('RA')), d = dec(get('Dec'));
        if (a == null || d == null || a < 0 || a >= 360 || d.abs() > 90) {
          continue;
        }
        final messier = int.tryParse(get('M'));
        final display = messier == null ? id : 'M$messier';
        final common = get('Common names')
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .map((e) => e.trim())
            .toList();
        // Prefer names astronomers actually type when OpenNGC lists several.
        if (id == 'NGC1976') {
          common.remove('Orion Nebula');
          common.insert(0, 'Orion Nebula');
        }
        final aliases = <String>{
          id,
          display,
          if (messier != null) 'Messier $messier',
          ...common,
          ...get('Identifiers')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
        };
        final ngc = int.tryParse(get('NGC')), ic = int.tryParse(get('IC'));
        if (ngc != null) aliases.add('NGC $ngc');
        if (ic != null) aliases.add('IC $ic');
        if (RegExp(r'^NGC\d+$').hasMatch(id)) {
          aliases.add('NGC ${int.parse(id.substring(3))}');
        }
        if (RegExp(r'^IC\d+$').hasMatch(id)) {
          aliases.add('IC ${int.parse(id.substring(2))}');
        }
        final ids = <String>{
          id,
          if (messier != null) display,
          if (ngc != null) 'NGC$ngc',
          if (ic != null) 'IC$ic'
        };
        final v = number(get('V-Mag')), b = number(get('B-Mag'));
        final mag = v ?? b;
        await txn.insert('astro_objects', {
          'id': id,
          'primary_name': display,
          'common_name': common.isEmpty ? null : common.first,
          'object_type': typeFor(get('Type')).name,
          'constellation': constellations[get('Const')] ?? get('Const'),
          'ra_deg': a,
          'dec_deg': d,
          'magnitude': mag,
          'surface_brightness': number(get('SurfBr')),
          'major_axis_arcmin': number(get('MajAx')),
          'minor_axis_arcmin': number(get('MinAx')),
          'position_angle_deg': number(get('PosAng')),
          'redshift': number(get('Redshift')),
          'source_catalog': 'OpenNGC',
          'source_version': sourceVersion
        });
        await txn.insert('object_photometry', {
          'object_id': id,
          'magnitude_v': v,
          'magnitude_b': b,
          'surface_brightness': number(get('SurfBr'))
        });
        await txn.insert('object_metadata', {
          'object_id': id,
          'source_catalog': 'OpenNGC',
          'source_version': sourceVersion,
          'source_identifier': get('Name')
        });
        for (final alias in aliases) {
          final normalized = normalizeCatalogQuery(alias);
          if (normalized.isNotEmpty) {
            await txn.insert(
                'object_aliases',
                {
                  'object_id': id,
                  'alias': alias,
                  'normalized_alias': normalized
                },
                conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
        for (final identifier in ids) {
          final catalog = identifier.replaceAll(RegExp(r'\d'), '');
          await txn.insert(
              'catalog_identifiers',
              {
                'object_id': id,
                'catalog': catalog,
                'designation': identifier,
                'number': identifier.replaceAll(RegExp(r'\D'), ''),
                'normalized_designation': normalizeCatalogQuery(identifier)
              },
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await txn.insert('object_search', {
          'object_id': id,
          'search_text':
              '$display ${common.join(' ')} ${aliases.join(' ')} ${constellations[get('Const')] ?? get('Const')} ${typeFor(get('Type')).name}'
        });
        count++;
      }
      // Supplemental objects absent from OpenNGC; coordinates are source credited.
      for (final extra in [
        (
          id: 'B33',
          name: 'Horsehead Nebula',
          type: AstroObjectType.darkNebula,
          constellation: 'Orion',
          ra: 85.2458333333,
          dec: -2.4583333333,
          source: 'SIMBAD Barnard 33, J2000',
          aliases: ['Barnard 33', 'Horsehead', 'Horsehead Nebula']
        ),
        (
          id: 'Sh2-101',
          name: 'Tulip Nebula',
          type: AstroObjectType.emissionNebula,
          constellation: 'Cygnus',
          ra: 300.1208333333,
          dec: 35.3166666667,
          source:
              'Sharpless catalog / Northern Berkshire Astronomical Society J2000',
          aliases: ['Sh 2-101', 'Sharpless 101', 'Tulip Nebula']
        ),
      ]) {
        await txn.insert('astro_objects', {
          'id': extra.id,
          'primary_name': extra.id,
          'common_name': extra.name,
          'object_type': extra.type.name,
          'constellation': extra.constellation,
          'ra_deg': extra.ra,
          'dec_deg': extra.dec,
          'source_catalog': extra.source,
          'source_version': '2026-09-30 verified'
        });
        await txn.insert('object_metadata', {
          'object_id': extra.id,
          'source_catalog': extra.source,
          'source_version': '2026-09-30 verified',
          'source_identifier': extra.id
        });
        final aliases = <String>{extra.id, extra.name, ...extra.aliases};
        for (final alias in aliases) {
          await txn.insert(
              'object_aliases',
              {
                'object_id': extra.id,
                'alias': alias,
                'normalized_alias': normalizeCatalogQuery(alias)
              },
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await txn.insert('catalog_identifiers', {
          'object_id': extra.id,
          'catalog': extra.id == 'B33' ? 'Barnard' : 'Sharpless',
          'designation': extra.id,
          'number': extra.id.replaceAll(RegExp(r'\D'), ''),
          'normalized_designation': normalizeCatalogQuery(extra.id)
        });
        await txn.insert('object_search', {
          'object_id': extra.id,
          'search_text':
              '${aliases.join(' ')} ${extra.constellation} ${extra.type.name}'
        });
        count++;
      }
    });
    print('Imported $count unique OpenNGC rows to ${output.path}');
    await db.execute('VACUUM');
  } finally {
    await db.close();
  }
}
