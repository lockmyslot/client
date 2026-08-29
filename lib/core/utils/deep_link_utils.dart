import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/ui.dart';

class DeepLinkUtils {
  static const String appScheme = 'lockmyslot';
  static const String webHost = 'lockmyslot.app';

  /// Generates the universal web deep link: https://lockmyslot.app/join?code=XYZ123
  static String buildWebInviteLink(String inviteCode) {
    final cleanCode = inviteCode.trim().toUpperCase();
    return 'https://$webHost/join?code=$cleanCode';
  }

  /// Generates the custom scheme deep link: lockmyslot://join?code=XYZ123
  static String buildCustomSchemeInviteLink(String inviteCode) {
    final cleanCode = inviteCode.trim().toUpperCase();
    return '$appScheme://join?code=$cleanCode';
  }

  /// Shows an invite bottom sheet with options to copy the code or share the deep link.
  static void showInviteSheet(
    BuildContext context, {
    required String groupName,
    required String inviteCode,
  }) {
    final cleanCode = inviteCode.trim().toUpperCase();
    final inviteLink = buildWebInviteLink(cleanCode);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Invite to $groupName').h3(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(modalContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share this invite link or code with others to let them join your group.',
                ).muted().small(),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(modalContext)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(modalContext).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('INVITE CODE').small().semiBold().muted(),
                      const SizedBox(height: 4),
                      Text(cleanCode).mono().h2(),
                      const SizedBox(height: 8),
                      Text(
                        inviteLink,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(modalContext).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteLink));
                    Navigator.of(modalContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invite link copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Copy Invite Link'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: cleanCode));
                    Navigator.of(modalContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invite code copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Copy Code Only'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
