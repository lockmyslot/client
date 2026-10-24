import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/screens/main_shell_screen.dart';
import '../../features/groups/screens/groups_list_screen.dart';
import '../../features/groups/screens/create_group_screen.dart';
import '../../features/groups/screens/join_group_screen.dart';
import '../../features/groups/screens/group_detail_screen.dart';
import '../../features/groups/screens/members_screen.dart';
import '../../features/resources/screens/create_resource_screen.dart';
import '../../features/resources/screens/resource_settings_screen.dart';
import '../../features/resources/screens/resource_detail_screen.dart';
import '../../features/resources/screens/maintenance_tasks_screen.dart';
import '../../features/bookings/data/models/booking.dart';
import '../../features/bookings/widgets/booking_details_form.dart';
import '../../features/bookings/screens/availability_screen.dart';
import '../../features/bookings/screens/quick_booking_screen.dart';
import '../../features/bookings/screens/bookings_calendar_screen.dart';
import '../../features/bookings/screens/my_bookings_screen.dart';
import '../../features/bookings/screens/all_bookings_screen.dart';
import '../../features/profile/screens/me_profile_screen.dart';

CustomTransitionPage<void> _buildSmoothTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.06, 0.0),
        end: Offset.zero,
      ).animate(curvedAnimation);

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(curvedAnimation);

      final secondaryAnimationCurved = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final secondarySlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.04, 0.0),
      ).animate(secondaryAnimationCurved);

      return SlideTransition(
        position: secondarySlide,
        child: SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        ),
      );
    },
  );
}

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated ||
            previous?.isLoading != next.isLoading ||
            previous?.isInitialized != next.isInitialized) {
          notifyListeners();
        }
      },
    );
  }
}

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      if (!authState.isInitialized) {
        if (state.matchedLocation == '/splash') return null;
        final target = state.uri.toString();
        if (target.isNotEmpty && target != '/' && target != '/splash') {
          return '/splash?returnTo=${Uri.encodeComponent(target)}';
        }
        return '/splash';
      }

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isSplashRoute = state.matchedLocation == '/splash' ||
          state.matchedLocation == '/';

      if (!authState.isAuthenticated) {
        if (isAuthRoute) return null;
        final returnTo = state.uri.queryParameters['returnTo'];
        if (returnTo != null && returnTo.isNotEmpty) {
          return '/login?returnTo=${Uri.encodeComponent(returnTo)}';
        }
        final target = state.uri.toString();
        if (target.isNotEmpty &&
            target != '/' &&
            target != '/splash' &&
            target != '/groups' &&
            target != '/bookings' &&
            target != '/me') {
          return '/login?returnTo=${Uri.encodeComponent(target)}';
        }
        return '/login';
      }

      if (isAuthRoute || isSplashRoute) {
        final returnTo = state.uri.queryParameters['returnTo'];
        if (returnTo != null && returnTo.isNotEmpty) {
          final decoded = Uri.decodeComponent(returnTo);
          if (decoded.startsWith('/') &&
              !decoded.startsWith('/login') &&
              !decoded.startsWith('/register') &&
              !decoded.startsWith('/splash')) {
            return decoded;
          }
        }
        return '/groups';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) => '/splash',
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _buildSmoothTransition(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _buildSmoothTransition(state: state, child: const RegisterScreen()),
      ),
      GoRoute(
        path: '/join',
        pageBuilder: (context, state) => _buildSmoothTransition(
          state: state,
          child: JoinGroupScreen(
            initialCode: state.uri.queryParameters['code'],
          ),
        ),
      ),
      GoRoute(
        path: '/quick-book',
        pageBuilder: (context, state) => _buildSmoothTransition(
          state: state,
          child: QuickBookingScreen(
            initialGroupId: state.uri.queryParameters['group'] ??
                state.uri.queryParameters['groupId'],
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/groups',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: GroupsListScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AllBookingsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MeProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/groups/create',
        pageBuilder: (context, state) => _buildSmoothTransition(
          state: state,
          child: const CreateGroupScreen(),
        ),
      ),
      GoRoute(
        path: '/groups/join',
        pageBuilder: (context, state) => _buildSmoothTransition(
          state: state,
          child: JoinGroupScreen(
            initialCode: state.uri.queryParameters['code'],
          ),
        ),
      ),
      GoRoute(
        path: '/groups/:group_id',
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
                child: ResourceDetailScreen(
                  groupId: groupId,
                  resourceId: resourceId,
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'settings',
                pageBuilder: (context, state) {
                  final groupId = state.pathParameters['group_id']!;
                  final resourceId = state.pathParameters['resource_id']!;
                  final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
                  return _buildSmoothTransition(
                    state: state,
                    child: ResourceSettingsScreen(
                      groupId: groupId,
                      resourceId: resourceId,
                      initialTab: tab,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'edit',
                pageBuilder: (context, state) {
                  final groupId = state.pathParameters['group_id']!;
                  final resourceId = state.pathParameters['resource_id']!;
                  return _buildSmoothTransition(
                    state: state,
                    child: ResourceSettingsScreen(
                      groupId: groupId,
                      resourceId: resourceId,
                      initialTab: 0,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'rules',
                pageBuilder: (context, state) {
                  final groupId = state.pathParameters['group_id']!;
                  final resourceId = state.pathParameters['resource_id']!;
                  return _buildSmoothTransition(
                    state: state,
                    child: ResourceSettingsScreen(
                      groupId: groupId,
                      resourceId: resourceId,
                      initialTab: 1,
                    ),
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
                    child: AvailabilityScreen(
                      groupId: groupId,
                      resourceId: resourceId,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'reschedule',
                pageBuilder: (context, state) {
                  final groupId = state.pathParameters['group_id']!;
                  final resourceId = state.pathParameters['resource_id']!;
                  final booking = state.extra as Booking?;
                  return _buildSmoothTransition(
                    state: state,
                    child: Scaffold(
                      appBar: AppBar(
                        title: Text(
                          booking?.resourceName != null
                              ? 'Reschedule ${booking!.resourceName}'
                              : 'Reschedule Booking',
                        ),
                      ),
                      body: SafeArea(
                        top: false,
                        child: BookingDetailsForm(
                          groupId: groupId,
                          resourceId: resourceId,
                          reschedulingBooking: booking,
                        ),
                      ),
                    ),
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
                    child: BookingsCalendarScreen(
                      groupId: groupId,
                      resourceId: resourceId,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'maintenance',
                pageBuilder: (context, state) {
                  final groupId = state.pathParameters['group_id']!;
                  final resourceId = state.pathParameters['resource_id']!;
                  return _buildSmoothTransition(
                    state: state,
                    child: MaintenanceTasksScreen(
                      groupId: groupId,
                      resourceId: resourceId,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
