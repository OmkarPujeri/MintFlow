/// Shared form-field validators so email/URL rules stay consistent across pages.

final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final RegExp _urlRe = RegExp(r'^https?://', caseSensitive: false);

/// Required email with a real format check (not just `contains('@')`).
String? emailError(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Required';
  if (!_emailRe.hasMatch(v)) return 'Enter a valid email';
  return null;
}

/// Optional URL: empty is allowed, but a value must start with http(s)://.
String? optionalUrlError(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null;
  if (!_urlRe.hasMatch(v)) return 'Start with http:// or https://';
  return null;
}
