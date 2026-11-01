import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class LockMySlotApp extends ConsumerWidget {
  const LockMySlotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: 'Lock My Slot',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(
            lightDynamic == null
                ? null
                : AppTheme.harmonizeDynamic(
                    lightDynamic,
                    Brightness.light,
                  ),
          ),
          darkTheme: AppTheme.darkTheme(
            darkDynamic == null
                ? null
                : AppTheme.harmonizeDynamic(
                    darkDynamic,
                    Brightness.dark,
                  ),
          ),
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
