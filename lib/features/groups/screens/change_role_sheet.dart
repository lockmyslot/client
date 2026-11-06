import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/groups_repository.dart';
import '../data/models/group_member.dart';
import '../providers/groups_provider.dart';
import '../../../core/utils/date_utils.dart';

class ChangeRoleSheet extends ConsumerStatefulWidget {
  final String groupId;
  final GroupMember member;

  const ChangeRoleSheet({
    super.key,
    required this.groupId,
    required this.member,
  });

  static Future<void> show(
    BuildContext context, {
    required String groupId,
    required GroupMember member,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ChangeRoleSheet(groupId: groupId, member: member),
    );
  }

  @override
  ConsumerState<ChangeRoleSheet> createState() => _ChangeRoleSheetState();
}

class _ChangeRoleSheetState extends ConsumerState<ChangeRoleSheet> {
  late String _selectedRole;
  late DateTime _expiresAt;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final role = widget.member.role.toUpperCase();
    _selectedRole = role == 'MOD' ? 'MODERATOR' : role;
    _expiresAt =
        widget.member.expiresAt ??
        DateTime.now().add(const Duration(days: 7));
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

  Future<void> _saveRole() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
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

      final targetUserId = widget.member.userId.trim().isNotEmpty
          ? widget.member.userId.trim()
          : widget.member.id.trim();

      await ref.read(groupsRepositoryProvider).updateMemberRole(
        widget.groupId,
        targetUserId,
        _selectedRole,
        expiresAt: expiry,
      );

      ref.invalidate(groupMembersProvider(widget.groupId));
      ref.invalidate(groupDetailProvider(widget.groupId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Updated ${widget.member.displayName} to $_selectedRole',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Change Member Role',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a new role for ${widget.member.displayName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildRoleOption(
                role: 'ADMIN',
                title: 'Admin',
                subtitle:
                    'Full control over group settings, resources, and members',
                icon: Icons.shield,
              ),
              const SizedBox(height: 8),
              _buildRoleOption(
                role: 'MODERATOR',
                title: 'Moderator',
                subtitle:
                    'Can manage bookings, maintenance tasks, and remove guests',
                icon: Icons.security,
              ),
              const SizedBox(height: 8),
              _buildRoleOption(
                role: 'MEMBER',
                title: 'Member',
                subtitle: 'Standard access to view resources and make bookings',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 8),
              _buildRoleOption(
                role: 'GUEST',
                title: 'Guest',
                subtitle:
                    'Temporary access, auto-removed on the set expiration date',
                icon: Icons.badge,
              ),
              if (_selectedRole == 'GUEST') ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.event_available,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Auto-Removal Date'),
                    subtitle: Text(
                      AppDateUtils.formatDisplayDate(_expiresAt),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _saveRole,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save Role',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedRole == role;

    return Card(
      elevation: 0,
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.4)
          : colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
