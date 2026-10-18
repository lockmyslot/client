import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../../bookings/providers/my_bookings_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class MeProfileScreen extends ConsumerWidget {
  const MeProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final groupsAsync = ref.watch(myGroupsProvider);
    final bookingsAsync = ref.watch(
      allBookingsProvider((groupId: null, status: 'CONFIRMED')),
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final initial = (user?.displayName.isNotEmpty == true)
        ? user!.displayName[0].toUpperCase()
        : 'U';

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverAppBar.large(
            title: Text('Me'),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Header Card
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.4),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              initial,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(user?.displayName ?? 'User').h2(),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Member',
                              style: TextStyle(
                                color: colorScheme.onSecondaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (user?.createdAt != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Member since ${AppDateUtils.formatDisplayDate(user!.createdAt)}',
                            ).small().muted(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Overview Stats
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: colorScheme.outlineVariant
                                  .withOpacity(0.4),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.group_outlined,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('My Groups').small().muted(),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                groupsAsync.when(
                                  data: (groups) =>
                                      Text('${groups.length}').h2(),
                                  loading: () => const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  error: (_, __) => const Text('0').h2(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: colorScheme.outlineVariant
                                  .withOpacity(0.4),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bookmark_added_outlined,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Confirmed').small().muted(),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                bookingsAsync.when(
                                  data: (bookings) =>
                                      Text('${bookings.length}').h2(),
                                  loading: () => const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  error: (_, __) => const Text('0').h2(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quick Actions
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.vpn_key_outlined,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Join a Group'),
                          subtitle: const Text(
                            'Enter code to join an existing group',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          onTap: () => context.push('/groups/join'),
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          color: colorScheme.outlineVariant.withOpacity(0.4),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.add_circle_outline,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Create a Group'),
                          subtitle: const Text(
                            'Set up a new group for sharing slots',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(20),
                            ),
                          ),
                          onTap: () => context.push('/groups/create'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // About & System
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.4),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text('Lock My Slot'),
                      subtitle: const Text('Version 1.0.0'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await ConfirmDialog.show(
                        context,
                        title: 'Sign Out',
                        message: 'Are you sure you want to sign out?',
                        confirmText: 'Sign Out',
                        isDestructive: true,
                      );
                      if (confirmed == true) {
                        ref.read(authProvider.notifier).logout();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(
                        color: colorScheme.error.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.logout_outlined),
                    label: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
