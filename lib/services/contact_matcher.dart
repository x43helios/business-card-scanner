import '../models/business_card_fields.dart';
import '../models/contact.dart';

class MatchCandidate {
  final Contact contact;
  final double score;
  final List<String> reasons;

  const MatchCandidate({
    required this.contact,
    required this.score,
    required this.reasons,
  });
}

/// Heuristic matcher: name / company / phone / email.
class ContactMatcher {
  static List<MatchCandidate> findMatches(
    BusinessCardFields fields,
    List<Contact> contacts, {
    double minScore = 0.45,
  }) {
    final results = <MatchCandidate>[];
    for (final c in contacts) {
      final reasons = <String>[];
      var score = 0.0;

      if (_eq(fields.name, c.name)) {
        score += 0.45;
        reasons.add('name');
      } else if (_similar(fields.name, c.name)) {
        score += 0.25;
        reasons.add('name~');
      }

      if (_eq(fields.companyName, c.companyName)) {
        score += 0.25;
        reasons.add('company');
      }

      final phones = [
        fields.personalPhone,
        fields.whatsapp,
        fields.companyPhone,
        fields.directLine,
      ];
      final cPhones = [
        c.personalPhone,
        c.whatsapp,
        c.companyPhone,
        c.directLine,
      ];
      if (_anyPhoneMatch(phones, cPhones)) {
        score += 0.35;
        reasons.add('phone');
      }

      final emails = [fields.personalEmail, fields.companyEmail];
      final cEmails = [c.personalEmail, c.companyEmail];
      if (_anyEmailMatch(emails, cEmails)) {
        score += 0.4;
        reasons.add('email');
      }

      if (score >= minScore && reasons.isNotEmpty) {
        results.add(MatchCandidate(
          contact: c,
          score: score.clamp(0, 1),
          reasons: reasons,
        ));
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  static bool _eq(String? a, String? b) {
    if (a == null || b == null) return false;
    return _norm(a) == _norm(b) && _norm(a).isNotEmpty;
  }

  static bool _similar(String? a, String? b) {
    if (a == null || b == null) return false;
    final na = _norm(a);
    final nb = _norm(b);
    if (na.isEmpty || nb.isEmpty) return false;
    return na.contains(nb) || nb.contains(na);
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s\-_.]+'), '');

  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  static bool _anyPhoneMatch(List<String?> a, List<String?> b) {
    for (final x in a) {
      if (x == null || x.isEmpty) continue;
      final dx = _digits(x);
      if (dx.length < 7) continue;
      for (final y in b) {
        if (y == null || y.isEmpty) continue;
        final dy = _digits(y);
        if (dy.length < 7) continue;
        if (dx == dy || dx.endsWith(dy) || dy.endsWith(dx)) return true;
      }
    }
    return false;
  }

  static bool _anyEmailMatch(List<String?> a, List<String?> b) {
    for (final x in a) {
      if (x == null || x.isEmpty) continue;
      final nx = x.toLowerCase().trim();
      for (final y in b) {
        if (y == null || y.isEmpty) continue;
        if (nx == y.toLowerCase().trim()) return true;
      }
    }
    return false;
  }
}
