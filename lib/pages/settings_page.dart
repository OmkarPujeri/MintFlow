import 'package:flutter/material.dart';

import '../core/validators.dart';
import '../models/company_admin.dart';
import '../state/dashboard_controller.dart';
import '../theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final DashboardController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _company;
  late final TextEditingController _name;
  late final TextEditingController _email;
  bool _notify = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final admin = widget.controller.admin;
    _company = TextEditingController(text: admin.companyName);
    _name = TextEditingController(text: admin.name);
    _email = TextEditingController(text: admin.email);
  }

  @override
  void dispose() {
    _company.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final updated = CompanyAdmin(
      id: widget.controller.admin.id,
      name: _name.text.trim(),
      email: _email.text.trim(),
      companyName: _company.text.trim(),
    );
    final ok = await widget.controller.updateProfile(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    AppToast.show(
      context,
      ok ? 'Settings saved' : 'Could not save settings. Please try again.',
      kind: ok ? ToastKind.success : ToastKind.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Settings',
          subtitle: 'Company profile and dashboard preferences.',
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company Profile',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _company,
                        decoration: const InputDecoration(
                          labelText: 'Company name',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Admin name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Admin email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: emailError,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferences',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _notify,
                        activeThumbColor: AppColors.mint,
                        onChanged: (value) => setState(() => _notify = value),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Notify me when campaigns cross 80% budget spend',
                        ),
                        subtitle: const Text(
                          'Get alerted before a campaign exhausts its budget.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

}
