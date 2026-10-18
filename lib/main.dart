import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'db/database_helper.dart';
import 'l10n/app_localizations.dart';
import 'providers/contacts_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/crash_log.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  // Keep ensureInitialized + runApp in the SAME zone to avoid Flutter's
  // "Zone mismatch" binding warning (and hard-to-debug callback bugs).
  // Do NOT await CrashLog / heavy I/O before runApp — that keeps Android on
  // the splash screen and looks like a force-close / freeze after install.
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      unawaited(CrashLog.log('FlutterError', details.exception, details.stack));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Uncaught platform/async error: $error\n$stack');
      unawaited(CrashLog.log('PlatformDispatcher.onError', error, stack));
      return true;
    };

    unawaited(CrashLog.log('main: app starting'));
    final settingsProvider = SettingsProvider(SettingsService());
    final contactsProvider = ContactsProvider(DatabaseHelper.instance);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider.value(value: contactsProvider),
        ],
        child: _Bootstrap(
          settingsProvider: settingsProvider,
          contactsProvider: contactsProvider,
        ),
      ),
    );
  }, (error, stack) {
    debugPrint('Zone error: $error\n$stack');
    unawaited(CrashLog.log('Zone error', error, stack));
  });
}

/// Loads settings/DB after first frame so the UI can paint immediately.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap({
    required this.settingsProvider,
    required this.contactsProvider,
  });

  final SettingsProvider settingsProvider;
  final ContactsProvider contactsProvider;

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      await widget.settingsProvider.load();
      await widget.contactsProvider.load();
      await CrashLog.log('main: providers loaded');
      if (mounted) setState(() => _ready = true);
    } catch (e, st) {
      await CrashLog.log('main: provider load failed', e, st);
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Startup error: $_error')),
        ),
      );
    }
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return const BusinessCardScannerApp();
  }
}

class BusinessCardScannerApp extends StatelessWidget {
  const BusinessCardScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final systemLocale = View.of(context).platformDispatcher.locale;
    final locale = localeFromSettings(settings, systemLocale);

    return MaterialApp(
      title: '名片掃描',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4F72),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5DADE2),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const HomeScreen(),
    );
  }
}
