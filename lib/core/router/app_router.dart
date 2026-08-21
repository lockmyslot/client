import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/groups/screens/groups_list_screen.dart';
import '../../features/groups/screens/create_group_screen.dart';
import '../../features/groups/screens/join_group_screen.dart';
import '../../features/groups/screens/group_detail_screen.dart';
import '../../features/groups/screens/members_screen.dart';
import '../../features/resources/screens/create_resource_screen.dart';
import '../../features/resources/screens/resource_detail_screen.dart';
import '../../features/resources/screens/booking_rules_screen.dart';
import '../../features/bookings/screens/availability_screen.dart';
import '../../features/bookings/screens/quick_booking_screen.dart';
import '../../features/bookings/screens/bookings_calendar_screen.dart';
import '../../features/bookings/screens/my_bookings_screen.dart';

CustomTransitionPage<void> _buildSmoothTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.05, 0.0),
        end: Offset.zero,
      ).animate(curvedAnimation);

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(curvedAnimation);

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/groups',
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isLoggingIn = state.matchedLocation == '/register';

      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/register';
      }

      if (isLoggingIn) {
        return '/groups';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildSmoothTransition(
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-book',
        pageBuilder: (context, state) => _buildSmoothTransition(
          state: state,
          child: QuickBookingScreen(
            initialGroupId: state.uri.queryParameters['group'],
          ),
        ),
      ),
      GoRoute(
        path: '/groups',
        pageBuilder: (context, state) => _buildSmoothTransition(
          state: state,
          child: const GroupsListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'create',
            pageBuilder: (context, state) => _buildSmoothTransition(
              state: state,
              child: const CreateGroupScreen(),
            ),
          ),
          GoRoute(
            path: 'join',
            pageBuilder: (context, state) => _buildSmoothTransition(
              state: state,
              child: const JoinGroupScreen(),
            ),
          ),
          GoRoute(
            path: ':group_id',
            pageBuilder: (context, state) {
              final groupId = state.pathParameters['group_id']!;
              return _buildSmoothTransition(
                state: state,
                child: GroupDetailScreen(groupId: groupId),
              );
            },
            routes: [
              GoRoute(
                path: 'members',
                pageBuilder: (context, state) {
                  final groupId = state.pathParameters['group_id']!;
                  return _buildSmoothTransition(
                    state: state,
                    child: MembersScreen(groupId: groupId),
                  );
                },
              ),
              GoRoute(
                path: 'my_bookings',
                pageBuilder: (context, state) {
                  final groupId = state.pathParameters['group_id']!;
                  return _buildSmoothTransition(
                    state: state,
                    child: MyBookingsScreen(groupId: groupId),
                  );
                },
              ),
              GoRoute(
                path: 'resources/create',
                pageBuilder: (context, state) {
                  final groupId = state.pathParameters['group_id']!;
                  return _buildSmoothTransition(
                    state: state,
                    child: CreateResourceScreen(groupId: groupId),
                  );
                },
              ),
              GoRoute(
                path: 'resources/:resource_id',
                pageBuilder: (context, state) {
                  final groupId = state.pathParameters['group_id']!;
                  final resourceId = state.pathParameters['resource_id']!;
                  return _buildSmoothTransition(
                    state: state,
                    child: ResourceDetailScreen(groupId: groupId, resourceId: resourceId),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'rules',
                    pageBuilder: (context, state) {
                      final groupId = state.pathParameters['group_id']!;
                      final resourceId = state.pathParameters['resource_id']!;
                      return _buildSmoothTransition(
                        state: state,
                        child: BookingRulesScreen(groupId: groupId, resourceId: resourceId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'book',
                    pageBuilder: (context, state) {
                      final groupId = state.pathParameters['group_id']!;
                      final resourceId = state.pathParameters['resource_id']!;
                      return _buildSmoothTransition(
                        state: state,
                        child: AvailabilityScreen(groupId: groupId, resourceId: resourceId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'bookings',
                    pageBuilder: (context, state) {
                      final groupId = state.pathParameters['group_id']!;
                      final resourceId = state.pathParameters['resource_id']!;
                      return _buildSmoothTransition(
                        state: state,
                        child: BookingsCalendarScreen(groupId: groupId, resourceId: resourceId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.listen((_) => notifyListeners());
  }
}
