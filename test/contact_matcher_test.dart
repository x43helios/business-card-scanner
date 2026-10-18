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
    final hasCjk = name != null && RegExp(r'[\u4e00-\u9fff]').hasMatch(name);
    final coCjk =
        company != null && RegExp(r'[\u4e00-\u9fff]').hasMatch(company);
    return Contact(
      id: id,
      chineseName: hasCjk ? name : null,
      englishName: hasCjk ? null : name,
      companyNameChinese: coCjk ? company : null,
      companyNameEnglish: coCjk ? null : company,
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
      englishName: 'Ada Lovelace',
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
    final fields = const BusinessCardFields(
      englishName: 'Bob Chan',
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
      englishName: 'Alex',
      companyNameEnglish: 'Helios',
      personalEmail: 'a@helios.example',
    );
    final matches = ContactMatcher.findMatches(fields, existing);
    expect(matches, isEmpty);
  });
}
