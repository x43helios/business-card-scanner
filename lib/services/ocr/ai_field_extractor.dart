import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/business_card_fields.dart';
import '../crash_log.dart';
import 'ai_flags.dart';

/// Extracts structured [BusinessCardFields] from OCR raw text via an LLM.
///
/// Soft-fails: returns null on any error (caller keeps regex fields).
abstract class AiFieldExtractor {
  /// Returns structured fields, or null if skipped / failed.
  Future<BusinessCardFields?> extract(String rawText, {AiExtractConfig? config});
}

class AiExtractConfig {
  final String apiKey;
  final String baseUrl;
  final String model;
  final String provider; // openai | gemini
  final bool enabled;

  const AiExtractConfig({
    required this.apiKey,
    this.baseUrl = kCardAiBaseUrl,
    this.model = kCardAiModel,
    this.provider = kCardAiProvider,
    this.enabled = true,
  });

  bool get canRun => enabled && apiKey.trim().isNotEmpty && rawReady;

  /// Placeholder so const analysis is happy; real check is apiKey.
  bool get rawReady => true;

  /// Effective config: runtime key overrides dart-define.
  factory AiExtractConfig.resolve({
    required bool enabled,
    String? runtimeApiKey,
    String? runtimeBaseUrl,
    String? runtimeModel,
    String? runtimeProvider,
  }) {
    final key = (runtimeApiKey != null && runtimeApiKey.trim().isNotEmpty)
        ? runtimeApiKey.trim()
        : kCardAiApiKey;
    return AiExtractConfig(
      apiKey: key,
      baseUrl: (runtimeBaseUrl != null && runtimeBaseUrl.trim().isNotEmpty)
          ? runtimeBaseUrl.trim()
          : kCardAiBaseUrl,
      model: (runtimeModel != null && runtimeModel.trim().isNotEmpty)
          ? runtimeModel.trim()
          : kCardAiModel,
      provider: (runtimeProvider != null && runtimeProvider.trim().isNotEmpty)
          ? runtimeProvider.trim()
          : kCardAiProvider,
      enabled: enabled && key.isNotEmpty,
    );
  }
}

const _jsonKeys = '''
chineseName, englishName, titleChinese, titleEnglish, qualifications, education,
companyNameChinese, companyNameEnglish, department,
personalPhone, whatsapp, wechat, lineId, companyPhone, directLine, extension, fax,
personalEmail, companyEmail, companyWebsite, linkedIn, socialMedia,
companyAddressChinese, companyAddressEnglish, roomFloor, district, postalCode,
slogan, services, businessHours, qrInfo, notes
''';

String buildAiExtractionPrompt(String rawText) => '''
You are a Hong Kong bilingual (Traditional Chinese + English) business-card parser.
Given OCR raw text from a business card, extract fields into a single JSON object.

Rules:
- Return ONLY valid JSON (no markdown fences, no commentary).
- Use exactly these keys (null for unknown): $_jsonKeys
- Prefer Chinese company/person names in chinese* fields and English in english* fields.
- qualifications = professional registration (e.g. 註冊中醫師, R.C.M.P., 註冊編號).
- education = degree lines (大學/學士/碩士 etc.), not job title.
- For websites, prefer the clinic/company domain over watermark directories (e.g. prefer gloryin.com over chinesedoctor.com.hk).
- WhatsApp numbers go in whatsapp (and may also be personalPhone).
- Do not invent values not supported by the text.

OCR raw text:
---
$rawText
---
''';

/// OpenAI-compatible (OpenRouter / OpenAI) + optional Gemini REST client.
class HttpAiFieldExtractor implements AiFieldExtractor {
  HttpAiFieldExtractor({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<BusinessCardFields?> extract(
    String rawText, {
    AiExtractConfig? config,
  }) async {
    final cfg = config;
    if (cfg == null || !cfg.enabled || cfg.apiKey.trim().isEmpty) {
      return null;
    }
    final text = rawText.trim();
    if (text.isEmpty) return null;

    try {
      await CrashLog.log(
        'AiFieldExtractor: provider=${cfg.provider} model=${cfg.model}',
      );
      final content = cfg.provider.toLowerCase() == 'gemini'
          ? await _callGemini(cfg, text)
          : await _callOpenAiCompatible(cfg, text);
      if (content == null || content.trim().isEmpty) return null;
      return parseAiJson(content);
    } catch (e, st) {
      await CrashLog.log('AiFieldExtractor failed', e, st);
      return null;
    }
  }

  Future<String?> _callOpenAiCompatible(AiExtractConfig cfg, String rawText) async {
    final base = cfg.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/chat/completions');
    final body = jsonEncode({
      'model': cfg.model,
      'temperature': 0,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You extract business-card fields. Reply with a JSON object only.',
        },
        {'role': 'user', 'content': buildAiExtractionPrompt(rawText)},
      ],
    });
    final res = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${cfg.apiKey}',
            // OpenRouter optional headers (harmless for OpenAI)
            'HTTP-Referer': 'https://github.com/x43helios/business-card-scanner-ios',
            'X-Title': 'Business Card Scanner',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 45));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      await CrashLog.log(
        'AiFieldExtractor OpenAI HTTP ${res.statusCode}: ${res.body.length > 400 ? res.body.substring(0, 400) : res.body}',
      );
      return null;
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = map['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final msg = choices.first['message'];
    if (msg is! Map) return null;
    return msg['content']?.toString();
  }

  Future<String?> _callGemini(AiExtractConfig cfg, String rawText) async {
    // generativelanguage.googleapis.com/v1beta/models/{model}:generateContent
    final model = cfg.model.contains('/')
        ? cfg.model.split('/').last
        : cfg.model;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${Uri.encodeQueryComponent(cfg.apiKey)}',
    );
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': buildAiExtractionPrompt(rawText)},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0,
        'responseMimeType': 'application/json',
      },
    });
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 45));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      await CrashLog.log(
        'AiFieldExtractor Gemini HTTP ${res.statusCode}: ${res.body.length > 400 ? res.body.substring(0, 400) : res.body}',
      );
      return null;
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = map['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final content = candidates.first['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;
    return parts.first['text']?.toString();
  }
}

/// Parse model JSON (strips optional ``` fences) into [BusinessCardFields].
BusinessCardFields? parseAiJson(String content) {
  var s = content.trim();
  if (s.startsWith('```')) {
    s = s.replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '');
    s = s.replaceFirst(RegExp(r'\s*```$'), '');
    s = s.trim();
  }
  final decoded = jsonDecode(s);
  if (decoded is! Map) return null;
  final map = <String, dynamic>{};
  for (final e in decoded.entries) {
    map[e.key.toString()] = e.value;
  }
  final fields = BusinessCardFields.fromMap(map);
  return fields.isEmpty ? null : fields;
}

/// Test double — returns a fixed result or throws.
class FakeAiFieldExtractor implements AiFieldExtractor {
  FakeAiFieldExtractor({this.result, this.error});

  final BusinessCardFields? result;
  final Object? error;

  @override
  Future<BusinessCardFields?> extract(
    String rawText, {
    AiExtractConfig? config,
  }) async {
    if (error != null) throw error!;
    if (config != null && !config.enabled) return null;
    return result;
  }
}
