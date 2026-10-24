import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'join_group_sheet.dart';

export 'join_group_sheet.dart';

class JoinGroupScreen extends StatelessWidget {
  final String? initialCode;

  const JoinGroupScreen({super.key, this.initialCode});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : Colors.black45,
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: JoinGroupSheet(
            initialCode: initialCode,
            onSuccess: (group) {
              if (context.canPop()) {
                context.pop();
              }
              context.go('/groups/${group.id}');
            },
            onClose: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/groups');
              }
            },
          ),
        ),
      ),
    );
  }
}
