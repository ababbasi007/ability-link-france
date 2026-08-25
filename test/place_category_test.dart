import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ability_link/models/place_category.dart';

void main() {
  test('native categories resolve to distinct icons', () {
    expect(PlaceCategory.resolve('hospital').icon, Icons.local_hospital_rounded);
    expect(PlaceCategory.resolve('cafe').icon, Icons.local_cafe_rounded);
    expect(PlaceCategory.resolve('restaurant').icon, Icons.restaurant_rounded);
    expect(PlaceCategory.resolve('grocery').icon, Icons.local_grocery_store_rounded);
    expect(PlaceCategory.resolve('beach').icon, Icons.beach_access_rounded);
    expect(PlaceCategory.resolve('public_toilet').icon, Icons.wc_rounded);
  });

  test('aliases map to canonical categories', () {
    expect(PlaceCategory.resolve('mosque').id, 'worship');
    expect(PlaceCategory.resolve('university').id, 'school');
    expect(PlaceCategory.resolve('train').id, 'railway');
    expect(PlaceCategory.resolve('medical').id, 'hospital');
  });

  test('module-linked categories expose healthcare/benefits/education', () {
    expect(
      PlaceCategory.resolve('clinic').module,
      PlaceCategoryModule.healthcare,
    );
    expect(
      PlaceCategory.resolve('government').module,
      PlaceCategoryModule.benefits,
    );
    expect(
      PlaceCategory.resolve('school').module,
      PlaceCategoryModule.education,
    );
  });

  test('smart filters include 16 place types', () {
    expect(PlaceCategory.smartFilters.length, 16);
  });

  test('matchesType filters by canonical id', () {
    expect(PlaceCategory.matchesType('mosque', 'worship'), isTrue);
    expect(PlaceCategory.matchesType('cafe', 'restaurant'), isFalse);
    expect(PlaceCategory.matchesType('cafe', null), isTrue);
  });
}
