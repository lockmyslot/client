import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/widgets/loading_overlay.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your display name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).register(name);
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
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Entrance(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Entrance(
                          delay: const Duration(milliseconds: 80),
                          curve: Curves.elasticOut,
                          child: const Icon(
                            Icons.lock_clock_outlined,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Entrance(
                          delay: const Duration(milliseconds: 140),
                          child: const Text(
                            'Welcome to Lock My Slot',
                            textAlign: TextAlign.center,
                          ).h2(),
                        ),
                        const SizedBox(height: 8),
                        Entrance(
                          delay: const Duration(milliseconds: 200),
                          child: const Text(
                            'Multi-tenant resource booking simplified.',
                            textAlign: TextAlign.center,
                          ).muted().small(),
                        ),
                        const SizedBox(height: 32),
                        Entrance(
                          delay: const Duration(milliseconds: 260),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'What should we call you?',
                              ).small().semiBold(),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Enter your display name',
                                ),
                                onSubmitted: (_) => _handleRegister(),
                              ),
                            ],
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          SlideFadeSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _errorMessage!,
                              key: const ValueKey('register-error'),
                              style: const TextStyle(color: Colors.red),
                            ).small(),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Entrance(
                          delay: const Duration(milliseconds: 340),
                          child: PrimaryButton(
                            onPressed: _handleRegister,
                            child: const Text('Get Started'),
                          ),
                        ),
                      ],
                    ),
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
