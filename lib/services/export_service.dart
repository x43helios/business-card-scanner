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

  void _noteLine(StringBuffer buf, String label, String? value) {
    if (value == null || value.trim().isEmpty) return;
    buf.writeln('NOTE:${_escV('$label: ${value.trim()}')}');
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
      if (c.department != null) {
        buf.writeln('ORG:${_escV(c.companyName)};${_escV(c.department)}');
      }
      if (c.personalPhone != null) {
        buf.writeln('TEL;TYPE=CELL:${_escV(c.personalPhone)}');
      }
      if (c.whatsapp != null && c.whatsapp != c.personalPhone) {
        buf.writeln('TEL;TYPE=CELL:${_escV(c.whatsapp)}');
      }
      if (c.companyPhone != null) {
        buf.writeln('TEL;TYPE=WORK:${_escV(c.companyPhone)}');
      }
      if (c.directLine != null) {
        buf.writeln('TEL;TYPE=WORK:${_escV(c.directLine)}');
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
      if (c.linkedIn != null) {
        buf.writeln('URL:${_escV(c.linkedIn)}');
      }
      if (c.qrInfo != null) {
        buf.writeln('URL:${_escV(c.qrInfo)}');
      }
      if (c.wechat != null) {
        buf.writeln('IMPP:weixin:${_escV(c.wechat)}');
      }
      if (c.lineId != null) {
        buf.writeln('IMPP:line:${_escV(c.lineId)}');
      }
      _noteLine(buf, 'Qualifications', c.qualifications);
      _noteLine(buf, 'Education', c.education);
      _noteLine(buf, 'Services', c.services);
      _noteLine(buf, 'Hours', c.businessHours);
      _noteLine(buf, 'Slogan', c.slogan);
      _noteLine(buf, 'Notes', c.notes);
      if (c.extension != null) {
        _noteLine(buf, 'Ext', c.extension);
      }
      if (c.socialMedia != null) {
        _noteLine(buf, 'Social', c.socialMedia);
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

  static const csvHeaders = [
    'chinese_name',
    'english_name',
    'title_chinese',
    'title_english',
    'qualifications',
    'education',
    'company_name_chinese',
    'company_name_english',
    'department',
    'personal_phone',
    'whatsapp',
    'wechat',
    'line_id',
    'company_phone',
    'direct_line',
    'extension',
    'fax',
    'personal_email',
    'company_email',
    'company_website',
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
    // Legacy bridge columns
    'name',
    'title',
    'company_name',
    'company_address',
    'tags',
    'card_count',
  ];

  String _toCsv(List<Contact> contacts) {
    final buf = StringBuffer();
    buf.writeln(csvHeaders.join(','));
    for (final c in contacts) {
      buf.writeln([
        _csvCell(c.chineseName),
        _csvCell(c.englishName),
        _csvCell(c.titleChinese),
        _csvCell(c.titleEnglish),
        _csvCell(c.qualifications),
        _csvCell(c.education),
        _csvCell(c.companyNameChinese),
        _csvCell(c.companyNameEnglish),
        _csvCell(c.department),
        _csvCell(c.personalPhone),
        _csvCell(c.whatsapp),
        _csvCell(c.wechat),
        _csvCell(c.lineId),
        _csvCell(c.companyPhone),
        _csvCell(c.directLine),
        _csvCell(c.extension),
        _csvCell(c.fax),
        _csvCell(c.personalEmail),
        _csvCell(c.companyEmail),
        _csvCell(c.companyWebsite),
        _csvCell(c.linkedIn),
        _csvCell(c.socialMedia),
        _csvCell(c.companyAddressChinese),
        _csvCell(c.companyAddressEnglish),
        _csvCell(c.roomFloor),
        _csvCell(c.district),
        _csvCell(c.postalCode),
        _csvCell(c.slogan),
        _csvCell(c.services),
        _csvCell(c.businessHours),
        _csvCell(c.qrInfo),
        _csvCell(c.notes),
        _csvCell(c.name),
        _csvCell(c.title),
        _csvCell(c.companyName),
        _csvCell(c.companyAddress),
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

    pw.Widget? line(String label, String? value) {
      if (value == null || value.trim().isEmpty) return null;
      return pw.Text('$label: $value', style: bodyStyle);
    }

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
            final lines = <pw.Widget>[
              pw.Text(c.displayName, style: headingStyle),
              ...[
                line('中文姓名', c.chineseName),
                line('English name', c.englishName),
                line('職銜', c.title),
                line('資格', c.qualifications),
                line('學歷', c.education),
                line('公司', c.companyName),
                line('部門', c.department),
                line('地址', c.companyAddress),
                line('Mobile', c.personalPhone),
                line('WhatsApp', c.whatsapp),
                line('WeChat', c.wechat),
                line('LINE', c.lineId),
                line('Tel', c.companyPhone),
                line('Direct', c.directLine),
                line('Ext', c.extension),
                line('Email', c.personalEmail),
                line('Work Email', c.companyEmail),
                line('Fax', c.fax),
                line('Web', c.companyWebsite),
                line('LinkedIn', c.linkedIn),
                line('Social', c.socialMedia),
                line('Services', c.services),
                line('Hours', c.businessHours),
                line('Slogan', c.slogan),
                line('QR', c.qrInfo),
                line('Notes', c.notes),
              ].whereType<pw.Widget>(),
              if (c.tags.isNotEmpty)
                pw.Text('Tags: ${c.tags.join(', ')}', style: bodyStyle),
              pw.Text('Cards: ${c.cards.length}', style: bodyStyle),
            ];
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: lines,
              ),
            );
          }),
        ],
      ),
    );
    return doc.save();
  }
}
