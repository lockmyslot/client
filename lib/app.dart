import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/color_scheme_provider.dart';
import 'core/theme/theme_provider.dart';

class LockMySlotApp extends ConsumerWidget {
  const LockMySlotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final colorSchemePref = ref.watch(appColorSchemeProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme? lightScheme;
        ColorScheme? darkScheme;

        if (colorSchemePref.isMaterialYou) {
          if (lightDynamic != null) {
            lightScheme = AppTheme.harmonizeDynamic(
              lightDynamic,
              Brightness.light,
            );
            darkScheme = darkDynamic != null
                ? AppTheme.harmonizeDynamic(
                    darkDynamic,
                    Brightness.dark,
                  )
                : null;
          }
        } else {
          lightScheme = AppTheme.schemeFromSeed(
            colorSchemePref.preferredColor,
            Brightness.light,
          );
          darkScheme = AppTheme.schemeFromSeed(
            colorSchemePref.preferredColor,
            Brightness.dark,
          );
        }

        return MaterialApp.router(
          title: 'Lock My Slot',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(lightScheme),
          darkTheme: AppTheme.darkTheme(darkScheme),
          themeMode: themeMode,
          routerConfig: router,
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.15,
                ),
              ),
              child: child,
            );
          },
        );
      },
    );
  }
}
