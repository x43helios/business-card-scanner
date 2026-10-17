import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._service);

  final SettingsService _service;
  AppSettings _settings = const AppSettings();
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get loaded => _loaded;

  Future<void> load() async {
    _settings = await _service.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(AppSettings Function(AppSettings) fn) async {
    _settings = await _service.save(fn(_settings));
    notifyListeners();
  }

  Future<AppSettings> persist(AppSettings s) async {
    _settings = await _service.save(s);
    notifyListeners();
    return _settings;
  }
}
