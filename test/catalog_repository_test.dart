import 'dart:io';
import 'package:astrofield_ui/data/astro_object_repository.dart';
import 'package:astrofield_ui/models/astro_object.dart';
import 'package:astrofield_ui/domain/field_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late AstroObjectRepository repo;
  setUpAll(() async {
    directory=await Directory.systemTemp.createTemp('astrofield_catalog_test_');
    final data=await rootBundle.load('assets/catalog/astrofield.sqlite');
    final file=File('${directory.path}/catalog.sqlite');
    await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes,data.lengthInBytes));
    repo=await AstroObjectRepository.open(testPath:file.path);
  });
  tearDownAll(() async {await repo.close();await directory.delete(recursive:true);});

  test('M42, NGC 1976 and Orion Nebula resolve to one object',() async {
    for(final query in ['M42','M 42','Messier 42','NGC 1976','NGC1976','ngc-1976','Orion Nebula','great orion nebula']) {
      final results=await repo.searchObjects(CatalogFilter(query:query));
      expect(results,contains(predicate<AstroObject>((o)=>o.id=='NGC1976')),reason:query);
    }
    final m42=await repo.getById('M42');
    expect(m42?.id,'NGC1976');
    expect(m42?.raDeg,closeTo(83.8187,.01));
    expect(m42?.decDeg,closeTo(-5.3897,.01));
    expect(m42?.aliases,contains('Orion Nebula'));
  });
  test('Barnard and Sharpless forms resolve canonical supplemental objects',() async {
    for(final query in ['B33','Barnard 33','Horsehead Nebula']) {
      expect((await repo.searchObjects(CatalogFilter(query:query))).first.id,'B33',reason:query);
    }
    for(final query in ['Sh2-101','Sh 2 101','Sharpless 101','Tulip Nebula']) {
      expect((await repo.searchObjects(CatalogFilter(query:query))).first.id,'Sh2-101',reason:query);
    }
  });
  test('pagination does not repeat records',() async {
    final first=await repo.searchObjects(const CatalogFilter(),limit:50);
    final second=await repo.searchObjects(const CatalogFilter(),limit:50,offset:50);
    expect(first.length,50);expect(second.length,50);
    expect(first.map((o)=>o.id).toSet().intersection(second.map((o)=>o.id).toSet()),isEmpty);
    expect(await repo.countObjects(const CatalogFilter()),greaterThan(13000));
  });
  test('favorites store references without duplicating objects',() async {
    final object=(await repo.getById('M42'))!;
    await repo.setFavorite(object.id,true);
    expect(await repo.countObjects(const CatalogFilter(savedOnly:true)),1);
    await repo.setFavorite(object.id,false);
    expect(await repo.countObjects(const CatalogFilter(savedOnly:true)),0);
  });
  test('SQL altitude filter and sort use a full-catalog observation cache',() async {
    const site=Site(24.8607,67.0011);
    final time=DateTime.utc(2026,9,30,19);
    await repo.ensureObservationCache(site,time);
    final key=AstroObjectRepository.cacheKey(site,time);
    final filter=CatalogFilter(visibleNow:true,cacheKey:key,sort:CatalogSort.altitude);
    final count=await repo.countObjects(filter);
    final page=await repo.searchObjects(filter,limit:50);
    expect(count,greaterThan(1000));
    expect(page.length,50);
    expect((await repo.searchObjects(filter,limit:50,offset:50)).map((o)=>o.id).toSet().intersection(page.map((o)=>o.id).toSet()),isEmpty);
  });
}
