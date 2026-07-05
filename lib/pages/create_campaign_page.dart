import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/constants.dart';
import '../formatters.dart';
import '../models/campaign.dart';
import '../state/dashboard_controller.dart';
import '../theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/youtube_player_widget.dart';

/// Editable draft for a single interaction (owns its text controllers).
class _InteractionDraft {
  _InteractionDraft({
    required this.type,
    String question = '',
    String options = 'Option A, Option B, Option C',
  })  : question = TextEditingController(text: question),
        options = TextEditingController(text: options);

  InteractionType type;
  final TextEditingController question;
  final TextEditingController options;

  void dispose() {
    question.dispose();
    options.dispose();
  }
}

/// Editable draft for a single slide.
class _SlideDraft {
  _SlideDraft({
    required this.type,
    String url = '',
  }) : urlController = TextEditingController(text: url) {
    urlController.addListener(() {
      duration = null;
    });
  }

  String type; // "video" | "image"
  final TextEditingController urlController;
  double? duration;

  void dispose() {
    urlController.dispose();
  }
}

class CreateCampaignPage extends StatefulWidget {
  const CreateCampaignPage({
    super.key,
    this.existing,
    required this.controller,
    required this.onCreate,
    required this.onUpdate,
    this.onCancel,
  });

  final Campaign? existing;
  final DashboardController controller;
  final Future<void> Function(Campaign campaign) onCreate;
  final Future<void> Function(Campaign campaign) onUpdate;
  final VoidCallback? onCancel;

  @override
  State<CreateCampaignPage> createState() => _CreateCampaignPageState();
}

