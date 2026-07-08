import 'package:flutter/material.dart';

import '../state/viewer_controller.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/mint_coin.dart';

/// Login + register (toggle) for viewers. On success the root shell rebuilds
/// via the controller — this page doesn't navigate itself.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.controller});

  final ViewerController controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final email = _email.text;
    final password = _password.text;
    final ok = _isRegister
        ? await widget.controller.register(email, password)
        : await widget.controller.login(email, password);
    if (!ok && mounted) {
      final msg = widget.controller.error ?? 'Something went wrong.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ambient mint glow behind the brand mark
          Positioned(
            top: -140,
            left: 0,
            right: 0,
            child: Container(
              height: 320,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x3346E39B), Color(0x0046E39B)],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final busy = widget.controller.isBusy;
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Logo(),
                        const SizedBox(height: 28),
                        Text(
                          _isRegister ? 'Create your account' : 'Welcome back',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Watch. Complete tasks. Earn Mint Coins.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Enter your email';
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            helperText: _isRegister
                                ? '8+ characters, with a letter and a number'
                                : null,
                          ),
                          validator: (v) {
                            final value = v ?? '';
                            if (value.isEmpty) return 'Enter your password';
                            if (_isRegister && value.length < 8) {
                              return 'At least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: busy ? null : _submit,
                          child: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_isRegister ? 'Create account' : 'Log in'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GoogleSignInButton(
                          enabled: !busy,
                          onIdToken: (idToken) async {
                            final messenger = ScaffoldMessenger.of(context);
                            final ok =
                                await widget.controller.loginWithGoogle(idToken);
                            if (!ok) {
                              final msg = widget.controller.error ??
                                  'Google sign-in failed.';
                              messenger.showSnackBar(
                                  SnackBar(content: Text(msg)));
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => setState(() => _isRegister = !_isRegister),
                          child: Text(_isRegister
                              ? 'Already have an account? Log in'
                              : "New here? Create an account"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: MintCoin(size: 76));
  }
}
