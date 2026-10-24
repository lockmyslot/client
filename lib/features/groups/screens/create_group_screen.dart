import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'create_group_sheet.dart';

export 'create_group_sheet.dart';

class CreateGroupScreen extends StatelessWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : Colors.black45,
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: CreateGroupSheet(
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
