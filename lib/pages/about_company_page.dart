import 'package:flutter/material.dart';

import '../core/validators.dart';
import '../models/company_admin.dart';
import '../state/dashboard_controller.dart';
import '../theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class AboutCompanyPage extends StatefulWidget {
  const AboutCompanyPage({super.key, required this.controller});

  final DashboardController controller;

  @override
  State<AboutCompanyPage> createState() => _AboutCompanyPageState();
}

class _AboutCompanyPageState extends State<AboutCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyName;
  late final TextEditingController _brandWebsite;
  late final TextEditingController _brandLogoUrl;
  late final TextEditingController _brandBio;
  late final TextEditingController _adminName;
  late final TextEditingController _adminEmail;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final admin = widget.controller.admin;
    _companyName = TextEditingController(text: admin.companyName);
    _brandWebsite = TextEditingController(text: admin.brandWebsite);
    _brandLogoUrl = TextEditingController(text: admin.brandLogoUrl);
    _brandBio = TextEditingController(text: admin.brandBio);
    _adminName = TextEditingController(text: admin.name);
    _adminEmail = TextEditingController(text: admin.email);

    // Refresh UI on changes to update real-time preview card
    _companyName.addListener(_refresh);
    _brandWebsite.addListener(_refresh);
    _brandLogoUrl.addListener(_refresh);
    _brandBio.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _companyName.dispose();
    _brandWebsite.dispose();
    _brandLogoUrl.dispose();
    _brandBio.dispose();
    _adminName.dispose();
    _adminEmail.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final updated = CompanyAdmin(
      id: widget.controller.admin.id,
      name: _adminName.text.trim(),
      email: _adminEmail.text.trim(),
      companyName: _companyName.text.trim(),
      brandBio: _brandBio.text.trim(),
      brandWebsite: _brandWebsite.text.trim(),
      brandLogoUrl: _brandLogoUrl.text.trim(),
    );

    final ok = await widget.controller.updateProfile(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    AppToast.show(
      context,
      ok ? 'Company profile saved successfully!' : 'Could not save profile.',
      kind: ok ? ToastKind.success : ToastKind.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'About Company',
          subtitle: 'Configure your company identity, website, and bio distributed to all campaigns.',
        ),
        const SizedBox(height: 22),
        Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              final formContent = Column(
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Brand Identity', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _companyName,
                          decoration: const InputDecoration(
                            labelText: 'Company / Brand Name',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _brandWebsite,
                          decoration: const InputDecoration(
                            labelText: 'Brand Website URL',
                            hintText: 'https://yourbrand.com',
                            prefixIcon: Icon(Icons.language_outlined),
                          ),
                          keyboardType: TextInputType.url,
                          validator: optionalUrlError,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _brandLogoUrl,
                          decoration: const InputDecoration(
                            labelText: 'Brand Logo URL',
                            hintText: 'https://…/logo.png',
                            prefixIcon: Icon(Icons.image_outlined),
                          ),
                          keyboardType: TextInputType.url,
                          validator: optionalUrlError,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _brandBio,
                          decoration: const InputDecoration(
                            labelText: 'Brand Description / Bio',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Contacts', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _adminName,
                                decoration: const InputDecoration(
                                  labelText: 'Admin Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _adminEmail,
                                decoration: const InputDecoration(
                                  labelText: 'Admin Email',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: emailError,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final previewContent = SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Brand Preview Mockup', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.mintSoft,
                                backgroundImage: _brandLogoUrl.text.trim().isNotEmpty
                                    ? NetworkImage(_brandLogoUrl.text.trim())
                                    : null,
                                onBackgroundImageError:
                                    _brandLogoUrl.text.trim().isNotEmpty
                                        ? (_, __) {}
                                        : null,
                                child: _brandLogoUrl.text.trim().isEmpty
                                    ? Text(
                                        _companyName.text.isNotEmpty
                                            ? _companyName.text.substring(0, 1).toUpperCase()
                                            : 'B',
                                        style: const TextStyle(
                                          color: AppColors.mintDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _companyName.text.isNotEmpty ? _companyName.text : 'Brand Name',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _brandWebsite.text.isNotEmpty ? _brandWebsite.text : 'www.yourwebsite.com',
                                      style: const TextStyle(color: AppColors.mintDark, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppColors.line),
                          const SizedBox(height: 12),
                          Text(
                            _brandBio.text.isNotEmpty
                                ? _brandBio.text
                                : 'Describe your company bio here. This content is displayed directly to viewers inside their rewards feed so they can learn about your brand values and products.',
                            style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (wide) {
                return Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: formContent),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: previewContent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save Profile Details'),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  formContent,
                  const SizedBox(height: 18),
                  previewContent,
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Profile Details'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
