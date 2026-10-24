import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/app.dart';
import 'package:lockmyslot_app/features/auth/data/models/user.dart';
import 'package:lockmyslot_app/features/auth/providers/auth_provider.dart';
import 'package:lockmyslot_app/features/auth/screens/login_screen.dart';
import 'package:lockmyslot_app/features/auth/screens/splash_screen.dart';
import 'package:lockmyslot_app/features/groups/screens/groups_list_screen.dart';

class FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  FakeAuthNotifier(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void emitState(AuthState newState) {
    state = newState;
  }
}

void main() {
  group('App Startup Navigation Tests', () {
    testWidgets(
      'when opening the app while already logged in, shows SplashScreen first and never flashes LoginScreen before reaching GroupsListScreen',
      (WidgetTester tester) async {
        final authNotifier = FakeAuthNotifier(
          const AuthState(isLoading: true, isInitialized: false),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => authNotifier),
            ],
            child: const LockMySlotApp(),
          ),
        );

        // First frame: initial state is initializing, SplashScreen should be rendered
        await tester.pump();
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);

        // Simulate auth check completing with authenticated user
        authNotifier.emitState(
          AuthState(
            user: User(
              id: 'user-123',
              username: 'alice',
              displayName: 'Alice',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            isAuthenticated: true,
            isLoading: false,
            isInitialized: true,
          ),
        );

        // Pump and animate to next screen
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // User is now on the home screen (GroupsListScreen) and LoginScreen was NEVER displayed
        expect(find.byType(LoginScreen), findsNothing);
        expect(find.byType(GroupsListScreen), findsOneWidget);
      },
    );

    testWidgets(
      'when opening the app while unauthenticated, shows SplashScreen first and transitions to LoginScreen',
      (WidgetTester tester) async {
        final authNotifier = FakeAuthNotifier(
          const AuthState(isLoading: true, isInitialized: false),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => authNotifier),
            ],
            child: const LockMySlotApp(),
          ),
        );

        // First frame: SplashScreen is shown
        await tester.pump();
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);

        // Auth check completes: no session
        authNotifier.emitState(
          const AuthState(
            isAuthenticated: false,
            isLoading: false,
            isInitialized: true,
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Now user is transitioned to LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  });
}
