import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/groups_repository.dart';
import '../providers/groups_provider.dart';
import 'create_group_sheet.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/deep_link_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/m3_collapsing_app_bar.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  String _getGroupInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'G';

    final words = trimmed
        .split(RegExp(r'[\s\-_]+'))
        .where((w) => RegExp(r'[a-zA-Z0-9]').hasMatch(w))
        .toList();

    if (words.length >= 2) {
      final first = words[0].characters.firstWhere(
            (c) => RegExp(r'[a-zA-Z0-9]').hasMatch(c),
            orElse: () => words[0].characters.first,
          );
      final second = words[1].characters.firstWhere(
            (c) => RegExp(r'[a-zA-Z0-9]').hasMatch(c),
            orElse: () => words[1].characters.first,
          );
      return '$first$second'.toUpperCase();
    }

    if (words.isNotEmpty) {
      final word = words[0];
      if (word.length <= 2) {
        return word.toUpperCase();
      }
      return word.characters.first.toUpperCase();
    }

    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myGroupsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            M3CollapsingAppBar(
              title: const Text('My Groups'),
              pinned: true,
            ),
            groupsAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorDisplay(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(myGroupsProvider),
                ),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.group_work_outlined,
                      title: 'No Groups Yet',
                      description:
                          'Create or join a group to start booking shared resources.',
                      action: PrimaryButton(
                        onPressed: () => CreateGroupSheet.show(context),
                        child: const Text('Create Your First Group'),
                      ),
                    ),
                  );
                }

                final hasPinned = groups.any((g) => g.isPinned);

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final group = groups[index];
                        final isFirstPinned =
                            hasPinned && group.isPinned && index == 0;
                        final isFirstUnpinned = hasPinned &&
                            !group.isPinned &&
                            (index == 0 || groups[index - 1].isPinned);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isFirstPinned)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 8.0,
                                    left: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.push_pin,
                                        size: 14,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'PINNED',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (isFirstUnpinned)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 8.0,
                                    left: 4,
                                    top: 4.0,
                                  ),
                                  child: Text(
                                    'ALL GROUPS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              Entrance(
                                delay: Duration(milliseconds: index * 60),
                                child: PressableScale(
                                  onTap: () =>
                                      context.push('/groups/${group.id}'),
                                  onLongPress: () {
                                    showModalBottomSheet(
                                      context: context,
                                      showDragHandle: true,
                                      builder: (ctx) => SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 8.0,
                                              ),
                                              child: Text(
                                                group.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 22,
                                                    ),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Divider(height: 1),
                                            ListTile(
                                              leading: Icon(
                                                group.isPinned
                                                    ? Icons.push_pin_outlined
                                                    : Icons.push_pin,
                                                color: colorScheme.primary,
                                              ),
                                              title: Text(
                                                group.isPinned
                                                    ? 'Unpin from top'
                                                    : 'Pin to top',
                                              ),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                ref
                                                    .read(
                                                      myGroupsProvider.notifier,
                                                    )
                                                    .togglePin(group.id);
                                              },
                                            ),
                                            ListTile(
                                              leading: Icon(
                                                Icons.person_add_outlined,
                                                color: colorScheme.primary,
                                              ),
                                              title: const Text('Invite'),
                                              onTap: () async {
                                                Navigator.pop(ctx);
                                                if (group.inviteCode != null &&
                                                    group.inviteCode!.isNotEmpty) {
                                                  DeepLinkUtils.showInviteSheet(
                                                    context,
                                                    groupName: group.name,
                                                    inviteCode:
                                                        group.inviteCode!,
                                                    groupId: group.id,
                                                  );
                                                } else if (group.isAdmin) {
                                                  try {
                                                    final detail = await ref
                                                        .read(
                                                          groupsRepositoryProvider,
                                                        )
                                                        .getGroupDetail(
                                                          group.id,
                                                        );
                                                    if (context.mounted &&
                                                        detail.inviteCode !=
                                                            null &&
                                                        detail.inviteCode!
                                                            .isNotEmpty) {
                                                      DeepLinkUtils
                                                          .showInviteSheet(
                                                        context,
                                                        groupName:
                                                            detail.name,
                                                        inviteCode:
                                                            detail.inviteCode!,
                                                        groupId: detail.id,
                                                      );
                                                    }
                                                  } catch (_) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Failed to load invite code',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                } else {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Only group admins can invite members',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 0,
                                    color: colorScheme.surfaceContainerLow,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: group.isPinned
                                            ? colorScheme.primary.withValues(
                                                alpha: 0.4,
                                              )
                                            : colorScheme.outlineVariant
                                                .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: kCardPadding,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  Container(
                                                    width: 48,
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      color: colorScheme
                                                          .primaryContainer,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      _getGroupInitials(
                                                        group.name,
                                                      ),
                                                      style: TextStyle(
                                                        color: colorScheme
                                                            .onPrimaryContainer,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  if (group.isAdmin)
                                                    Positioned(
                                                      right: -2,
                                                      bottom: -2,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              3,
                                                            ),
                                                        decoration:
                                                            BoxDecoration(
                                                              color: colorScheme
                                                                  .primary,
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                color: colorScheme
                                                                    .surfaceContainerLow,
                                                                width: 1.5,
                                                              ),
                                                            ),
                                                        child: Icon(
                                                          Icons.shield,
                                                          size: 10,
                                                          color: colorScheme
                                                              .onPrimary,
                                                        ),
                                                      ),
                                                    )
                                                  else if (group.isGuest)
                                                    Positioned(
                                                      right: -2,
                                                      bottom: -2,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              3,
                                                            ),
                                                        decoration:
                                                            BoxDecoration(
                                                              color: colorScheme
                                                                  .secondary,
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                color: colorScheme
                                                                    .surfaceContainerLow,
                                                                width: 1.5,
                                                              ),
                                                            ),
                                                        child: Icon(
                                                          Icons.badge,
                                                          size: 10,
                                                          color: colorScheme
                                                              .onSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(group.name).h4(),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.people_outline,
                                                          size: 14,
                                                          color: colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '${group.memberCount} members',
                                                        ).small().muted(),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (group.isPinned)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    right: 6.0,
                                                  ),
                                                  child: Icon(
                                                    Icons.push_pin,
                                                    size: 16,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                              Icon(
                                                Icons.chevron_right_outlined,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: groups.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
