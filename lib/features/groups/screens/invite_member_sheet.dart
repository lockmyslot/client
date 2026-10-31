import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/groups_repository.dart';
import '../data/models/group_member.dart';
import '../providers/groups_provider.dart';
import '../../../core/ui/ui.dart';

class InviteMemberSheet extends ConsumerStatefulWidget {
  final String groupId;
  final String? groupName;

  const InviteMemberSheet({
    super.key,
    required this.groupId,
    this.groupName,
  });

  static Future<GroupMember?> show(
    BuildContext context, {
    required String groupId,
    String? groupName,
  }) async {
    return showModalBottomSheet<GroupMember>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InviteMemberSheet(
        groupId: groupId,
        groupName: groupName,
      ),
    );
  }

  @override
  ConsumerState<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<InviteMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  String _formatError(String rawError, String username) {
    final clean = rawError.replaceFirst('Exception: ', '').toLowerCase();
    if (clean.contains('user_not_found') || clean.contains('not found')) {
      return 'User "@$username" not found. Please verify the username.';
    }
    if (clean.contains('already_a_member') || clean.contains('already a member')) {
      return 'User "@$username" is already a member of this group.';
    }
    if (clean.contains('cannot_invite_self')) {
      return 'You cannot invite yourself to the group.';
    }
    return rawError.replaceFirst('Exception: ', '');
  }

  Future<void> _handleInvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawUsername = _usernameController.text.trim();
    final cleanUsername = rawUsername.replaceFirst(RegExp(r'^@'), '').trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(groupsRepositoryProvider);
      final member = await repo.inviteMember(widget.groupId, cleanUsername);

      ref.invalidate(groupMembersProvider(widget.groupId));
      ref.invalidate(groupDetailProvider(widget.groupId));
      ref.invalidate(myGroupsProvider);

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop(member);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Successfully invited @$cleanUsername to the group!',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _formatError(e.toString(), cleanUsername);
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite Member',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.groupName != null
                              ? 'Invite a user to ${widget.groupName} by username'
                              : 'Enter the username of the user you want to invite',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _usernameController,
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Username *',
                  hintText: 'e.g. alice',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a username';
                  }
                  final trimmed =
                      val.trim().replaceFirst(RegExp(r'^@'), '').trim();
                  if (trimmed.isEmpty) {
                    return 'Please enter a valid username';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleInvite(),
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
                onPressed: _isLoading ? null : () => _handleInvite(),
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Invite to Group',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
