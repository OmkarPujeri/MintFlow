import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';

/// Native Google Sign-In (Android/iOS). Same prop contract as the web widget:
/// once the user authenticates, hands the Google ID token to [onIdToken] to
/// exchange for an app JWT at the backend.
///
/// Uses `serverClientId` = the backend's WEB OAuth client id (via
/// --dart-define=GOOGLE_CLIENT_ID) so the returned idToken's `aud` matches what
/// the backend verifies. Empty client id → a disabled hint.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key, required this.onIdToken, this.enabled = true});

  final Future<void> Function(String idToken) onIdToken;
  final bool enabled;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  GoogleSignIn? _googleSignIn;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (AppConfig.googleClientId.isEmpty) return;
    _googleSignIn = GoogleSignIn(
      serverClientId: AppConfig.googleClientId,
      scopes: const ['email', 'profile'],
    );
  }

  Future<void> _signIn() async {
    final gsi = _googleSignIn;
    if (gsi == null || _busy) return;
    setState(() => _busy = true);
    try {
      final account = await gsi.signIn();
      if (account == null) return; // user cancelled
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        _toast('Google did not return an ID token.');
        return;
      }
      await widget.onIdToken(idToken);
    } catch (_) {
      _toast('Google sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_googleSignIn == null) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.g_mobiledata),
        label: const Text('Google Sign-In not configured'),
      );
    }
    return OutlinedButton.icon(
      onPressed: widget.enabled && !_busy ? _signIn : null,
      icon: _busy
          ? const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.g_mobiledata, size: 26),
      label: const Text('Continue with Google'),
    );
  }
}
