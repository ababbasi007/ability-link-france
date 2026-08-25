import 'package:ability_link/models/place_barrier_report.dart';
import 'package:ability_link/models/place_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PlaceReport.fromMap parses fields and status', () {
    final report = PlaceReport.fromMap('r1', {
      'placeId': 'city-hospital',
      'placeName': 'City Hospital',
      'category': PlaceBarrierCategory.elevator.id,
      'type': 'barrier',
      'details': 'Lift stuck on floor 3',
      'status': 'in_review',
      'photoUrls': ['https://example.com/a.jpg'],
    });
    expect(report.id, 'r1');
    expect(report.placeName, 'City Hospital');
    expect(report.categoryLabel, contains('elevator'));
    expect(report.status, PlaceReportStatus.inReview);
    expect(report.isOpen, isFalse);
    expect(report.photoUrls, hasLength(1));
  });

  test('PlaceReportStatus labels and messages cover known states', () {
    expect(PlaceReportStatus.label('open'), 'Open');
    expect(PlaceReportStatus.label('in_review'), 'In review');
    expect(PlaceReportStatus.label('resolved'), 'Resolved');
    expect(PlaceReportStatus.label('dismissed'), 'Dismissed');
    expect(PlaceReportStatus.normalize(null), PlaceReportStatus.open);
    expect(
      PlaceReportStatus.message('resolved'),
      contains('reviewed'),
    );
  });

  test('PlaceReportStatus colors are distinct', () {
    final open = PlaceReportStatus.color('open');
    final resolved = PlaceReportStatus.color('resolved');
    expect(open, isA<Color>());
    expect(resolved, isNot(equals(open)));
  });
}
