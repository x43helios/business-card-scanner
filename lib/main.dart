import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'db/database_helper.dart';
import 'l10n/app_localizations.dart';
import 'providers/contacts_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsProvider = SettingsProvider(SettingsService());
  await settingsProvider.load();
  final contactsProvider = ContactsProvider(DatabaseHelper.instance);
  await contactsProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: contactsProvider),
      ],
      child: const BusinessCardScannerApp(),
    ),
  );
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
