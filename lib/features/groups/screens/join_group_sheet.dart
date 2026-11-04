import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/groups_repository.dart';
import '../data/models/group.dart';
import '../providers/groups_provider.dart';
import '../../../core/ui/ui.dart';

class JoinGroupSheet extends ConsumerStatefulWidget {
  final String? initialCode;
  final void Function(Group group)? onSuccess;
  final VoidCallback? onClose;

  const JoinGroupSheet({
    super.key,
    this.initialCode,
    this.onSuccess,
    this.onClose,
  });

  static Future<Group?> show(
    BuildContext context, {
    String? initialCode,
  }) async {
    final group = await showModalBottomSheet<Group>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JoinGroupSheet(initialCode: initialCode),
    );
    if (group != null && context.mounted) {
      context.push('/groups/${group.id}');
    }
    return group;
  }

  @override
  ConsumerState<JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends ConsumerState<JoinGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.initialCode?.trim().toUpperCase() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant JoinGroupSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCode != oldWidget.initialCode &&
        widget.initialCode != null) {
      _codeController.text = widget.initialCode!.trim().toUpperCase();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final code = _codeController.text.trim().toUpperCase();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(groupsRepositoryProvider);
      final group = await repo.joinGroup(code);
      ref.invalidate(myGroupsProvider);

      if (mounted) {
        if (widget.onSuccess != null) {
          widget.onSuccess!(group);
        } else {
          Navigator.of(context).pop(group);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Group',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Enter the 6-character group invite code',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              ref.watch(pendingInvitesProvider).maybeWhen(
                data: (invites) {
                  if (invites.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mark_email_unread_outlined,
                              size: 16, color: cs.primary),
                          const SizedBox(width: 6),
                          Text(
                            'PENDING INVITATIONS (${invites.length})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...invites.map((invite) {
                        final inviter = invite.invitedByName ??
                            invite.invitedByUsername ??
                            'Admin';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invite.groupName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Invited by $inviter',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: cs.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(pendingInvitesProvider.notifier)
                                      .decline(invite.id);
                                },
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: cs.error,
                                ),
                                child: const Text('Decline'),
                              ),
                              const SizedBox(width: 4),
                              FilledButton.tonal(
                                onPressed: () async {
                                  await ref
                                      .read(pendingInvitesProvider.notifier)
                                      .accept(invite.id);
                                  if (context.mounted) {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    }
                                    GoRouter.maybeOf(context)
                                        ?.push('/groups/${invite.groupId}');
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Accept'),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: cs.outlineVariant.withValues(alpha: 0.5))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR ENTER CODE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: cs.outlineVariant.withValues(alpha: 0.5))),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                autofocus: widget.initialCode == null || widget.initialCode!.isEmpty,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Invite Code *',
                  hintText: 'e.g., AB12CD',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an invite code';
                  }
                  if (val.trim().length != 6) {
                    return 'Invite code must be exactly 6 characters';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleJoin(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: cs.error),
                ).small(),
              ],

              const SizedBox(height: 20),

              PrimaryButton(
                onPressed: _isLoading ? null : () => _handleJoin(),
                expand: true,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Join Group',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
