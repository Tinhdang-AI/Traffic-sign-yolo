import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_dashboard/admin_dashboard_screen.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

  runApp(const SentinelWebApp());
}

class SentinelWebApp extends StatelessWidget {
  const SentinelWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);

    return MaterialApp(
      title: 'SENTINEL ADMIN',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
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
        textTheme: GoogleFonts.interTextTheme(base.textTheme),
      ),
      home: const AdminDashboardScreen(),
    );
  }
}