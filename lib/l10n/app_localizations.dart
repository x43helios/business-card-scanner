import 'package:flutter/widgets.dart';

import '../models/app_settings.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('zh', 'Hant'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('zh'),
  ];

  bool get isZh {
    if (locale.languageCode != 'zh') return false;
    final script = locale.scriptCode?.toLowerCase();
    final country = locale.countryCode?.toUpperCase();
    if (script == 'hans') return false;
    if (country == 'CN' || country == 'SG') return false;
    return true; // zh, zh_Hant, zh_TW, zh_HK → Traditional for this app
  }

  String get appTitle => isZh ? '名片掃描' : 'Business Card Scanner';
  String get contacts => isZh ? '聯絡人' : 'Contacts';
  String get searchHint => isZh ? '搜尋姓名、公司、電話、電郵…' : 'Search name, company, phone, email…';
  String get allTags => isZh ? '全部' : 'All';
  String get scan => isZh ? '掃描' : 'Scan';
  String get settings => isZh ? '設定' : 'Settings';
  String get takePhoto => isZh ? '拍攝名片' : 'Take photo';
  String get pickGallery => isZh ? '從相簿選擇' : 'Choose from gallery';
  String get preparing => isZh ? '準備中…' : 'Preparing…';
  String get processing => isZh ? '辨識中…' : 'Recognizing…';
  String get reviewFields => isZh ? '檢視／編輯欄位' : 'Review / edit fields';
  String get save => isZh ? '儲存' : 'Save';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get delete => isZh ? '刪除' : 'Delete';
  String get export => isZh ? '匯出' : 'Export';
  String get language => isZh ? '語言' : 'Language';
  String get languageSystem => isZh ? '跟隨系統' : 'System';
  String get languageEn => 'English';
  String get languageZh => '繁體中文';
  String get saveCardPhoto => isZh ? '儲存名片照片' : 'Save card photo';
  String get saveCardPhotoDesc =>
      isZh ? '預設開啟。關閉後儲存聯絡人時不保留名片影像。' : 'Default on. Turn off to skip keeping card images when saving.';
  String get cloudOcr => isZh ? '雲端 OCR' : 'Cloud OCR';
  String get cloudConsentStatus => isZh ? '同意狀態' : 'Consent status';
  String get consentNotAsked => isZh ? '尚未詢問' : 'Not asked yet';
  String get consentGranted => isZh ? '已同意' : 'Granted';
  String get consentDenied => isZh ? '已拒絕（僅本機）' : 'Declined (local-only)';
  String get resetCloudConsent => isZh ? '重設雲端同意' : 'Reset cloud consent';
  String get syncPlaceholder =>
      isZh ? '雲端同步（Google / iCloud）— MVP 尚未實作' : 'Cloud sync (Google / iCloud) — not in MVP';
  String get exportVcard => isZh ? '匯出 vCard' : 'Export vCard';
  String get exportCsv => isZh ? '匯出 CSV' : 'Export CSV';
  String get exportPdf => isZh ? '匯出 PDF' : 'Export PDF';
  String get noContacts => isZh ? '尚無聯絡人。點擊 + 掃描名片。' : 'No contacts yet. Tap + to scan a card.';
  String get cards => isZh ? '名片' : 'Cards';
  String get tags => isZh ? '分類標籤' : 'Tags';
  String get addTag => isZh ? '新增標籤' : 'Add tag';
  String get mergeTitle => isZh ? '找到相似聯絡人' : 'Similar contact found';
  String get mergeMessage =>
      isZh ? '是否將此名片合併到既有聯絡人？' : 'Merge this card onto an existing contact?';
  String get mergeYes => isZh ? '是，合併' : 'Yes, merge';
  String get mergeNo => isZh ? '否，新建聯絡人' : 'No, new contact';
  String get fieldName => isZh ? '姓名' : 'Name';
  String get fieldChineseName => isZh ? '中文姓名' : 'Chinese name';
  String get fieldEnglishName => isZh ? '英文姓名' : 'English name';
  String get fieldTitle => isZh ? '職稱' : 'Title / position';
  String get fieldTitleChinese => isZh ? '中文職銜' : 'Title (Chinese)';
  String get fieldTitleEnglish => isZh ? '英文職銜' : 'Title (English)';
  String get fieldQualifications => isZh ? '專業資格／註冊編號' : 'Qualifications / registration';
  String get fieldEducation => isZh ? '學歷' : 'Education';
  String get fieldCompany => isZh ? '公司名稱' : 'Company name';
  String get fieldCompanyChinese => isZh ? '公司中文名' : 'Company (Chinese)';
  String get fieldCompanyEnglish => isZh ? '公司英文名' : 'Company (English)';
  String get fieldDepartment => isZh ? '部門' : 'Department';
  String get fieldAddress => isZh ? '公司地址' : 'Company address';
  String get fieldAddressChinese => isZh ? '公司地址（中文）' : 'Address (Chinese)';
  String get fieldAddressEnglish => isZh ? '公司地址（英文）' : 'Address (English)';
  String get fieldRoomFloor => isZh ? '室／樓層' : 'Room / floor';
  String get fieldDistrict => isZh ? '地區' : 'District';
  String get fieldPostalCode => isZh ? '郵遞區號' : 'Postal code';
  String get fieldPersonalPhone => isZh ? '手提／手機' : 'Mobile phone';
  String get fieldWhatsapp => isZh ? 'WhatsApp' : 'WhatsApp';
  String get fieldWechat => isZh ? '微信' : 'WeChat';
  String get fieldLineId => isZh ? 'LINE ID' : 'LINE ID';
  String get fieldPersonalEmail => isZh ? '個人電郵' : 'Personal email';
  String get fieldCompanyPhone => isZh ? '公司電話' : 'Company phone';
  String get fieldDirectLine => isZh ? '直線' : 'Direct line';
  String get fieldExtension => isZh ? '分機' : 'Extension';
  String get fieldCompanyEmail => isZh ? '公司電郵' : 'Company email';
  String get fieldFax => isZh ? '傳真' : 'Fax';
  String get fieldWebsite => isZh ? '公司網站' : 'Company website';
  String get fieldLinkedIn => isZh ? 'LinkedIn' : 'LinkedIn';
  String get fieldSocialMedia => isZh ? '其他社交媒體' : 'Other social media';
  String get fieldSlogan => isZh ? '標語' : 'Slogan';
  String get fieldServices => isZh ? '服務範圍／專科' : 'Services / specialties';
  String get fieldBusinessHours => isZh ? '營業時間' : 'Business hours';
  String get fieldQrInfo => isZh ? 'QR／連結' : 'QR / link info';
  String get fieldNotes => isZh ? '備註' : 'Notes';
  String get sectionIdentity => isZh ? '身份' : 'Identity';
  String get sectionOrganization => isZh ? '機構' : 'Organization';
  String get sectionContact => isZh ? '聯絡' : 'Contact';
  String get sectionAddress => isZh ? '地址' : 'Address';
  String get sectionOther => isZh ? '其他' : 'Other';
  String get cloudConsentTitle => isZh ? '使用雲端 OCR？' : 'Use cloud OCR?';
  String get cloudConsentBody => isZh
      ? '本機辨識未能取得結果。是否允許將影像送至雲端 OCR？（可拒絕並改為僅本機模式）\n此 MVP 不會實際上傳，僅記錄您的同意。'
      : 'On-device OCR did not return results. Allow cloud OCR? (Decline keeps local-only mode.)\nThis MVP does not upload; it only records consent.';
  String get agree => isZh ? '同意' : 'Agree';
  String get disagree => isZh ? '不同意' : 'Disagree';
  String get ocrSource => isZh ? '辨識來源' : 'OCR source';
  String get openImage => isZh ? '開啟名片照片' : 'Open card photo';
  String get cardImageNotSaved => isZh
      ? '尚未儲存名片照片。請到「設定」開啟「儲存名片照片」後重新掃描。'
      : 'Card photo was not saved. Enable “Save card photo” in Settings, then scan again.';
  String get cardImageMissing => isZh
      ? '名片照片檔案已遺失。'
      : 'Card photo file is missing.';
  String get selectForExport => isZh ? '選擇以匯出' : 'Select to export';
  String get exportSelected => isZh ? '匯出已選' : 'Export selected';
  String get done => isZh ? '完成' : 'Done';
  String get errorGeneric => isZh ? '發生錯誤' : 'Something went wrong';
  String get saved => isZh ? '已儲存' : 'Saved';
  String get confirmDelete => isZh ? '確定刪除此聯絡人？' : 'Delete this contact?';
  String get demoHint => isZh
      ? '提示：選取檔名含 demo/sample 的圖片可走通示範 OCR。'
      : 'Tip: pick an image whose filename contains demo/sample for stub OCR.';
  String get matchReasons => isZh ? '相符' : 'Matched on';
  String get emptyFieldHint => isZh ? '可手動填寫' : 'Optional — edit manually';
  String get aiSection => isZh ? 'AI 欄位抽取' : 'AI field extraction';
  String get aiFieldExtraction => isZh ? '啟用 AI 欄位抽取' : 'Enable AI field extraction';
  String get aiFieldExtractionDesc => isZh
      ? 'OCR 原文後以 AI 結構化為名片欄位；失敗時自動退回規則解析。需 API 金鑰。'
      : 'After OCR, AI structures fields as JSON; falls back to regex on failure. Needs an API key.';
  String get aiApiKey => isZh ? 'API 金鑰（執行時期）' : 'API key (runtime)';
  String get aiApiKeyHint => isZh
      ? '覆寫編譯期 CARD_AI_API_KEY；不會提交到 Git'
      : 'Overrides build-time CARD_AI_API_KEY; never committed';
  String get aiProvider => isZh ? '供應商' : 'Provider';
  String get aiProviderHint => isZh ? 'openai 或 gemini（留空用預設）' : 'openai or gemini (empty = default)';
  String get aiBaseUrl => isZh ? 'API Base URL' : 'API base URL';
  String get aiModel => isZh ? '模型' : 'Model';
  String get aiKeyMissing => isZh
      ? '尚未設定金鑰 — 請在上方填入，或用 --dart-define=CARD_AI_API_KEY=… 建置'
      : 'No API key — enter one above, or build with --dart-define=CARD_AI_API_KEY=…';
  String get refreshAiFields => isZh ? '重新抽取 AI 欄位' : 'Refresh AI fields';
  String get refreshAiSuccess => isZh ? 'AI 欄位已更新' : 'AI fields updated';
  String get refreshAiNoRawText => isZh
      ? '沒有 OCR 原文，無法重新抽取'
      : 'No OCR text available to re-extract';
  String get refreshAiNoKey => isZh
      ? '尚未設定 API 金鑰，請到設定填入'
      : 'No API key — set one in Settings';
  String get refreshAiDisabled => isZh
      ? '請先在設定啟用 AI 欄位抽取'
      : 'Enable AI field extraction in Settings first';
  String get refreshAiEmpty => isZh
      ? 'AI 未回傳欄位，請稍後再試'
      : 'AI returned no fields — try again later';
  String get refreshAiFailed => isZh
      ? 'AI 抽取失敗'
      : 'AI extraction failed';
}


class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'zh';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

Locale? localeFromSettings(AppSettings settings, Locale? system) {
  switch (settings.language) {
    case AppLanguage.english:
      return const Locale('en');
    case AppLanguage.traditionalChinese:
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
    case AppLanguage.system:
      return system;
  }
}
