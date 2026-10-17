import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/contact.dart';

enum ExportFormat { vcard, csv, pdf }

class ExportService {
  Future<File> exportContacts(
    List<Contact> contacts,
    ExportFormat format, {
    Directory? outputDir,
  }) async {
    final dir = outputDir ?? await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    switch (format) {
      case ExportFormat.vcard:
        final file = File(p.join(dir.path, 'contacts_$stamp.vcf'));
        await file.writeAsString(_toVCard(contacts));
        return file;
      case ExportFormat.csv:
        final file = File(p.join(dir.path, 'contacts_$stamp.csv'));
        await file.writeAsString(_toCsv(contacts), encoding: utf8);
        return file;
      case ExportFormat.pdf:
        final file = File(p.join(dir.path, 'contacts_$stamp.pdf'));
        final bytes = await _toPdf(contacts);
        await file.writeAsBytes(bytes);
        return file;
    }
  }

  Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }

  String _escV(String? v) {
    if (v == null) return '';
    return v
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\n', '\\n');
  }

  String _toVCard(List<Contact> contacts) {
    final buf = StringBuffer();
    for (final c in contacts) {
      buf.writeln('BEGIN:VCARD');
      buf.writeln('VERSION:3.0');
      buf.writeln('FN:${_escV(c.displayName)}');
      if (c.name != null) {
        buf.writeln('N:${_escV(c.name)};;;;');
      }
      if (c.title != null) buf.writeln('TITLE:${_escV(c.title)}');
      if (c.companyName != null) buf.writeln('ORG:${_escV(c.companyName)}');
      if (c.personalPhone != null) {
        buf.writeln('TEL;TYPE=CELL:${_escV(c.personalPhone)}');
      }
      if (c.companyPhone != null) {
        buf.writeln('TEL;TYPE=WORK:${_escV(c.companyPhone)}');
      }
      if (c.fax != null) buf.writeln('TEL;TYPE=FAX:${_escV(c.fax)}');
      if (c.personalEmail != null) {
        buf.writeln('EMAIL;TYPE=HOME:${_escV(c.personalEmail)}');
      }
      if (c.companyEmail != null) {
        buf.writeln('EMAIL;TYPE=WORK:${_escV(c.companyEmail)}');
      }
      if (c.companyAddress != null) {
        buf.writeln('ADR;TYPE=WORK:;;${_escV(c.companyAddress)};;;;');
      }
      if (c.companyWebsite != null) {
        buf.writeln('URL:${_escV(c.companyWebsite)}');
      }
      if (c.tags.isNotEmpty) {
        buf.writeln('CATEGORIES:${c.tags.map(_escV).join(',')}');
      }
      buf.writeln('END:VCARD');
    }
    return buf.toString();
  }

  String _csvCell(String? v) {
    final s = v ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  String _toCsv(List<Contact> contacts) {
    final headers = [
      'name',
      'title',
      'company_name',
      'company_address',
      'personal_phone',
      'personal_email',
      'company_phone',
      'company_email',
      'fax',
      'company_website',
      'tags',
      'card_count',
    ];
    final buf = StringBuffer();
    buf.writeln(headers.join(','));
    for (final c in contacts) {
      buf.writeln([
        _csvCell(c.name),
        _csvCell(c.title),
        _csvCell(c.companyName),
        _csvCell(c.companyAddress),
        _csvCell(c.personalPhone),
        _csvCell(c.personalEmail),
        _csvCell(c.companyPhone),
        _csvCell(c.companyEmail),
        _csvCell(c.fax),
        _csvCell(c.companyWebsite),
        _csvCell(c.tags.join('|')),
        c.cards.length.toString(),
      ].join(','));
    }
    return buf.toString();
  }

  Future<pw.Font?> _loadCjkFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/NotoSansTC-Regular.ttf');
      return pw.Font.ttf(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<int>> _toPdf(List<Contact> contacts) async {
    final cjk = await _loadCjkFont();
    final theme = cjk != null
        ? pw.ThemeData.withFont(base: cjk, bold: cjk)
        : null;

    final doc = pw.Document(theme: theme);
    final titleStyle = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
      font: cjk,
    );
    final headingStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      font: cjk,
    );
    final bodyStyle = pw.TextStyle(fontSize: 11, font: cjk);
    final smallStyle = pw.TextStyle(fontSize: 10, font: cjk);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Business Card Scanner / 名片掃描',
              style: titleStyle,
            ),
          ),
          pw.Text(
            'Exported: ${DateTime.now().toIso8601String()}',
            style: smallStyle,
          ),
          pw.SizedBox(height: 16),
          ...contacts.map((c) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(c.displayName, style: headingStyle),
                  if (c.title != null) pw.Text(c.title!, style: bodyStyle),
                  if (c.companyName != null)
                    pw.Text(c.companyName!, style: bodyStyle),
                  if (c.companyAddress != null)
                    pw.Text(c.companyAddress!, style: bodyStyle),
                  if (c.personalPhone != null)
                    pw.Text('Mobile: ${c.personalPhone}', style: bodyStyle),
                  if (c.companyPhone != null)
                    pw.Text('Tel: ${c.companyPhone}', style: bodyStyle),
                  if (c.personalEmail != null)
                    pw.Text('Email: ${c.personalEmail}', style: bodyStyle),
                  if (c.companyEmail != null)
                    pw.Text('Work Email: ${c.companyEmail}', style: bodyStyle),
                  if (c.fax != null) pw.Text('Fax: ${c.fax}', style: bodyStyle),
                  if (c.companyWebsite != null)
                    pw.Text('Web: ${c.companyWebsite}', style: bodyStyle),
                  if (c.tags.isNotEmpty)
                    pw.Text('Tags: ${c.tags.join(', ')}', style: bodyStyle),
                  pw.Text('Cards: ${c.cards.length}', style: bodyStyle),
                ],
              ),
            );
          }),
        ],
      ),
    );
    return doc.save();
  }
}
