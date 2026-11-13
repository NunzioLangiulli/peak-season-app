import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/food_repository.dart';
import 'l10n/copy_service.dart';
import 'theme/icon_service.dart';
import 'notifications/notification_service.dart';
import 'providers/app_navigation.dart';
import 'providers/detail_layout_controller.dart';
import 'providers/home_controller.dart';
import 'providers/library_controller.dart';
import 'providers/notification_controller.dart';
import 'providers/settings_controller.dart';
import 'screens/root_shell.dart';
import 'theme/app_backdrop.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Preferences and database are loaded before the first frame (the
  // native splash stays visible meanwhile): this way every screen, including
  // those opened with Navigator.push, finds the data already loaded.
  final results = await Future.wait([
    SharedPreferences.getInstance(),
    FoodRepository.load(),
    NotificationService.instance.init(),
    CopyService.load(),
    IconService.load(),
  ]);
  final launch = await NotificationService.instance.launchResponse();
  runApp(PeakSeasonApp(
    prefs: results[0] as SharedPreferences,
    database: results[1] as FoodDatabase,
    launchPayload: launch?.payload,
  ));
}

class PeakSeasonApp extends StatelessWidget {
  const PeakSeasonApp({
    super.key,
    required this.prefs,
    required this.database,
    this.now,
    this.launchPayload,
  });

  final SharedPreferences prefs;
  final FoodDatabase database;

  /// Injectable "today" date for tests and previews.
  final DateTime? now;

  /// Payload of the notification that opened the app, if any.
  final String? launchPayload;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FoodDatabase>.value(value: database),
        ChangeNotifierProvider(create: (_) => AppNavigation()),
        ChangeNotifierProvider(create: (_) => SettingsController(prefs)),
        ChangeNotifierProvider(create: (_) => LibraryController(prefs)),
        ChangeNotifierProvider(create: (_) => HomeController(prefs, now: now)),
        ChangeNotifierProvider(create: (_) => DetailLayoutController(prefs)),
        ChangeNotifierProvider(
          lazy: false,
          create: (ctx) {
            final c = NotificationController(
              prefs: prefs,
              db: database,
              settings: ctx.read<SettingsController>(),
              library: ctx.read<LibraryController>(),
              navigation: ctx.read<AppNavigation>(),
              clock: now == null ? null : () => now!,
            );
            if (launchPayload != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => c.openPayload(launchPayload));
            }
            return c;
          },
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Peak Season',
          debugShowCheckedModeBanner: false,
          navigatorKey: context.read<AppNavigation>().navigatorKey,
          theme: AppTheme.light(frost: settings.frost),
          darkTheme: AppTheme.dark(frost: settings.frost),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: const [Locale('it'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // On tablets and wide screens the content stays a centred,
          // well-proportioned column instead of stretching to full width.
          builder: (context, child) => AppBackdrop(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: child,
              ),
            ),
          ),
          home: const AppBackdrop(child: RootShell()),
        ),
      ),
    );
  }
}
