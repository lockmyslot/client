import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/core/theme/item_color_provider.dart';
import 'package:lockmyslot_app/core/theme/item_color_utils.dart';
import 'package:lockmyslot_app/core/theme/theme_provider.dart';
import 'package:lockmyslot_app/features/groups/widgets/group_avatar.dart';
import 'package:lockmyslot_app/features/resources/widgets/resource_avatar.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  FakeFlutterSecureStorage([Map<String, String>? initialData]) {
    if (initialData != null) _data.addAll(initialData);
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }
}

void main() {
  group('GroupAvatar Color & Icon Tests', () {
    testWidgets('renders initials by default with theme styling', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GroupAvatar(name: 'Apartment 4B'),
            ),
          ),
        ),
      );

      expect(find.text('A4'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders icon when iconKey is provided', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GroupAvatar(
                name: 'Gaming Lounge',
                iconKey: 'game',
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.sports_esports), findsOneWidget);
      expect(find.text('GL'), findsNothing);
    });

    testWidgets('applies custom item color when colorHex is provided and useItemColors is true',
        (tester) async {
      const customHex = '#3B82F6';
      final expectedColor = parseHexColor(customHex)!;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GroupAvatar(
                name: 'Blue Group',
                colorHex: customHex,
                useItemColors: true,
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.color, equals(expectedColor.withValues(alpha: 0.16)));

      final text = tester.widget<Text>(find.text('BG'));
      expect(text.style?.color, equals(expectedColor));
    });

    testWidgets('uses theme colors when useItemColors is false despite colorHex being set',
        (tester) async {
      const customHex = '#EF4444';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          home: const Scaffold(
            body: GroupAvatar(
              name: 'Red Group',
              colorHex: customHex,
              useItemColors: false,
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(GroupAvatar));
      final themeScheme = Theme.of(context).colorScheme;

      final container = tester.widget<Container>(find.byType(Container).first);
      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.color, equals(themeScheme.primaryContainer));

      final text = tester.widget<Text>(find.text('RG'));
      expect(text.style?.color, equals(themeScheme.onPrimaryContainer));
    });
  });

  group('ResourceAvatar Color & Icon Tests', () {
    testWidgets('renders icon and applies custom color when colorHex is provided',
        (tester) async {
      const customHex = '#10B981';
      final expectedColor = parseHexColor(customHex)!;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ResourceAvatar(
                iconKey: 'washing_machine',
                name: 'Laundry 1',
                colorHex: customHex,
                useItemColors: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.local_laundry_service), findsOneWidget);

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.local_laundry_service));
      expect(iconWidget.color, equals(expectedColor));

      final container = tester.widget<Container>(find.byType(Container).first);
      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.color, equals(expectedColor.withValues(alpha: 0.16)));
    });

    testWidgets('falls back to theme colors when useItemColors is false', (tester) async {
      const customHex = '#F59E0B';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
          home: const Scaffold(
            body: ResourceAvatar(
              iconKey: 'computer',
              name: 'Lab PC',
              colorHex: customHex,
              useItemColors: false,
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(ResourceAvatar));
      final themeScheme = Theme.of(context).colorScheme;

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.computer));
      expect(iconWidget.color, equals(themeScheme.onPrimaryContainer));

      final container = tester.widget<Container>(find.byType(Container).first);
      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.color, equals(themeScheme.primaryContainer));
    });

    testWidgets('reacts to itemColorPreferenceProvider toggle dynamically',
        (tester) async {
      const customHex = '#8B5CF6';
      final expectedColor = parseHexColor(customHex)!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeStorageProvider.overrideWithValue(FakeFlutterSecureStorage()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  GroupAvatar(name: 'Group Dynamic', colorHex: customHex),
                  ResourceAvatar(name: 'Resource Dynamic', colorHex: customHex),
                ],
              ),
            ),
          ),
        ),
      );

      // By default useItemColors is true -> styled with custom color
      var groupText = tester.widget<Text>(find.text('GD'));
      expect(groupText.style?.color, equals(expectedColor));

      var resourceText = tester.widget<Text>(find.text('RD'));
      expect(resourceText.style?.color, equals(expectedColor));

      // Toggle preference off
      final element = tester.element(find.byType(GroupAvatar));
      final container = ProviderScope.containerOf(element);
      await container.read(itemColorPreferenceProvider.notifier).setUseItemColors(false);
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(GroupAvatar));
      final themeScheme = Theme.of(context).colorScheme;

      groupText = tester.widget<Text>(find.text('GD'));
      expect(groupText.style?.color, equals(themeScheme.onPrimaryContainer));

      resourceText = tester.widget<Text>(find.text('RD'));
      expect(resourceText.style?.color, equals(themeScheme.onPrimaryContainer));
    });
  });
}
