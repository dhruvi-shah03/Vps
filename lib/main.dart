import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'services/app_state.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorageService.init();
  await AppState.instance.initSession();

  // Custom ErrorWidget so any runtime rendering exception displays clearly on screen
  // instead of rendering a completely blank white container
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Form Rendering Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(const VPSApp());
}

class VPSApp extends StatefulWidget {
  const VPSApp({super.key});

  @override
  State<VPSApp> createState() => _VPSAppState();
}

class _VPSAppState extends State<VPSApp> {
  final AppState _appState = AppState.instance;

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _appState,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _appState.themeModeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const SplashScreen(),
            builder: (context, child) {
              return AppStateScope(
                state: _appState,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
