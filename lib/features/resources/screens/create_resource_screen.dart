import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'create_resource_sheet.dart';

export 'create_resource_sheet.dart';

class CreateResourceScreen extends StatelessWidget {
  final String groupId;

  const CreateResourceScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : Colors.black45,
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: CreateResourceSheet(
            groupId: groupId,
            onSuccess: (resource) {
              if (context.canPop()) {
                context.pop();
              }
              context.go('/groups/$groupId/resources/${resource.id}');
            },
            onClose: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/groups/$groupId');
              }
            },
          ),
        ),
      ),
    );
  }
}
