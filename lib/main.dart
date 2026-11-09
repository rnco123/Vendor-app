import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_colors.dart';
import 'email_signin_screen.dart';
import 'shared/app_log.dart';
import 'shared/firebase_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    runApp(_ConfigErrorApp(
      message:
          'Could not load .env file.\n\n$e\n\nMake sure .env exists next to the app and restart.',
    ));
    return;
  }
  await initializeApp();
}

Future<void> initializeApp() async {
  final configError = FirebaseEnv.missingKeysMessage();
  final options = FirebaseEnv.tryLoadOptions();
  if (configError != null || options == null) {
    runApp(_ConfigErrorApp(
      message: configError ?? 'Firebase configuration is incomplete.',
    ));
    return;
  }

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(options: options);
    } on FirebaseException catch (e, st) {
      if (e.code != 'duplicate-app') {
        AppLog.caught('lib/main.dart:initializeApp', e, st);
        runApp(_ConfigErrorApp(
          message: 'Firebase failed to start: ${e.message ?? e.code}',
        ));
        return;
      }
    }
  }

  FirebaseDatabase.instance.databaseURL = options.databaseURL ??
      'https://${options.projectId}-default-rtdb.firebaseio.com';
  await AppLog.installCrashHandlers();

  runApp(const PartnerApp());
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings_suggest_outlined,
                        color: Color(0xFFE74C3C), size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'App configuration error',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFBBBBBB),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
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

class PartnerApp extends StatelessWidget {
  const PartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoolX Partner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.cardBackground,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionColor: Color(0x331DB954),
          selectionHandleColor: AppColors.primary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.cardBackground,
          dialBackgroundColor: AppColors.background,
          dialHandColor: AppColors.primary,
          dialTextColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.textPrimary,
          ),
          hourMinuteColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary.withAlpha(51) : AppColors.background,
          ),
          hourMinuteTextColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textPrimary,
          ),
          dayPeriodColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.background,
          ),
          dayPeriodTextColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.textSecondary,
          ),
          dayPeriodBorderSide: const BorderSide(color: AppColors.divider),
          entryModeIconColor: AppColors.textSecondary,
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarDividerColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
        ),
        child: ColoredBox(
          color: AppColors.background,
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(alwaysUse24HourFormat: false),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
      home: const PartnerGate(),
    );
  }
}

class PartnerGate extends StatelessWidget {
  const PartnerGate({super.key});

  Future<Widget> _start() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const EmailLoginScreen();
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = (userDoc.data()?['role'] as String? ?? '').toLowerCase();
      if (role != 'vendor') {
        await FirebaseAuth.instance.signOut();
        return const EmailLoginScreen();
      }
      return await partnerHomeFor(user.uid);
    } catch (e, st) {
      AppLog.caught('lib/main.dart:PartnerGate', e, st);
      return const EmailLoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _start(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snap.data!;
      },
    );
  }
}
