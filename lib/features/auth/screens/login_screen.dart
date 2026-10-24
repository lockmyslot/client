import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/widgets/loading_overlay.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your username';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(authProvider.notifier).login(
            username: username,
            password: password,
          );

      if (!mounted) return;

      if (!success) {
        setState(() {
          _isLoading = false;
          _errorMessage = ref.read(authProvider).error ?? 'Login failed';
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        final returnTo =
            GoRouterState.of(context).uri.queryParameters['returnTo'];
        if (returnTo != null && returnTo.isNotEmpty) {
          final decoded = Uri.decodeComponent(returnTo);
          if (decoded.startsWith('/') &&
              !decoded.startsWith('/login') &&
              !decoded.startsWith('/register')) {
            context.go(decoded);
            return;
          }
        }
        context.go('/groups');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _fillCredentials(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Entrance(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Entrance(
                      delay: const Duration(milliseconds: 80),
                      curve: Curves.elasticOut,
                      child: Icon(
                        Icons.lock_clock_outlined,
                        size: 52,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Entrance(
                      delay: const Duration(milliseconds: 140),
                      child: Text.rich(
                        TextSpan(
                          text: 'Welcome back to\n',
                          children: [
                            TextSpan(
                              text: 'LockMySlot',
                              style: TextStyle(
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Entrance(
                      delay: const Duration(milliseconds: 200),
                      child: const Text(
                        'Sign in to manage your bookings and resources',
                        textAlign: TextAlign.center,
                      ).muted().small(),
                    ),
                    const SizedBox(height: 32),

                    // Username field
                    Entrance(
                      delay: const Duration(milliseconds: 240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Username').small().semiBold(),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameController,
                            autofocus: true,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Enter your username',
                              prefixIcon: Icon(
                                Icons.alternate_email_outlined,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    Entrance(
                      delay: const Duration(milliseconds: 280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Password').small().semiBold(),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      SlideFadeSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Container(
                          key: ValueKey(_errorMessage),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 18,
                                color: colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: colorScheme.onErrorContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Login Button
                    Entrance(
                      delay: const Duration(milliseconds: 320),
                      child: PrimaryButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quick fill helper
                    Entrance(
                      delay: const Duration(milliseconds: 360),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demo Accounts (tap to autofill):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.person_pin,
                                    size: 16,
                                  ),
                                  label: const Text('Alice (admin)'),
                                  onPressed: () => _fillCredentials(
                                    'alice',
                                    'password123',
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.person_outline,
                                    size: 16,
                                  ),
                                  label: const Text('Bob (member)'),
                                  onPressed: () => _fillCredentials(
                                    'bob',
                                    'password123',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Switch to Register
                    Entrance(
                      delay: const Duration(milliseconds: 400),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?").small().muted(),
                          TextButton(
                            onPressed: () {
                              final returnTo = GoRouterState.of(context)
                                  .uri
                                  .queryParameters['returnTo'];
                              if (returnTo != null && returnTo.isNotEmpty) {
                                context.go(
                                  '/register?returnTo=${Uri.encodeComponent(returnTo)}',
                                );
                              } else {
                                context.go('/register');
                              }
                            },
                            child: const Text('Register').small().semiBold(),
                          ),
                        ],
                      ),
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
