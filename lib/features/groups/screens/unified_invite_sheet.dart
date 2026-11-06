import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/deep_link_utils.dart';
import '../data/groups_repository.dart';
import '../providers/groups_provider.dart';

enum InviteTab {
  share,
  direct,
}

class UnifiedInviteSheet extends ConsumerStatefulWidget {
  final String groupName;
  final String inviteCode;
  final String? groupId;
  final InviteTab initialTab;

  const UnifiedInviteSheet({
    super.key,
    required this.groupName,
    required this.inviteCode,
    this.groupId,
    this.initialTab = InviteTab.share,
  });

  static Future<void> show(
    BuildContext context, {
    required String groupName,
    required String inviteCode,
    String? groupId,
    InviteTab initialTab = InviteTab.share,
  }) async {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UnifiedInviteSheet(
        groupName: groupName,
        inviteCode: inviteCode,
        groupId: groupId,
        initialTab: initialTab,
      ),
    );
  }

  @override
  ConsumerState<UnifiedInviteSheet> createState() => _UnifiedInviteSheetState();
}

class _UnifiedInviteSheetState extends ConsumerState<UnifiedInviteSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _currentCode;
  bool _isRegenerating = false;

  // Direct invite state
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  String _selectedRole = 'GUEST';
  late DateTime _expiresAt;
  bool _isInviting = false;
  String? _directInviteError;
  String? _lastInvitedUser;
  String? _lastInvitedRole;

  @override
  void initState() {
    super.initState();
    _currentCode = widget.inviteCode.trim().toUpperCase();
    _expiresAt = DateTime.now().add(const Duration(days: 7));
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == InviteTab.direct ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final initial = _expiresAt.isAfter(now)
        ? _expiresAt
        : now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _expiresAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
      });
    }
  }

  String _formatError(String rawError, String username) {
    final clean = rawError.replaceFirst('Exception: ', '').toLowerCase();
    if (clean.contains('user_not_found') || clean.contains('not found')) {
      return 'User "@$username" not found. Please verify the username.';
    }
    if (clean.contains('already_a_member') ||
        clean.contains('already a member')) {
      return 'User "@$username" is already a member of this group.';
    }
    if (clean.contains('cannot_invite_self')) {
      return 'You cannot invite yourself to the group.';
    }
    if (clean.contains('invite_already_pending')) {
      return 'An invitation is already pending for "@$username".';
    }
    return rawError.replaceFirst('Exception: ', '');
  }

  Future<void> _handleDirectInvite() async {
    if (!_formKey.currentState!.validate() || widget.groupId == null) {
      return;
    }

    final rawUsername = _usernameController.text.trim();
    final cleanUsername = rawUsername.replaceFirst(RegExp(r'^@'), '').trim();

    setState(() {
      _isInviting = true;
      _directInviteError = null;
      _lastInvitedUser = null;
      _lastInvitedRole = null;
    });

    try {
      final repo = ref.read(groupsRepositoryProvider);
      DateTime? expiry;
      if (_selectedRole == 'GUEST') {
        expiry = DateTime(
          _expiresAt.year,
          _expiresAt.month,
          _expiresAt.day,
          23,
          59,
          59,
        );
      }

      await repo.inviteMember(
        widget.groupId!,
        cleanUsername,
        role: _selectedRole,
        expiresAt: expiry,
      );

      ref.invalidate(groupMembersProvider(widget.groupId!));
      ref.invalidate(groupDetailProvider(widget.groupId!));
      ref.invalidate(myGroupsProvider);

      if (mounted) {
        setState(() {
          _isInviting = false;
          _lastInvitedUser = cleanUsername;
          _lastInvitedRole = _selectedRole;
          _usernameController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInviting = false;
          _directInviteError = _formatError(e.toString(), cleanUsername);
        });
      }
    }
  }

  Future<void> _confirmAndRegenerateCode() async {
    if (widget.groupId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Regenerate Invite Code?'),
          content: const Text(
            'Existing invite links and codes will stop working immediately. Are you sure you want to generate a new code?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogCtx).colorScheme.error,
                foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
              ),
              child: const Text('Regenerate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isRegenerating = true;
    });

    try {
      final repo = ref.read(groupsRepositoryProvider);
      final updatedGroup = await repo.regenerateInviteCode(widget.groupId!);

      if (mounted) {
        setState(() {
          _isRegenerating = false;
          if (updatedGroup.inviteCode != null &&
              updatedGroup.inviteCode!.isNotEmpty) {
            _currentCode = updatedGroup.inviteCode!.trim().toUpperCase();
          }
        });

        ref.invalidate(groupDetailProvider(widget.groupId!));
        ref.invalidate(myGroupsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New invite code generated successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate code: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final inviteLink = DeepLinkUtils.buildWebInviteLink(_currentCode);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite to ${widget.groupName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Add new members to your group',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.link, size: 18),
                  text: 'Share Link & Code',
                ),
                Tab(
                  icon: Icon(Icons.alternate_email, size: 18),
                  text: 'Invite by Username',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab content
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: SizedBox(
              height: 280,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Share Link & Code
                  _buildShareTab(context, cs, inviteLink),

                  // Tab 2: Direct Invite by Username
                  _buildDirectInviteTab(context, cs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareTab(
    BuildContext context,
    ColorScheme cs,
    String inviteLink,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Code & Link Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INVITE CODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (widget.groupId != null)
                      InkWell(
                        onTap: _isRegenerating ? null : _confirmAndRegenerateCode,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isRegenerating
                                  ? SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cs.primary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.refresh,
                                      size: 14,
                                      color: cs.primary,
                                    ),
                              const SizedBox(width: 4),
                              Text(
                                'Regenerate',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link_outlined, size: 14, color: cs.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          inviteLink,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Primary Share button (Rich native share)
          Builder(
            builder: (btnContext) {
              return PrimaryButton(
                onPressed: () {
                  final box = btnContext.findRenderObject() as RenderBox?;
                  final origin = box != null
                      ? box.localToGlobal(Offset.zero) & box.size
                      : null;
                  DeepLinkUtils.shareInviteCode(
                    context,
                    _currentCode,
                    groupName: widget.groupName,
                    sharePositionOrigin: origin,
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Share Invite'),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Copy Link & Copy Code buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invite link copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Copy Link'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _currentCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invite code copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('Copy Code'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectInviteTab(BuildContext context, ColorScheme cs) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the username of the person you want to invite. They will receive a pending invitation in their app.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // Success feedback
            if (_lastInvitedUser != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invitation sent to @$_lastInvitedUser!',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          if (_lastInvitedRole != null)
                            Text(
                              'Role: $_lastInvitedRole',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Error feedback
            if (_directInviteError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _directInviteError!,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Username input field
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'e.g. johndoe',
                prefixIcon: const Icon(Icons.alternate_email, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: cs.surface,
              ),
              textInputAction: TextInputAction.send,
              onFieldSubmitted: (_) => _handleDirectInvite(),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Role selection
            Text(
              'Invite as Role',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('role_chip_guest'),
                  label: const Text('Guest (Default)'),
                  avatar: const Icon(Icons.badge, size: 16),
                  selected: _selectedRole == 'GUEST',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRole = 'GUEST');
                  },
                ),
                ChoiceChip(
                  key: const Key('role_chip_member'),
                  label: const Text('Member'),
                  avatar: const Icon(Icons.person_outline, size: 16),
                  selected: _selectedRole == 'MEMBER',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRole = 'MEMBER');
                  },
                ),
                ChoiceChip(
                  key: const Key('role_chip_moderator'),
                  label: const Text('Moderator'),
                  avatar: const Icon(Icons.security, size: 16),
                  selected: _selectedRole == 'MODERATOR',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRole = 'MODERATOR');
                  },
                ),
                ChoiceChip(
                  key: const Key('role_chip_admin'),
                  label: const Text('Admin'),
                  avatar: const Icon(Icons.shield, size: 16),
                  selected: _selectedRole == 'ADMIN',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRole = 'ADMIN');
                  },
                ),
              ],
            ),
            if (_selectedRole == 'GUEST') ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.event_available, color: cs.primary),
                  title: const Text('Guest Access Expires On'),
                  subtitle: Text(
                    AppDateUtils.formatDisplayDate(_expiresAt),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: _pickExpirationDate,
                    child: const Text('Change Date'),
                  ),
                  onTap: _pickExpirationDate,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Submit button
            PrimaryButton(
              onPressed: _isInviting ? null : _handleDirectInvite,
              child: _isInviting
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
                        Text('Send Invitation'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
