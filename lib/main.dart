import 'package:demos/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'router.dart';
import 'services/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qanpblqitdrnwgsgarrd.supabase.co',
    anonKey: 'sb_publishable_Wi6HSQQguRTqqKP-cmk_iA_RNVbLCt0',
  );
  usePathUrlStrategy(); // Quita el '#' de la URL
  await AppService.initTheme();
  // await AppService.initPrefs();
  await AuthService.checkLoginStatus();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // 3. Definir idiomas soportados
          supportedLocales: const [
            Locale('es', 'ES'), // Español
            Locale('en', 'US'), // Inglés (opcional)
          ],

          // 4. Forzar el idioma si es necesario
          locale: const Locale('es', 'ES'),
          title: 'Flota',
          themeMode: mode,
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.indigo,
          ),
          routerConfig: appRouter,
        );
      },
    );
  }
}
