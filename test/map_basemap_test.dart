import 'package:ability_link/models/map_basemap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes standard, satellite, and terrain basemaps', () {
    expect(MapBasemap.all.length, 3);
    expect(
      MapBasemap.all.map((b) => b.kind).toSet(),
      {
        MapBasemapKind.standard,
        MapBasemapKind.satellite,
        MapBasemapKind.terrain,
      },
    );
  });

  test('each basemap has a distinct tile URL', () {
    final urls = MapBasemap.all.map((b) => b.urlTemplate).toSet();
    expect(urls.length, MapBasemap.all.length);
    expect(
      MapBasemap.byKind(MapBasemapKind.standard).urlTemplate,
      contains('cartocdn'),
    );
    expect(
      MapBasemap.byKind(MapBasemapKind.satellite).urlTemplate,
      contains('World_Imagery'),
    );
    expect(
      MapBasemap.byKind(MapBasemapKind.terrain).urlTemplate,
      contains('opentopomap'),
    );
  });

  test('tryParse and indexOf round-trip', () {
    for (final kind in MapBasemapKind.values) {
      expect(MapBasemap.tryParse(kind.name), kind);
      expect(MapBasemap.byIndex(MapBasemap.indexOf(kind)).kind, kind);
    }
    expect(MapBasemap.tryParse('nope'), isNull);
    expect(MapBasemap.byIndex(99).kind, MapBasemapKind.standard);
  });
}
