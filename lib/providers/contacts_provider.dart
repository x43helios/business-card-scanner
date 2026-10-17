import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import '../models/business_card_fields.dart';
import '../models/card_record.dart';
import '../models/contact.dart';

class ContactsProvider extends ChangeNotifier {
  ContactsProvider(this._db);

  final DatabaseHelper _db;
  final _uuid = const Uuid();

  List<Contact> _contacts = [];
  bool _loading = true;
  String _search = '';
  String? _tagFilter;
  final Set<String> _selectedIds = {};

  List<Contact> get contacts => _contacts;
  bool get loading => _loading;
  String get search => _search;
  String? get tagFilter => _tagFilter;
  Set<String> get selectedIds => _selectedIds;

  List<Contact> get filtered {
    var list = _contacts;
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        final hay = [
          c.name,
          c.title,
          c.companyName,
          c.companyAddress,
          c.personalPhone,
          c.personalEmail,
          c.companyPhone,
          c.companyEmail,
          c.fax,
          c.companyWebsite,
          ...c.tags,
        ].whereType<String>().join(' ').toLowerCase();
        return hay.contains(q);
      }).toList();
    }
    if (_tagFilter != null && _tagFilter!.isNotEmpty) {
      list = list.where((c) => c.tags.contains(_tagFilter)).toList();
    }
    return list;
  }

  Set<String> get allTags {
    final tags = <String>{};
    for (final c in _contacts) {
      tags.addAll(c.tags);
    }
    return tags;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _contacts = await _db.getAllContacts();
    _loading = false;
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  void setTagFilter(String? tag) {
    _tagFilter = tag;
    notifyListeners();
  }

  void toggleSelected(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  void selectAllFiltered() {
    for (final c in filtered) {
      _selectedIds.add(c.id);
    }
    notifyListeners();
  }

  List<Contact> get selectedContacts =>
      _contacts.where((c) => _selectedIds.contains(c.id)).toList();

  Future<Contact> createContactWithCard({
    required BusinessCardFields fields,
    String? imagePath,
    required String ocrSource,
    List<String> tags = const [],
    bool savePhoto = false,
  }) async {
    final now = DateTime.now();
    final contactId = _uuid.v4();
    final cardId = _uuid.v4();

    String? storedImage;
    if (savePhoto && imagePath != null) {
      storedImage = await _persistImage(imagePath, cardId);
    }

    var contact = Contact.fromFields(
      fields,
      id: contactId,
      tags: tags,
      now: now,
    );
    final card = CardRecord(
      id: cardId,
      contactId: contactId,
      fields: fields,
      imagePath: storedImage,
      ocrSource: ocrSource,
      createdAt: now,
    );
    contact = contact.copyWith(cards: [card]);

    await _db.upsertContact(contact);
    await _db.insertCard(card);
    await load();
    return (await _db.getContact(contactId))!;
  }

  Future<Contact> mergeCardOntoContact({
    required String contactId,
    required BusinessCardFields fields,
    String? imagePath,
    required String ocrSource,
    bool savePhoto = false,
  }) async {
    final existing = await _db.getContact(contactId);
    if (existing == null) {
      return createContactWithCard(
        fields: fields,
        imagePath: imagePath,
        ocrSource: ocrSource,
        savePhoto: savePhoto,
      );
    }

    final now = DateTime.now();
    final cardId = _uuid.v4();
    String? storedImage;
    if (savePhoto && imagePath != null) {
      storedImage = await _persistImage(imagePath, cardId);
    }

    final updated = existing.mergeFromCard(fields, now: now);
    final card = CardRecord(
      id: cardId,
      contactId: contactId,
      fields: fields,
      imagePath: storedImage,
      ocrSource: ocrSource,
      createdAt: now,
    );

    await _db.upsertContact(updated);
    await _db.insertCard(card);
    await load();
    return (await _db.getContact(contactId))!;
  }

  Future<void> updateContact(Contact contact) async {
    await _db.upsertContact(contact.copyWith(updatedAt: DateTime.now()));
    await load();
  }

  Future<void> setTags(String contactId, List<String> tags) async {
    await _db.updateContactTags(contactId, tags);
    await load();
  }

  Future<void> deleteContact(String id) async {
    final c = await _db.getContact(id);
    if (c != null) {
      for (final card in c.cards) {
        if (card.imagePath != null) {
          final f = File(card.imagePath!);
          if (await f.exists()) await f.delete();
        }
      }
    }
    await _db.deleteContact(id);
    _selectedIds.remove(id);
    await load();
  }

  Future<String> _persistImage(String sourcePath, String cardId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'card_images'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final ext = p.extension(sourcePath);
    final dest = p.join(dir.path, '$cardId$ext');
    await File(sourcePath).copy(dest);
    return dest;
  }
}
