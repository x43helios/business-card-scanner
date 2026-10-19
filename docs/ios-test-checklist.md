# iOS test checklist (parity with Android)

Run on a **Mac** with Simulator or a physical iPhone (iOS 15.5+). Mark each row Pass / Fail / Skip.

Environment: Flutter ______ | Xcode ______ | Device/Sim ______ | Date ______ (Asia/Hong_Kong)

| # | Area | Steps | Expected | Result |
|---|------|-------|----------|--------|
| 1 | Home | Launch app | Contact list (empty or saved); FAB / scan entry; language OK (EN / 繁中) | |
| 2 | Demo OCR | Tap in-app **Run demo OCR** (or pick image whose name contains `demo`/`sample`) | Review screen with 陳大文 / Helios sample fields; **not** Glory-In fixture | |
| 3 | Camera | Grant camera → take a clear bilingual card photo | Preparing… → Recognizing… → editable fields; Chinese + Latin text present when ML Kit OK | |
| 4 | Gallery | Grant photos → pick a card image | Same OCR pipeline as camera | |
| 5 | AI extract | Settings → enable AI, set OpenRouter key (or dart-define), scan a real card | Fields enriched (names/company/phone/email); if AI fails, regex FieldParser still fills contacts | |
| 6 | Save | Save from review | Contact appears in list; reopen detail shows all fields | |
| 7 | Merge | Scan second card that matches name/company/phone/email | Merge dialog; choosing merge updates contact / multi-card | |
| 8 | Settings | Toggle language, save-photo, AI provider/model/key | Prefs persist across relaunch; footer shows app version | |
| 9 | Export | Contact detail → export vCard / CSV / PDF | Files shareable; content includes expanded fields | |
| 10 | Permissions deny | Deny camera or photos once | Soft message / settings link; no crash | |
| 11 | Crash log | Force a soft failure if possible | `crash_log.txt` under app documents; app stays up | |

## Notes

- Glory-In fixture (`test/fixtures/gloryin_cathy_cheung.jpg`) is **unit-test / manual gallery only** — do not rename it to contain `demo`/`sample`.
- Default AI model (when key present): `minimax/minimax-m3.1-flash:free` via OpenRouter. `thinkingmachines/inkling-small:free` cannot be called from the app (harness-only 403).
- Without a Mac: Linux cannot run Simulator or produce IPA; Android debug APKs remain the CI smoke path.
