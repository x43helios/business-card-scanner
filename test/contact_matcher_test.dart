import 'package:business_card_scanner/models/business_card_fields.dart';
import 'package:business_card_scanner/models/contact.dart';
import 'package:business_card_scanner/services/contact_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  Contact contact({
    String id = '1',
    String? name,
    String? company,
    String? phone,
    String? email,
  }) {
    return Contact(
      id: id,
      name: name,
      companyName: company,
      personalPhone: phone,
      personalEmail: email,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('matches by email', () {
    final existing = [
      contact(name: 'Ada', email: 'ada@example.com'),
    ];
    final fields = const BusinessCardFields(
      name: 'Ada Lovelace',
      personalEmail: 'ada@example.com',
    );
    final matches = ContactMatcher.findMatches(fields, existing);
    expect(matches, isNotEmpty);
    expect(matches.first.reasons, contains('email'));
  });

  test('matches by phone digits', () {
    final existing = [
      contact(name: 'Bob Chan', phone: '+852 9123-4567'),
    ];
    // Same name + overlapping phone digits → score above threshold
    final fields = const BusinessCardFields(
      name: 'Bob Chan',
      personalPhone: '91234567',
    );
    final matches = ContactMatcher.findMatches(fields, existing);
    expect(matches, isNotEmpty);
    expect(matches.first.reasons, contains('phone'));
    expect(matches.first.reasons, contains('name'));
  });

  test('no match for unrelated contact', () {
    final existing = [
      contact(name: 'Zoe', company: 'Other Co', email: 'z@other.example'),
    ];
    final fields = const BusinessCardFields(
      name: 'Alex',
      companyName: 'Helios',
      personalEmail: 'a@helios.example',
    );
    final matches = ContactMatcher.findMatches(fields, existing);
    expect(matches, isEmpty);
  });
}
