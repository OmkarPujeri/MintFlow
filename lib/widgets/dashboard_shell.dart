import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/campaign.dart';
import '../models/company_admin.dart';
import '../pages/campaign_detail_page.dart';
import '../pages/campaigns_page.dart';
import '../pages/create_campaign_page.dart';
import '../pages/interactions_page.dart';
import '../pages/overview_page.dart';
import '../pages/responses_page.dart';
import '../pages/settings_page.dart';
import '../pages/spend_page.dart';
import '../pages/about_company_page.dart';
import '../state/dashboard_controller.dart';
import '../theme.dart';
import 'app_skeleton.dart';
import 'app_toast.dart';
import 'error_state.dart';

enum DashboardSection {
  overview,
  campaigns,
  create,
  aboutCompany,
  interactions,
  responses,
  spend,
  settings,
}

extension DashboardSectionMeta on DashboardSection {
  String get label => switch (this) {
        DashboardSection.overview => 'Overview',
        DashboardSection.campaigns => 'Campaigns',
        DashboardSection.create => 'Create Campaign',
        DashboardSection.aboutCompany => 'About Company',
        DashboardSection.interactions => 'Interactions',
        DashboardSection.responses => 'Responses',
        DashboardSection.spend => 'Spend',
        DashboardSection.settings => 'Settings',
      };

