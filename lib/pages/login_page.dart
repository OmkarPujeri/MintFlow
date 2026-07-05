import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../repositories/api_client.dart';
import '../theme.dart';
import '../widgets/section_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onLogin,
    required this.onGoogleLogin,
  });

  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function() onGoogleLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Turn a raw error into a clear, production-style message.
  String _friendlyAuthError(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'No account found with those credentials. '
            'Check your email and password, or register first.';
      }
      if (error.statusCode == 429) {
        return 'Too many attempts. Please wait a minute and try again.';
      }
      if (error.statusCode >= 500) {
        return 'Server error. Please try again in a moment.';
      }
    }
    return 'Could not sign in. Check your connection and try again.';
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Enter your email and password to continue.');
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.onLogin(email, password);
    } catch (error) {
      _showError(_friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    try {
      await widget.onGoogleLogin();
    } catch (error) {
      _showError(_friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 920;
          return Container(
            padding: EdgeInsets.all(compact ? 24 : 44),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7FBF8), Color(0xFFE6F5EC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: compact
                    ? ListView(
                        shrinkWrap: true,
                        children: [
                          const _HeroPanel(compact: true),
                          const SizedBox(height: 26),
                          _LoginCard(
                            emailController: _emailController,
                            passwordController: _passwordController,
                            loading: _loading,
                            googleLoading: _googleLoading,
                            onSubmit: _submit,
                            onGoogle: _google,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Expanded(
                            child: SingleChildScrollView(
                              child: _HeroPanel(),
                            ),
                          ),
                          const SizedBox(width: 40),
                          SizedBox(
                            width: 420,
                            child: _LoginCard(
                              emailController: _emailController,
                              passwordController: _passwordController,
                              loading: _loading,
                              googleLoading: _googleLoading,
                              onSubmit: _submit,
                              onGoogle: _google,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: SvgPicture.asset(
                'assets/brand_logo.svg',
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'MintFlow',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).moveX(begin: -16, end: 0),
        const SizedBox(height: 44),
        Text(
          'Run verified attention campaigns from one clean dashboard.',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: compact ? 34 : 50,
                height: 1.08,
              ),
        ).animate().fadeIn(delay: 120.ms, duration: 500.ms).moveY(
              begin: 18,
              end: 0,
              curve: AppMotion.curve,
            ),
        const SizedBox(height: 18),
        const Text(
          'Create campaigns, attach quizzes, surveys, polls, and feedback tasks, then track completion, spend, and response quality before the mobile app goes live.',
          style: TextStyle(color: AppColors.muted, fontSize: 16.5, height: 1.55),
        ).animate().fadeIn(delay: 240.ms, duration: 500.ms),
        const SizedBox(height: 30),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var i = 0; i < _stats.length; i++)
              _HeroStat(label: _stats[i].$1, value: _stats[i].$2)
                  .animate()
                  .fadeIn(delay: (340 + i * 110).ms, duration: 450.ms)
                  .moveY(begin: 14, end: 0, curve: AppMotion.curve),
          ],
        ),
      ],
    );
  }

  static const _stats = [
    ('Verified completions', '1,248'),
    ('Avg. completion', '78%'),
    ('Campaign spend', 'Rs. 2.4k'),
  ];
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SizedBox(
        width: 168,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The official multi-colour Google "G" mark.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/google_logo.svg',
      width: 18,
      height: 18,
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.loading,
    required this.googleLoading,
    required this.onSubmit,
    required this.onGoogle,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool loading;
  final bool googleLoading;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Company Admin Login',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in with your account to continue.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'demo@mintflow.com',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            onSubmitted: (_) => loading ? null : onSubmit(),
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'demo1234',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onSubmit,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login),
              label: const Text('Open Dashboard'),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: Divider(color: AppColors.line)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: TextStyle(color: AppColors.faint, fontSize: 12.5),
                ),
              ),
              Expanded(child: Divider(color: AppColors.line)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: googleLoading ? null : onGoogle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: AppColors.line),
                foregroundColor: AppColors.ink,
              ),
              icon: googleLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const _GoogleGlyph(),
              label: const Text('Continue with Google'),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Demo account:  demo@mintflow.com  •  demo1234',
              style: TextStyle(color: AppColors.faint, fontSize: 12.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).moveY(
          begin: 24,
          end: 0,
          curve: AppMotion.curve,
        );
  }
}
