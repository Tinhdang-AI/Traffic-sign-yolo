import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/main_shell.dart';
import 'core/theme/app_colors.dart';
import 'controllers/app_shell_provider.dart';
import 'controllers/navigation_provider.dart';
import 'controllers/auth_provider.dart';
import 'controllers/settings_provider.dart';
import 'controllers/detection_provider.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF131313),
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppShellProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DetectionProvider()),
      ],
      child: const SentinelApp(),
    ),
  );
}

class SentinelApp extends StatelessWidget {
  const SentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'SENTINEL TRAFFIC',
          debugShowCheckedModeBanner: false,
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: const MainShell(),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: const ColorScheme.light(
        background: Color(0xFFF8F9FA),
        surface: Colors.white,
        surfaceVariant: Color(0xFFE9ECEF),
        primary: AppColors.primaryContainer, // Blue
        primaryContainer: AppColors.primary,
        onPrimary: Colors.white,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondaryContainer,
        secondaryContainer: AppColors.secondary,
        onSecondary: Colors.white,
        tertiary: AppColors.tertiaryContainer,
        tertiaryContainer: AppColors.tertiary,
        onTertiary: Colors.white,
        error: AppColors.errorContainer,
        errorContainer: AppColors.error,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        onSurface: Color(0xFF212529),
        onSurfaceVariant: Color(0xFF495057),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: Color(0xFF212529)),
        titleTextStyle: TextStyle(color: Color(0xFF212529), fontSize: 20, fontWeight: FontWeight.w600),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? Colors.white
              : AppColors.outline,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? AppColors.primaryContainer
              : const Color(0xFFE9ECEF),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primaryContainer,
        thumbColor: AppColors.primaryContainer,
        inactiveTrackColor: Color(0xFFE9ECEF),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        background: AppColors.background,
        surface: AppColors.background,
        surfaceVariant: AppColors.surfaceContainerHighest,
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimary,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondary: AppColors.onSecondary,
        tertiary: AppColors.tertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiary: AppColors.onTertiary,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
      ),
      textTheme: base.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceContainer.withOpacity(0.85),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? AppColors.onPrimary
              : AppColors.outline,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerHighest,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primaryContainer,
        thumbColor: AppColors.primary,
        inactiveTrackColor: AppColors.outlineVariant,
      ),
    );
  }
}