  IconData get icon => switch (this) {
        DashboardSection.overview => Icons.dashboard_outlined,
        DashboardSection.campaigns => Icons.campaign_outlined,
        DashboardSection.create => Icons.add_circle_outline,
        DashboardSection.aboutCompany => Icons.business_outlined,
        DashboardSection.interactions => Icons.fact_check_outlined,
        DashboardSection.responses => Icons.forum_outlined,
        DashboardSection.spend => Icons.account_balance_wallet_outlined,
        DashboardSection.settings => Icons.settings_outlined,
      };
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    required this.controller,
    required this.onLogout,
  });

  final DashboardController controller;
  final Future<void> Function() onLogout;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  DashboardSection _section = DashboardSection.overview;
  String? _viewingId;
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  DashboardController get controller => widget.controller;

  static const _railBreakpoint = 1120.0;
  static const _drawerBreakpoint = 760.0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goTo(DashboardSection section) {
    setState(() {
      _section = section;
      _viewingId = null;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _openCampaign(Campaign campaign) {
    setState(() => _viewingId = campaign.id);
  }

  Future<void> _createCampaign(Campaign campaign) async {
    final ok = await controller.createCampaign(campaign);
    if (!mounted) return;
    if (ok) {
      AppToast.show(context, 'Campaign "${campaign.name}" created');
      _goTo(DashboardSection.campaigns);
    } else {
      AppToast.show(
        context,
        'Could not create campaign. Please try again.',
        kind: ToastKind.danger,
      );
    }
  }

  Future<void> _editCampaign(Campaign campaign) async {
    final ok = await controller.updateCampaign(campaign);
    if (!mounted) return;
    if (ok) {
      AppToast.show(context, 'Campaign updated');
      _goTo(DashboardSection.campaigns);
    } else {
      AppToast.show(
        context,
        'Could not save changes. Please try again.',
        kind: ToastKind.danger,
      );
    }
  }

  Campaign? _editing;

  void _startEdit(Campaign campaign) {
    setState(() {
      _editing = campaign;
      _section = DashboardSection.create;
      _viewingId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final useDrawer = width < _drawerBreakpoint;
            final compactRail = !useDrawer && width < _railBreakpoint;

            return Scaffold(
              key: _scaffoldKey,
              drawer: useDrawer
                  ? Drawer(
                      backgroundColor: Colors.white,
                      child: SafeArea(
                        child: _Sidebar(
                          current: _section,
                          onSelect: _goTo,
                          onLogout: widget.onLogout,
                          compact: false,
                        ),
                      ),
                    )
                  : null,
              body: Row(
                children: [
                  if (!useDrawer)
                    _Sidebar(
                      current: _section,
                      onSelect: _goTo,
                      onLogout: widget.onLogout,
                      compact: compactRail,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        _Topbar(
                          admin: controller.admin,
                          searchController: _searchController,
                          onSearch: controller.setSearch,
                          onMenu: useDrawer
                              ? () => _scaffoldKey.currentState?.openDrawer()
                              : null,
                          onProfileTap: () => _goTo(DashboardSection.aboutCompany),
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: AppMotion.medium,
                            switchInCurve: AppMotion.curve,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.03),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: SingleChildScrollView(
                              key: ValueKey(
                                '${_section.name}-${_viewingId ?? ''}-${controller.isLoading}-${controller.hasError}',
                              ),
                              padding: EdgeInsets.all(useDrawer ? 18 : 28),
                              child: controller.isLoading
                                  ? const DashboardSkeleton()
                                  : controller.hasError
                                      ? ErrorState(
                                          message: controller.error!,
                                          onRetry: controller.retry,
                                        )
                                      : _viewingId != null
                                          ? CampaignDetailPage(
                                              controller: controller,
                                              campaignId: _viewingId!,
                                              onBack: () => setState(
                                                () => _viewingId = null,
                                              ),
                                              onEdit: _startEdit,
                                            )
                                          : _buildPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPage() {
    switch (_section) {
      case DashboardSection.overview:
        return OverviewPage(
          controller: controller,
          onCreate: () => _goTo(DashboardSection.create),
          onViewCampaigns: () => _goTo(DashboardSection.campaigns),
        );
      case DashboardSection.campaigns:
        return CampaignsPage(
          controller: controller,
          onCreate: () => _goTo(DashboardSection.create),
          onEdit: _startEdit,
          onOpen: _openCampaign,
        );
      case DashboardSection.create:
        return CreateCampaignPage(
          key: ValueKey(_editing?.id ?? 'new'),
          existing: _editing,
          controller: controller,
          onCreate: _createCampaign,
          onUpdate: _editCampaign,
          onCancel: _editing != null
              ? () {
                  setState(() => _editing = null);
                  _goTo(DashboardSection.campaigns);
                }
              : null,
        );
      case DashboardSection.aboutCompany:
        return AboutCompanyPage(controller: controller);
      case DashboardSection.interactions:
        return InteractionsPage(campaigns: controller.campaigns);
      case DashboardSection.responses:
        return ResponsesPage(controller: controller);
      case DashboardSection.spend:
        return SpendPage(controller: controller);
      case DashboardSection.settings:
        return SettingsPage(controller: controller);
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.current,
    required this.onSelect,
    required this.onLogout,
    required this.compact,
  });

  final DashboardSection current;
  final ValueChanged<DashboardSection> onSelect;
  final Future<void> Function() onLogout;
  final bool compact;

  static const _mainSections = [
    DashboardSection.overview,
    DashboardSection.campaigns,
    DashboardSection.create,
    DashboardSection.aboutCompany,
    DashboardSection.interactions,
    DashboardSection.responses,
    DashboardSection.spend,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.curve,
      width: compact ? 78 : 248,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18, vertical: 20),
      child: Column(
        crossAxisAlignment:
            compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          _Logo(
            compact: compact,
            onTap: () => onSelect(DashboardSection.overview),
          ),
          SizedBox(height: compact ? 26 : 30),
          for (final section in _mainSections)
            _NavItem(
              section: section,
              selected: current == section,
              compact: compact,
              onSelect: onSelect,
            ),
          const Spacer(),
          const Divider(height: 20),
          _NavItem(
            section: DashboardSection.settings,
            selected: current == DashboardSection.settings,
            compact: compact,
            onSelect: onSelect,
          ),
          _LogoutItem(compact: compact, onLogout: onLogout),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: 42,
      height: 42,
      child: SvgPicture.asset(
        'assets/brand_logo.svg',
      ),
    );
    final Widget child;
    if (compact) {
      child = mark;
    } else {
      child = Row(
        children: [
          mark,
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MintFlow',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              Text(
                'Company admin',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.section,
    required this.selected,
    required this.compact,
    required this.onSelect,
  });

  final DashboardSection section;
  final bool selected;
  final bool compact;
  final ValueChanged<DashboardSection> onSelect;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final active = selected || _hovered;
    final color = selected
        ? AppColors.mintDark
        : (_hovered ? AppColors.ink : AppColors.muted);

    final content = Row(
      mainAxisAlignment:
          widget.compact ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Icon(widget.section.icon, size: 21, color: color),
        if (!widget.compact) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.section.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.compact ? widget.section.label : '',
        child: GestureDetector(
          onTap: () => widget.onSelect(widget.section),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            margin: const EdgeInsets.only(bottom: 6),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 0 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.mintSoft
                  : (active ? AppColors.lineSoft : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _LogoutItem extends StatelessWidget {
  const _LogoutItem({required this.compact, required this.onLogout});

  final bool compact;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onLogout,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 0 : 12,
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment:
                compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              const Icon(Icons.logout, size: 20, color: AppColors.muted),
              if (!compact) ...[
                const SizedBox(width: 12),
                const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Topbar extends StatelessWidget {
  const _Topbar({
    required this.admin,
    required this.searchController,
    required this.onSearch,
    required this.onMenu,
    required this.onProfileTap,
  });

  final CompanyAdmin admin;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback? onMenu;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showName = constraints.maxWidth > 560;
          return Row(
            children: [
              if (onMenu != null) ...[
                IconButton(
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu, color: AppColors.ink),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearch,
                      decoration: InputDecoration(
                        hintText: 'Search campaigns...',
                        hintStyle: const TextStyle(color: AppColors.faint),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.faint,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        constraints: const BoxConstraints(maxHeight: 46),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none,
                  color: AppColors.muted,
                ),
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onProfileTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: AppColors.mintSoft,
                        backgroundImage: admin.brandLogoUrl.isNotEmpty
                            ? NetworkImage(admin.brandLogoUrl)
                            : null,
                        child: admin.brandLogoUrl.isEmpty
                            ? Text(
                                admin.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.mintDark,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      ),
                      if (showName) ...[
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              admin.name,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              admin.companyName,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
