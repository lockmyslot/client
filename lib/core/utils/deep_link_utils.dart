import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/groups/screens/unified_invite_sheet.dart';

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

  /// Opens the system's native share sheet with the group invite code and web link.
  static Future<void> shareInviteCode(
    BuildContext context,
    String inviteCode, {
    String? groupName,
    Rect? sharePositionOrigin,
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();
    final inviteLink = buildWebInviteLink(cleanCode);
    final text = groupName != null && groupName.isNotEmpty
        ? 'Join my group "$groupName" on LockMySlot!\nUse invite code: $cleanCode\nOr tap the link to join: $inviteLink'
        : 'Join my group on LockMySlot!\nUse invite code: $cleanCode\nOr tap the link to join: $inviteLink';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite copied to clipboard!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Shows the unified invite bottom sheet with options to copy the code, share deep link, or invite by username.
  static void showInviteSheet(
    BuildContext context, {
    required String groupName,
    required String inviteCode,
    String? groupId,
    InviteTab initialTab = InviteTab.share,
  }) {
    UnifiedInviteSheet.show(
      context,
      groupName: groupName,
      inviteCode: inviteCode,
      groupId: groupId,
      initialTab: initialTab,
    );
  }
}