class _CreateCampaignPageState extends State<CreateCampaignPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _youtubeUrl;
  late final TextEditingController _budget;
  late final TextEditingController _reward;
  late final TextEditingController _ctaUrl;
  late final TextEditingController _ctaButtonText;
  late String _targetGender;
  late final TextEditingController _targetAgeMin;
  late final TextEditingController _targetAgeMax;
  late final TextEditingController _targetLocations;
  late final TextEditingController _targetInterests;
  final List<_InteractionDraft> _interactions = [];
  late DateTime _startDate;
  late DateTime _endDate;
  late CampaignStatus _status;
  bool _saving = false;
  final List<_SlideDraft> _slides = [];

  void _addSlide(String type, {String url = ''}) {
    if (_slides.length >= 5) {
      AppToast.show(context, 'Maximum 5 slides allowed', kind: ToastKind.danger);
      return;
    }
    final slide = _SlideDraft(type: type, url: url);
    slide.urlController.addListener(_refresh);
    setState(() {
      _slides.add(slide);
    });
  }

  void _removeSlide(int index) {
    if (_slides.length <= 1) {
      AppToast.show(context, 'Campaign must have at least 1 slide', kind: ToastKind.danger);
      return;
    }
    setState(() {
      final removed = _slides.removeAt(index);
      removed.dispose();
    });
  }

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _youtubeUrl = TextEditingController(text: existing?.youtubeUrl ?? '');
    _budget = TextEditingController(
      text: existing?.budget.toStringAsFixed(0) ?? '1000',
    );
    _reward = TextEditingController(
      text: existing?.rewardPerCompletion.toStringAsFixed(0) ?? '2',
    );
    _ctaUrl = TextEditingController(text: existing?.ctaUrl ?? '');
    _ctaButtonText = TextEditingController(text: existing?.ctaButtonText ?? 'Learn More');
    _targetGender = existing?.targetGender ?? 'all';
    _targetAgeMin = TextEditingController(
      text: existing?.targetAgeMin?.toString() ?? '18',
    );
    _targetAgeMax = TextEditingController(
      text: existing?.targetAgeMax?.toString() ?? '65',
    );
    _targetLocations = TextEditingController(
      text: existing?.targetLocations.join(', ') ?? '',
    );
    _targetInterests = TextEditingController(
      text: existing?.targetInterests.join(', ') ?? '',
    );


    if (existing != null && existing.interactions.isNotEmpty) {
      for (final it in existing.interactions) {
        _interactions.add(
          _InteractionDraft(
            type: it.type,
            question: it.question,
            options: it.options.join(', '),
          ),
        );
      }
    } else {
      _interactions.add(_InteractionDraft(type: InteractionType.quiz));
    }

    if (existing != null && existing.slides.isNotEmpty) {
      for (final s in existing.slides) {
        final draft = _SlideDraft(type: s.type, url: s.url);
        draft.urlController.addListener(_refresh);
        _slides.add(draft);
      }
    } else {
      final draft = _SlideDraft(type: 'video', url: existing?.youtubeUrl ?? '');
      draft.urlController.addListener(_refresh);
      _slides.add(draft);
    }

    final now = DateTime.now();
    _startDate = existing?.startDate ?? now;
    _endDate = existing?.endDate ?? now.add(const Duration(days: 21));
    _status = existing != null && existing.status == CampaignStatus.draft
        ? CampaignStatus.draft
        : CampaignStatus.active;

    _name.addListener(_refresh);
    _reward.addListener(_refresh);
    _ctaUrl.addListener(_refresh);
    _ctaButtonText.addListener(_refresh);
    _targetLocations.addListener(_refresh);
    _targetInterests.addListener(_refresh);
    _budget.addListener(_refresh);
    _reward.addListener(_refresh);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _youtubeUrl.dispose();

    for (final s in _slides) {
      s.dispose();
    }
    _budget.dispose();
    _reward.dispose();
    _ctaUrl.dispose();
    _ctaButtonText.dispose();
    _targetAgeMin.dispose();
    _targetAgeMax.dispose();
    _targetLocations.dispose();
    _targetInterests.dispose();
    for (final it in _interactions) {
      it.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _addInteraction() {
    setState(() {
      _interactions.add(_InteractionDraft(type: InteractionType.survey));
    });
  }

  void _removeInteraction(int index) {
    setState(() {
      _interactions.removeAt(index).dispose();
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      } else {
        _endDate = picked.isBefore(_startDate)
            ? _startDate.add(const Duration(days: 1))
            : picked;
      }
    });
  }

  List<CampaignInteraction> _buildInteractions() {
    return _interactions.map((draft) {
      final options = draft.type == InteractionType.feedback
          ? <String>[]
          : draft.options.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
      return CampaignInteraction(
        type: draft.type,
        question: draft.question.text.trim(),
        options: options,
        correctAnswer:
            draft.type == InteractionType.quiz && options.isNotEmpty
                ? options.first
                : null,
      );
    }).toList();
  }

  Future<void> _submit() async {
    for (var i = 0; i < _slides.length; i++) {
      final s = _slides[i];
      if (s.type == 'video' && s.duration != null && s.duration! > 180) {
        AppToast.show(
          context,
          'Cannot publish campaign: Slide #${i + 1} video exceeds 3 minutes limit.',
          kind: ToastKind.danger,
        );
        return;
      }
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final interactions = _buildInteractions();
    final slides = _slides.map((s) {
      final url = s.urlController.text.trim();
      final videoId = s.type == 'video' ? extractYouTubeVideoId(url) : null;
      return CampaignSlide(
        type: s.type,
        url: url,
        videoId: videoId,
      );
    }).toList();

    final firstVideo = slides.cast<CampaignSlide?>().firstWhere(
      (s) => s?.type == 'video',
      orElse: () => null,
    );
    final youtubeUrlVal = firstVideo?.url ?? '';
    final youtubeVideoIdVal = firstVideo?.videoId ?? '';

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        name: _name.text.trim(),
        description: _description.text.trim(),
        youtubeUrl: youtubeUrlVal,
        youtubeVideoId: youtubeVideoIdVal,
        slides: slides,
        budget: double.parse(_budget.text),
        rewardPerCompletion: double.parse(_reward.text),
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
        interactions: interactions,
        ctaUrl: _ctaUrl.text.trim().isEmpty ? null : _ctaUrl.text.trim(),
        ctaButtonText: _ctaButtonText.text.trim(),
        targetGender: _targetGender,
        targetAgeMin: int.tryParse(_targetAgeMin.text),
        targetAgeMax: int.tryParse(_targetAgeMax.text),
        targetLocations: _targetLocations.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        targetInterests: _targetInterests.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        brandBio: widget.controller.admin.brandBio,
        brandWebsite: widget.controller.admin.brandWebsite,
        brandLogoUrl: widget.controller.admin.brandLogoUrl,
      );
      await widget.onUpdate(updated);
    } else {
      final now = DateTime.now();
      final campaign = Campaign(
        id: 'campaign-${now.microsecondsSinceEpoch}',
        name: _name.text.trim(),
        description: _description.text.trim(),
        youtubeUrl: youtubeUrlVal,
        youtubeVideoId: youtubeVideoIdVal,
        slides: slides,
        budget: double.parse(_budget.text),
        rewardPerCompletion: double.parse(_reward.text),
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
        interactions: interactions,
        views: 0,
        completions: 0,
        createdAt: now,
        ctaUrl: _ctaUrl.text.trim().isEmpty ? null : _ctaUrl.text.trim(),
        ctaButtonText: _ctaButtonText.text.trim(),
        targetGender: _targetGender,
        targetAgeMin: int.tryParse(_targetAgeMin.text),
        targetAgeMax: int.tryParse(_targetAgeMax.text),
        targetLocations: _targetLocations.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        targetInterests: _targetInterests.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        brandBio: widget.controller.admin.brandBio,
        brandWebsite: widget.controller.admin.brandWebsite,
        brandLogoUrl: widget.controller.admin.brandLogoUrl,
      );
      await widget.onCreate(campaign);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: _isEditing ? 'Edit Campaign' : 'Create Campaign',
          subtitle:
              'Paste a YouTube URL, define reward economics, schedule, and viewer tasks.',
          trailing: widget.onCancel != null
              ? OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                )
              : null,
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 860;
            final form = _buildForm(context);
            final preview = _MobilePreview(
              interaction: _interactions.first,
              name: _name,
              reward: _reward,
              slides: _slides,
              ctaUrl: _ctaUrl,
              ctaButtonText: _ctaButtonText,
              onDurationLoaded: (index, duration) {
                if (index < _slides.length) {
                  _slides[index].duration = duration;
                  if (duration > 180) {
                    AppToast.show(
                      context,
                      'Warning: Slide #${index + 1} video exceeds the 3 minutes limit!',
                      kind: ToastKind.danger,
                    );
                  }
                }
              },
            );
            if (!wide) {
              return Column(
                children: [form, const SizedBox(height: 18), preview],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form),
                const SizedBox(width: 18),
                SizedBox(width: 340, child: preview),
              ],
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: AppMotion.medium);
  }

  Widget _buildForm(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(26),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Campaign details'),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Campaign name',
                prefixIcon: Icon(Icons.campaign_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            const SizedBox(height: 14),
            const _SectionLabel('Campaign Slides / Media (Max 5)'),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _slides.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.panelAlt,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.mintSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Slide #${index + 1}',
                          style: const TextStyle(
                            color: AppColors.mintDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: slide.type,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'video', child: Text('Video (YT)')),
                          DropdownMenuItem(value: 'image', child: Text('Image URL')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              slide.type = val;
                            });
                            _refresh();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: slide.urlController,
                          decoration: InputDecoration(
                            labelText:
                                slide.type == 'video' ? 'YouTube URL' : 'Image URL',
                            hintText: slide.type == 'video'
                                ? 'Paste YouTube video URL'
                                : 'Paste direct image URL',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'URL is required';
                            }
                            if (slide.type == 'video') {
                              return _youtubeUrlValidator(val);
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_slides.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                          onPressed: () => _removeSlide(index),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _slides.length >= 5 ? null : () => _addSlide('video'),
                  icon: const Icon(Icons.add_to_queue_outlined),
                  label: const Text('Add Video Slide'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _slides.length >= 5 ? null : () => _addSlide('image'),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Add Image Slide'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Reward economics'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budget,
                    decoration: const InputDecoration(
                      labelText: 'Budget (Rs.)',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: _number,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _reward,
                    decoration: InputDecoration(
                      labelText: 'Reward / completion (Mint Coins 🪙)',
                      helperText:
                          '1 Coin = ${formatCurrency(MintEconomics.coinValueInr, decimals: 2)}',
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: _number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Builder(
              builder: (context) {
                final double budgetVal = double.tryParse(_budget.text) ?? 0.0;
                final double rewardVal = double.tryParse(_reward.text) ?? 0.0;

                final feePct = (MintEconomics.platformFeeRate * 100).round();
                final poolPct = (MintEconomics.viewerPoolRate * 100).round();
                final fee = budgetVal * MintEconomics.platformFeeRate;
                final pool = budgetVal * MintEconomics.viewerPoolRate;
                final totalCoins = pool / MintEconomics.coinValueInr;
                final estViews =
                    rewardVal > 0 ? (totalCoins / rewardVal).floor() : 0;
                final viewerEarns = rewardVal * MintEconomics.coinValueInr;
                // Effective advertiser cost per verified view (== budget / views).
                final cpv = rewardVal *
                    (MintEconomics.coinValueInr / MintEconomics.viewerPoolRate);
                final cpm = cpv * 1000;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF16A066),
                        Color(0xFF0D6844),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF13201A).withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calculate_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Live Budget Split Calculator',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 12),
                      _CalcRow('Budget', formatCurrency(budgetVal)),
                      _CalcRow('Platform fee ($feePct%)',
                          '- ${formatCurrency(fee)}'),
                      _CalcRow('Viewer payout pool ($poolPct%)',
                          formatCurrency(pool)),
                      const SizedBox(height: 10),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 10),
                      _CalcRow(
                        'Reward / view',
                        rewardVal > 0
                            ? '${formatCoins(rewardVal)}  (${formatCurrency(viewerEarns, decimals: 2)})'
                            : '—',
                      ),
                      _CalcRow('Est. verified views', '$estViews',
                          emphasize: true),
                      _CalcRow('Effective CPV',
                          rewardVal > 0 ? formatCurrency(cpv, decimals: 2) : '—'),
                      _CalcRow('Effective CPM',
                          rewardVal > 0 ? formatCurrency(cpm) : '—'),
                      _CalcRow('Viewer earns / view',
                          rewardVal > 0
                              ? formatCurrency(viewerEarns, decimals: 2)
                              : '—'),
                      const SizedBox(height: 10),
                      Text(
                        'CPV is your effective cost per verified view. Viewers are '
                        'paid from the $poolPct% pool at ${formatCurrency(MintEconomics.coinValueInr, decimals: 2)}/coin.',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Schedule'),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start date',
                    value: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _DateField(
                    label: 'End date',
                    value: _endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Viewer Targeting'),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _targetGender,
                    decoration: const InputDecoration(
                      labelText: 'Target Gender',
                      prefixIcon: Icon(Icons.people_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (value) => setState(() => _targetGender = value!),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _targetAgeMin,
                          decoration: const InputDecoration(labelText: 'Min Age'),
                          keyboardType: TextInputType.number,
                          validator: _age,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('-'),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _targetAgeMax,
                          decoration: const InputDecoration(labelText: 'Max Age'),
                          keyboardType: TextInputType.number,
                          validator: _maxAge,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _targetLocations,
              decoration: const InputDecoration(
                labelText: 'Target Locations (comma-separated)',
                helperText: 'Leave empty for nationwide targeting (e.g. Mumbai, Delhi, Bangalore).',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _targetInterests,
              decoration: const InputDecoration(
                labelText: 'Target Interests (comma-separated)',
                helperText: 'Target specific user interests (e.g. Gaming, Fashion, Tech).',
                prefixIcon: Icon(Icons.interests_outlined),
              ),
            ),

            const SizedBox(height: 24),
            const _SectionLabel('Call To Action (Redirect)'),
            TextFormField(
              controller: _ctaUrl,
              decoration: const InputDecoration(
                labelText: 'CTA Destination URL (optional)',
                helperText: 'Redirects viewers to your store/website upon completion.',
                prefixIcon: Icon(Icons.link_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _ctaButtonText,
              decoration: const InputDecoration(
                labelText: 'CTA Button Label',
                helperText: 'Label shown to the viewer (e.g., Shop Now, Learn More, Claim Code).',
                prefixIcon: Icon(Icons.touch_app_outlined),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: _SectionLabel('Viewer tasks')),
                TextButton.icon(
                  onPressed: _addInteraction,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add task'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < _interactions.length; i++)
              _InteractionEditor(
                key: ObjectKey(_interactions[i]),
                index: i,
                draft: _interactions[i],
                canRemove: _interactions.length > 1,
                onTypeChanged: (type) =>
                    setState(() => _interactions[i].type = type),
                onRemove: () => _removeInteraction(i),
                validateRequired: _required,
              ),
            const SizedBox(height: 8),
            SegmentedButton<CampaignStatus>(
              segments: const [
                ButtonSegment(
                  value: CampaignStatus.active,
                  label: Text('Publish'),
                  icon: Icon(Icons.public),
                ),
                ButtonSegment(
                  value: CampaignStatus.draft,
                  label: Text('Save Draft'),
                  icon: Icon(Icons.drafts_outlined),
                ),
              ],
              selected: {_status},
              onSelectionChanged: (value) =>
                  setState(() => _status = value.first),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isEditing
                            ? Icons.save_outlined
                            : Icons.rocket_launch_outlined,
                      ),
                label: Text(_isEditing ? 'Save Changes' : 'Create Campaign'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _number(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final number = double.tryParse(value);
    if (number == null || number <= 0) return 'Enter a positive number';
    return null;
  }

  String? _youtubeUrlValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (extractYouTubeVideoId(value) == null) {
      return 'Enter a valid YouTube video URL';
    }
    return null;
  }

  /// Whole number in [13, 100]. Used for both age bounds.
  String? _age(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = int.tryParse(value.trim());
    if (n == null) return 'Whole number only';
    if (n < 13 || n > 100) return '13–100';
    return null;
  }

  /// Max age: a valid age AND not below the min age.
  String? _maxAge(String? value) {
    final base = _age(value);
    if (base != null) return base;
    final min = int.tryParse(_targetAgeMin.text.trim());
    final max = int.tryParse(value!.trim());
    if (min != null && max != null && max < min) return 'Max < min';
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.faint,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// A label/value line inside the budget-split calculator card.
class _CalcRow extends StatelessWidget {
  const _CalcRow(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: emphasize ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(formatDate(value)),
      ),
    );
  }
}

class _InteractionEditor extends StatelessWidget {
  const _InteractionEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onTypeChanged,
    required this.onRemove,
    required this.validateRequired,
  });

  final int index;
  final _InteractionDraft draft;
  final bool canRemove;
  final ValueChanged<InteractionType> onTypeChanged;
  final VoidCallback onRemove;
  final String? Function(String?) validateRequired;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelAlt,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Task ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.danger,
                  ),
                  tooltip: 'Remove task',
                ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<InteractionType>(
            initialValue: draft.type,
            decoration: const InputDecoration(
              labelText: 'Interaction type',
              prefixIcon: Icon(Icons.fact_check_outlined),
            ),
            items: InteractionType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  ),
                )
                .toList(),
            onChanged: (value) => onTypeChanged(value!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: draft.question,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Question or feedback prompt',
              prefixIcon: Icon(Icons.help_outline),
            ),
            validator: validateRequired,
          ),
          if (draft.type != InteractionType.feedback) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: draft.options,
              decoration: InputDecoration(
                labelText: 'Options, comma separated',
                helperText: draft.type == InteractionType.quiz
                    ? 'The first option is treated as the correct answer.'
                    : null,
                prefixIcon: const Icon(Icons.list_alt_outlined),
              ),
              validator: validateRequired,
            ),
          ],
        ],
      ),
    );
  }
}

