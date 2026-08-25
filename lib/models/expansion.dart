import 'package:cloud_firestore/cloud_firestore.dart';

class Market {
  const Market({
    required this.code,
    required this.name,
    required this.currency,
    required this.currencySymbol,
    required this.emergencyNumber,
    required this.relayNumber,
    required this.standard,
    required this.standardSummary,
    required this.placeTaxonomy,
    required this.providerTaxonomy,
    required this.languages,
    required this.samplePrice,
  });

  final String code;
  final String name;
  final String currency;
  final String currencySymbol;
  final String emergencyNumber;
  final String relayNumber;
  final String standard;
  final String standardSummary;
  final List<String> placeTaxonomy;
  final List<String> providerTaxonomy;
  final List<String> languages;
  final int samplePrice;

  String formatMoney(int amount) => '$currencySymbol$amount $currency';

  factory Market.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Market(
      code: doc.id,
      name: (d['name'] as String?) ?? doc.id,
      currency: (d['currency'] as String?) ?? 'USD',
      currencySymbol: (d['currencySymbol'] as String?) ?? '\$',
      emergencyNumber: (d['emergencyNumber'] as String?) ?? '112',
      relayNumber: (d['relayNumber'] as String?) ?? '',
      standard: (d['standard'] as String?) ?? 'WCAG 2.2',
      standardSummary: (d['standardSummary'] as String?) ?? '',
      placeTaxonomy: List<String>.from(d['placeTaxonomy'] as List? ?? const []),
      providerTaxonomy: List<String>.from(
        d['providerTaxonomy'] as List? ?? const [],
      ),
      languages: List<String>.from(d['languages'] as List? ?? const []),
      samplePrice: (d['samplePrice'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'currency': currency,
    'currencySymbol': currencySymbol,
    'emergencyNumber': emergencyNumber,
    'relayNumber': relayNumber,
    'standard': standard,
    'standardSummary': standardSummary,
    'placeTaxonomy': placeTaxonomy,
    'providerTaxonomy': providerTaxonomy,
    'languages': languages,
    'samplePrice': samplePrice,
  };

  static String inferCode(String countryName) {
    final x = countryName.toLowerCase();
    if (x.contains('france')) return 'FR';
    if (x.contains('spain') || x.contains('espa')) return 'ES';
    if (x.contains('emirate') || x.contains('dubai') || x.contains('uae')) {
      return 'AE';
    }
    if (x.contains('pakistan')) return 'PK';
    if (x.contains('kingdom') || x.contains('britain') || x.contains('uk')) {
      return 'GB';
    }
    if (x.contains('united states') || x.contains('usa') || x == 'us') {
      return 'US';
    }
    return 'US';
  }
}

class ExpansionPartner {
  const ExpansionPartner({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.marketCode,
    required this.kind,
    required this.summary,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String ownerUid;
  final String name;
  final String marketCode;
  final String kind;
  final String summary;
  final String status;
  final DateTime createdAt;

  factory ExpansionPartner.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return ExpansionPartner(
      id: doc.id,
      ownerUid: (d['ownerUid'] as String?) ?? '',
      name: (d['name'] as String?) ?? 'Partner',
      marketCode: (d['marketCode'] as String?) ?? 'US',
      kind: (d['kind'] as String?) ?? 'ngo',
      summary: (d['summary'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'pending',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
