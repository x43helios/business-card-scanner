/// Compile-time AI field-extraction config (no secrets committed).
/// Note: thinkingmachines/inkling-small:free is OpenRouter harness-only (403 from plain app HTTP); do not use as APK default.
///
/// Examples:
///   flutter build apk --dart-define=CARD_AI_API_KEY=sk-... \
///     --dart-define=CARD_AI_BASE_URL=https://openrouter.ai/api/v1 \
///     --dart-define=CARD_AI_MODEL=meta-llama/llama-3.3-70b-instruct \
///     --dart-define=CARD_AI_PROVIDER=openai
///
/// Runtime Settings API key overrides [kCardAiApiKey] when non-empty.
const String kCardAiApiKey =
    String.fromEnvironment('CARD_AI_API_KEY', defaultValue: '');

const String kCardAiBaseUrl = String.fromEnvironment(
  'CARD_AI_BASE_URL',
  defaultValue: 'https://openrouter.ai/api/v1',
);

const String kCardAiModel = String.fromEnvironment(
  'CARD_AI_MODEL',
  defaultValue: 'meta-llama/llama-3.3-70b-instruct',
);

/// `openai` = OpenAI-compatible chat completions; `gemini` = Google Generative Language API.
const String kCardAiProvider =
    String.fromEnvironment('CARD_AI_PROVIDER', defaultValue: 'openai');
