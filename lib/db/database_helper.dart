import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/card_record.dart';
import '../models/contact.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'business_card_scanner.db';
  static const _dbVersion = 2;

  /// Columns added in v2 (ALTER TABLE ADD COLUMN).
  static const List<String> v2Columns = [
    'chinese_name',
    'english_name',
    'title_chinese',
    'title_english',
    'qualifications',
    'education',
    'company_name_chinese',
    'company_name_english',
    'department',
    'whatsapp',
    'wechat',
    'line_id',
    'direct_line',
    'extension',
    'linkedin',
    'social_media',
    'company_address_chinese',
    'company_address_english',
    'room_floor',
    'district',
    'postal_code',
    'slogan',
    'services',
    'business_hours',
    'qr_info',
    'notes',
  ];

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  String get _contactsCreateSql => '''
CREATE TABLE contacts (
  id TEXT PRIMARY KEY,
  name TEXT,
  title TEXT,
  company_name TEXT,
  company_address TEXT,
  personal_phone TEXT,
  personal_email TEXT,
  company_phone TEXT,
  company_email TEXT,
  fax TEXT,
  company_website TEXT,
  chinese_name TEXT,
  english_name TEXT,
  title_chinese TEXT,
  title_english TEXT,
  qualifications TEXT,
  education TEXT,
  company_name_chinese TEXT,
  company_name_english TEXT,
  department TEXT,
  whatsapp TEXT,
  wechat TEXT,
  line_id TEXT,
  direct_line TEXT,
  extension TEXT,
  linkedin TEXT,
  social_media TEXT,
  company_address_chinese TEXT,
  company_address_english TEXT,
  room_floor TEXT,
  district TEXT,
  postal_code TEXT,
  slogan TEXT,
  services TEXT,
  business_hours TEXT,
  qr_info TEXT,
  notes TEXT,
  tags TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''';

  String get _cardsCreateSql => '''
CREATE TABLE cards (
  id TEXT PRIMARY KEY,
  contact_id TEXT NOT NULL,
  name TEXT,
  title TEXT,
  company_name TEXT,
  company_address TEXT,
  personal_phone TEXT,
  personal_email TEXT,
  company_phone TEXT,
  company_email TEXT,
  fax TEXT,
  company_website TEXT,
  chinese_name TEXT,
  english_name TEXT,
  title_chinese TEXT,
  title_english TEXT,
  qualifications TEXT,
  education TEXT,
  company_name_chinese TEXT,
  company_name_english TEXT,
  department TEXT,
  whatsapp TEXT,
  wechat TEXT,
  line_id TEXT,
  direct_line TEXT,
  extension TEXT,
  linkedin TEXT,
  social_media TEXT,
  company_address_chinese TEXT,
  company_address_english TEXT,
  room_floor TEXT,
  district TEXT,
  postal_code TEXT,
  slogan TEXT,
  services TEXT,
  business_hours TEXT,
  qr_info TEXT,
  notes TEXT,
  image_path TEXT,
  ocr_source TEXT NOT NULL DEFAULT 'on_device',
  created_at TEXT NOT NULL,
  FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
)
''';

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute(_contactsCreateSql);
        await db.execute(_cardsCreateSql);
        await db.execute(
          'CREATE INDEX idx_cards_contact ON cards(contact_id)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          for (final col in v2Columns) {
            try {
              await db.execute('ALTER TABLE contacts ADD COLUMN $col TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE cards ADD COLUMN $col TEXT');
            } catch (_) {}
          }
        }
      },
    );
  }

  Future<List<Contact>> getAllContacts() async {
    final db = await database;
    final rows = await db.query('contacts', orderBy: 'updated_at DESC');
    final contacts = <Contact>[];
    for (final row in rows) {
      final cards = await getCardsForContact(row['id'] as String);
      contacts.add(Contact.fromDbMap(row, cards: cards));
    }
    return contacts;
  }

  Future<Contact?> getContact(String id) async {
    final db = await database;
    final rows = await db.query('contacts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final cards = await getCardsForContact(id);
    return Contact.fromDbMap(rows.first, cards: cards);
  }

  Future<List<CardRecord>> getCardsForContact(String contactId) async {
    final db = await database;
    final rows = await db.query(
      'cards',
      where: 'contact_id = ?',
      whereArgs: [contactId],
      orderBy: 'created_at DESC',
    );
    return rows.map(CardRecord.fromDbMap).toList();
  }

  Future<void> upsertContact(Contact contact) async {
    final db = await database;
    await db.insert(
      'contacts',
      contact.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertCard(CardRecord card) async {
    final db = await database;
    await db.insert(
      'cards',
      card.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteContact(String id) async {
    final db = await database;
    await db.delete('cards', where: 'contact_id = ?', whereArgs: [id]);
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateContactTags(String id, List<String> tags) async {
    final db = await database;
    await db.update(
      'contacts',
      {
        'tags': tags.join('|'),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Set<String>> getAllTags() async {
    final contacts = await getAllContacts();
    final tags = <String>{};
    for (final c in contacts) {
      tags.addAll(c.tags);
    }
    return tags;
  }
}