class _MobilePreview extends StatefulWidget {
  const _MobilePreview({
    required this.interaction,
    required this.name,
    required this.reward,
    required this.slides,
    required this.ctaUrl,
    required this.ctaButtonText,
    this.onDurationLoaded,
  });

  final _InteractionDraft interaction;
  final TextEditingController name;
  final TextEditingController reward;
  final List<_SlideDraft> slides;
  final TextEditingController ctaUrl;
  final TextEditingController ctaButtonText;
  final void Function(int index, double duration)? onDurationLoaded;

  @override
  State<_MobilePreview> createState() => _MobilePreviewState();
}

class _MobilePreviewState extends State<_MobilePreview> {
  double _position = 0.0;
  double _duration = 0.0;
  int _currentSlideIndex = 0;
  late Listenable _slidesListenable;

  bool get _showCTA {
    if (_duration <= 0) return false;
    return (_duration - _position) <= 3.0;
  }

  @override
  void initState() {
    super.initState();
    _initListenable();
  }

  @override
  void didUpdateWidget(covariant _MobilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initListenable();
  }

  void _initListenable() {
    _slidesListenable = Listenable.merge(
      widget.slides.map((s) => s.urlController).toList(),
    );
  }

  Widget _buildSlidePreview(BuildContext context, int index) {
    if (index >= widget.slides.length) return const SizedBox();
    final slide = widget.slides[index];
    final url = slide.urlController.text.trim();

    if (slide.type == 'video') {
      final videoId = extractYouTubeVideoId(url);
      if (videoId != null && videoId.isNotEmpty) {
        return YoutubePlayerWidget(
          videoId: videoId,
          aspectRatio: 16 / 9,
          onDurationLoaded: (dur) {
            widget.onDurationLoaded?.call(index, dur);
          },
          onTimeChanged: (pos, dur) {
            setState(() {
              _position = pos;
              _duration = dur;
            });
          },
        );
      }
      // Empty URL → neutral "add a video" prompt; a non-empty but unparseable
      // URL → an actual error hint.
      final isEmpty = url.isEmpty;
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEmpty
                  ? Icons.play_circle_outline
                  : Icons.error_outline,
              color: Colors.white54,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              isEmpty ? 'Add a video URL to preview' : 'Invalid YouTube link',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    } else {
      return url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, _, __) => Container(
                color: Colors.grey[900],
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 36),
              ),
            )
          : Container(
              color: const Color(0xFF1E2E28),
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, color: Colors.white54, size: 36),
                  SizedBox(height: 8),
                  Text('Empty Image Slide', style: TextStyle(color: Colors.white70)),
                ],
              ),
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showOnlyCTA = _showCTA && widget.ctaUrl.text.trim().isNotEmpty;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smartphone, size: 18, color: AppColors.mintDark),
              const SizedBox(width: 8),
              Text(
                'Viewer Preview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 520,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1713),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            padding: const EdgeInsets.all(11),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Expanded(
                      child: ListenableBuilder(
                        listenable: _slidesListenable,
                        builder: (context, _) {
                          if (widget.slides.isEmpty) {
                            return Container(
                              color: Colors.black,
                              alignment: Alignment.center,
                              child: const Text('No slides configured', style: TextStyle(color: Colors.white)),
                            );
                          }
                          return Stack(
                            children: [
                              PageView.builder(
                                itemCount: widget.slides.length,
                                onPageChanged: (idx) {
                                  setState(() {
                                    _currentSlideIndex = idx;
                                    _position = 0.0;
                                    _duration = 0.0;
                                  });
                                },
                                itemBuilder: (context, idx) => _buildSlidePreview(context, idx),
                              ),
                              if (widget.slides.length > 1) ...[
                                Positioned(
                                  bottom: 8,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      widget.slides.length,
                                      (idx) => Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 3),
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _currentSlideIndex == idx
                                              ? AppColors.mintDark
                                              : Colors.white54,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: showOnlyCTA
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_purple500_outlined,
                                  color: AppColors.amber,
                                  size: 32,
                                ).animate(onPlay: (controller) => controller.repeat())
                                 .shimmer(duration: const Duration(seconds: 2)),
                                const SizedBox(height: 8),
                                const Text(
                                  'Bonus Action Unlocked!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.mintDark,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.open_in_new),
                                    label: Text(
                                      widget.ctaButtonText.text.isEmpty
                                          ? 'Learn More'
                                          : widget.ctaButtonText.text,
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.mintDark,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListenableBuilder(
                                  listenable: widget.name,
                                  builder: (context, _) => Text(
                                    widget.name.text.isEmpty
                                        ? 'Campaign title'
                                        : widget.name.text,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListenableBuilder(
                                  listenable: widget.interaction.question,
                                  builder: (context, _) => Text(
                                    widget.interaction.question.text.isEmpty
                                        ? 'Viewer task question appears here.'
                                        : widget.interaction.question.text,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.mintSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.interaction.type.label,
                                    style: const TextStyle(
                                      color: AppColors.mintDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ListenableBuilder(
                                    listenable: widget.reward,
                                    builder: (context, _) => FilledButton(
                                      onPressed: () {},
                                      child: Text(
                                        'Complete & Earn ${widget.reward.text.isEmpty ? '2' : widget.reward.text} Coins',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
