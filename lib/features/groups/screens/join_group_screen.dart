import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/groups_repository.dart';
import '../providers/groups_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/widgets/loading_overlay.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  final String? initialCode;

  const JoinGroupScreen({super.key, this.initialCode});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  late final TextEditingController _codeController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.initialCode?.trim().toUpperCase() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant JoinGroupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCode != oldWidget.initialCode &&
        widget.initialCode != null) {
      _codeController.text = widget.initialCode!.trim().toUpperCase();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty || code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-character invite code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(groupsRepositoryProvider);
      final group = await repo.joinGroup(code);
      ref.invalidate(myGroupsProvider);

      if (mounted) {
        context.go('/groups/${group.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Group'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () => context.pop(),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Entrance(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Join a Group').h3(),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter the 6-character invite code provided by your group admin.',
                      ).muted().small(),
                      const SizedBox(height: 24),
                      const Text('Invite Code').small().semiBold(),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'e.g., AB12CD',
                        ),
                        maxLength: 6,
                        onSubmitted: (_) => _handleJoin(),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ).small(),
                      ],
                      const SizedBox(height: 24),
                      PrimaryButton(
                        onPressed: _handleJoin,
                        child: const Text('Join Group'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
