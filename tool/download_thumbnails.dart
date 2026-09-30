// Fetches actual DSS2 color survey cutouts for Messier objects.
// Run from project root: dart run tool/download_thumbnails.dart
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

double? coord(String value, bool rightAscension) {
  final p = value.replaceFirst(RegExp(r'^[+-]'), '').split(':');
  if (p.length != 3) return null;
  final a = double.tryParse(p[0]),
      b = double.tryParse(p[1]),
      c = double.tryParse(p[2]);
  if (a == null || b == null || c == null) return null;
  final result = a + b / 60 + c / 3600;
  return rightAscension
      ? result * 15
      : (value.startsWith('-') ? -result : result);
}

Future<void> main() async {
  final directory = Directory('assets/catalog/thumbnails');
  await directory.create(recursive: true);
  final lines = File('assets/catalog/openngc.csv')
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  final converter = const CsvToListConverter(
      fieldDelimiter: ';', shouldParseNumbers: false, eol: '\n');
  List<String>? header;
  final entries = <({String id, double ra, double dec, double fov})>[];
  await for (final line in lines) {
    final cells =
        converter.convert(line).single.map((e) => e.toString().trim()).toList();
    if (header == null) {
      header = cells;
      continue;
    }
    String get(String key) {
      final i = header!.indexOf(key);
      return i < 0 || i >= cells.length ? '' : cells[i];
    }

    final m = int.tryParse(get('M')),
        a = coord(get('RA'), true),
        d = coord(get('Dec'), false);
    if (m == null || a == null || d == null) continue;
    final size = double.tryParse(get('MajAx')) ?? 10;
    entries
        .add((id: 'M$m', ra: a, dec: d, fov: (size / 60 * 1.45).clamp(.25, 5)));
  }
  final client = http.Client();
  var successes = 0;
  try {
    for (var start = 0; start < entries.length; start += 6) {
      final batch = entries.skip(start).take(6);
      await Future.wait(batch.map((e) async {
        final file = File('${directory.path}/${e.id}.jpg');
        if (await file.exists()) {
          successes++;
          return;
        }
        final uri = Uri.https(
            'alasky.cds.unistra.fr', '/hips-image-services/hips2fits', {
          'hips': 'CDS/P/DSS2/color',
          'width': '160',
          'height': '160',
          'fov': '${e.fov}',
          'projection': 'TAN',
          'ra': '${e.ra}',
          'dec': '${e.dec}',
          'format': 'jpg'
        });
        try {
          final response =
              await client.get(uri).timeout(const Duration(seconds: 40));
          if (response.statusCode == 200 &&
              response.headers['content-type']?.contains('image/jpeg') ==
                  true &&
              response.bodyBytes.length > 1000) {
            await file.writeAsBytes(response.bodyBytes);
            successes++;
          }
        } catch (_) {/* Leave optional thumbnail absent. */}
      }));
    }
  } finally {
    client.close();
  }
  stdout
      .writeln('Downloaded $successes of ${entries.length} real DSS2 cutouts.');
}
