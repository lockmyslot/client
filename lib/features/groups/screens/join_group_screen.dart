import 'package:flutter/services.dart' show TextCapitalization;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../data/groups_repository.dart';
import '../providers/groups_provider.dart';
import '../../../shared/widgets/loading_overlay.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

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
      headers: [
        AppBar(
          title: const Text('Join Group'),
          leading: [
            IconButton.ghost(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ],
      child: LoadingOverlay(
        isLoading: _isLoading,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Join a Group').h3(),
                    const SizedBox(height: 8),
                    const Text('Enter the 6-character invite code provided by your group admin.')
                        .muted()
                        .small(),
                    const SizedBox(height: 24),
                    const Text('Invite Code').small().semiBold(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      placeholder: const Text('e.g., AB12CD'),
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
    );
  }
}
