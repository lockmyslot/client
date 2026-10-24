import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'create_group_sheet.dart';

export 'create_group_sheet.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final group = await CreateGroupSheet.show(context);
      if (mounted && group == null) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/groups');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
