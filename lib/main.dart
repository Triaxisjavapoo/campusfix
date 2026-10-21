import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'data/firebase_repository.dart';
import 'state/app_state.dart';
import 'ui/app.dart';

const useEmulators = bool.fromEnvironment('USE_EMULATORS');
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if (!useEmulators && project.isEmpty) {
      throw StateError(
        'Falta la configuración Firebase. Ejecuta flutter run -d chrome --dart-define-from-file=firebase.config.json. Consulta docs/FIREBASE.md.',
      );
    }
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: useEmulators
            ? 'demo-campusfix-api-key'
            : const String.fromEnvironment('FIREBASE_API_KEY'),
        appId: useEmulators
            ? '1:123456789:web:campusfix'
            : const String.fromEnvironment('FIREBASE_APP_ID'),
        messagingSenderId: useEmulators
            ? '123456789'
            : const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: useEmulators ? 'demo-campusfix' : project,
        authDomain: useEmulators
            ? 'demo-campusfix.firebaseapp.com'
            : const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
        storageBucket: useEmulators
            ? 'demo-campusfix.firebasestorage.app'
            : const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      ),
    );
    if (useEmulators) {
      const host = String.fromEnvironment(
        'EMULATOR_HOST',
        defaultValue: 'localhost',
      );
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseStorage.instance.useStorageEmulator(host, 9199);
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }
    final repo = FirebaseRepository();
    runApp(
      MultiProvider(
        providers: [
          Provider.value(value: repo),
          ChangeNotifierProvider(create: (_) => AuthState(repo)),
          ChangeNotifierProxyProvider<AuthState, IncidentState>(
            create: (c) => IncidentState(repo, c.read<AuthState>()),
            update: (c, auth, previous) => previous!,
          ),
          ChangeNotifierProxyProvider<IncidentState, DashboardState>(
            create: (c) => DashboardState(c.read<IncidentState>()),
            update: (c, incidents, previous) => previous!,
          ),
          ChangeNotifierProvider(create: (_) => ThemeState()),
        ],
        child: const CampusFixApp(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings_suggest_outlined, size: 64),
                    const SizedBox(height: 24),
                    const Text(
                      'CampusFix necesita configuración',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                    SelectableText('$e'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CampusFixApp extends StatelessWidget {
  const CampusFixApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CampusFix · Gestión del campus',
    debugShowCheckedModeBanner: false,
    locale: const Locale('es', 'CR'),
    supportedLocales: const [Locale('es', 'CR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: campusTheme(Brightness.light),
    darkTheme: campusTheme(Brightness.dark),
    themeMode: context.watch<ThemeState>().isDark
        ? ThemeMode.dark
        : ThemeMode.light,
    home: const AuthGate(),
  );
}
