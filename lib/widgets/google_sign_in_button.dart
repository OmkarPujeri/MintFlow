import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
// web_only exposes the top-level renderButton() that draws Google's official,
// branding-compliant button. This file is only ever compiled for the web.
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

import '../config/app_config.dart';

/// Renders Google's official Sign-In button (via Google Identity Services) and,
/// once the user authenticates, hands the resulting Google ID token to
/// [onIdToken] so it can be exchanged for an app JWT at the backend.
///
/// Requires [AppConfig.googleClientId] to be set (via --dart-define). When it
/// is empty, a disabled hint is shown instead so the UI still makes sense.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key, required this.onIdToken});

  final Future<void> Function(String idToken) onIdToken;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  GoogleSignIn? _googleSignIn;

  @override
  void initState() {
    super.initState();
    if (AppConfig.googleClientId.isEmpty) return;

    _googleSignIn = GoogleSignIn(
      clientId: AppConfig.googleClientId,
      scopes: const ['email', 'profile'],
    );
    _googleSignIn!.onCurrentUserChanged.listen(_handleUser);
    // Attempt to restore an existing session without prompting.
    _googleSignIn!.signInSilently();
  }

  Future<void> _handleUser(GoogleSignInAccount? account) async {
    if (account == null) return;
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) return;
    await widget.onIdToken(idToken);
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.googleClientId.isEmpty) {
      return const _NotConfiguredHint();
    }
    // Google's own rendered button — required by GIS on the web.
    return gsi_web.renderButton();
  }
}

class _NotConfiguredHint extends StatelessWidget {
  const _NotConfiguredHint();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.g_mobiledata),
      label: const Text('Google Sign-In not configured'),
    );
  }
}
