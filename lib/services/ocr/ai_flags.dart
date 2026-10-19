/// Compile-time AI field-extraction config (no secrets committed).
/// Default: free OpenRouter model minimax/minimax-m3.1-flash:free (fast, correct on HK cards).
/// Note: thinkingmachines/inkling-small:free is harness-only (403 from app HTTP); do not use.
///
/// Examples:
///   flutter build apk --dart-define=CARD_AI_API_KEY=sk-... \
///     --dart-define=CARD_AI_BASE_URL=https://openrouter.ai/api/v1 \
///     --dart-define=CARD_AI_MODEL=minimax/minimax-m3.1-flash:free \
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
  defaultValue: 'minimax/minimax-m3.1-flash:free',
);

/// `openai` = OpenAI-compatible chat completions; `gemini` = Google Generative Language API.
const String kCardAiProvider =
    String.fromEnvironment('CARD_AI_PROVIDER', defaultValue: 'openai');
