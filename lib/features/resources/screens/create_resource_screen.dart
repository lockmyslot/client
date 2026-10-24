import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'create_resource_sheet.dart';

export 'create_resource_sheet.dart';

class CreateResourceScreen extends StatefulWidget {
  final String groupId;

  const CreateResourceScreen({super.key, required this.groupId});

  @override
  State<CreateResourceScreen> createState() => _CreateResourceScreenState();
}

class _CreateResourceScreenState extends State<CreateResourceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final res =
          await CreateResourceSheet.show(context, groupId: widget.groupId);
      if (mounted && res == null) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/groups/${widget.groupId}');
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
