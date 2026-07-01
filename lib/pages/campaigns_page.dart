import 'package:flutter/material.dart';

import '../formatters.dart';
import '../models/campaign.dart';
import '../state/dashboard_controller.dart';
import '../theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class CampaignsPage extends StatefulWidget {
  const CampaignsPage({
    super.key,
    required this.controller,
    required this.onCreate,
    required this.onEdit,
    required this.onOpen,
  });

  final DashboardController controller;
  final VoidCallback onCreate;
  final ValueChanged<Campaign> onEdit;
  final ValueChanged<Campaign> onOpen;

  @override
  State<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends State<CampaignsPage> {
  static const _pageSize = 8;
  int _page = 0;

  DashboardController get controller => widget.controller;

  Future<void> _confirmDelete(BuildContext context, Campaign campaign) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete campaign?'),
        content: Text(
          '"${campaign.name}" and its data will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final done = await controller.deleteCampaign(campaign.id);
      if (context.mounted) {
        AppToast.show(
          context,
          done ? 'Campaign deleted' : 'Could not delete campaign.',
          kind: ToastKind.danger,
        );
      }
    }
  }

  Future<void> _run(
    BuildContext context,
    Future<bool> Function() action,
    String success,
  ) async {
    final ok = await action();
    if (!context.mounted) return;
    AppToast.show(
      context,
      ok ? success : 'Action failed. Please try again.',
      kind: ok ? ToastKind.success : ToastKind.danger,
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    Campaign campaign,
    _CampaignAction action,
  ) async {
    switch (action) {
      case _CampaignAction.open:
        widget.onOpen(campaign);
      case _CampaignAction.edit:
        widget.onEdit(campaign);
      case _CampaignAction.pause:
        await _run(
          context,
          () => controller.updateStatus(campaign.id, CampaignStatus.paused),
          'Campaign paused',
        );
      case _CampaignAction.resume:
        await _run(
          context,
          () => controller.updateStatus(campaign.id, CampaignStatus.active),
          'Campaign resumed',
        );
      case _CampaignAction.complete:
        await _run(
          context,
          () => controller.updateStatus(campaign.id, CampaignStatus.completed),
          'Campaign completed',
        );
      case _CampaignAction.duplicate:
        await _run(
          context,
          () => controller.duplicateCampaign(campaign.id),
          'Campaign duplicated',
        );
      case _CampaignAction.delete:
        await _confirmDelete(context, campaign);
    }
  }

  int? _sortColumnIndex() => switch (controller.sort) {
        CampaignSort.name => 0,
        CampaignSort.budget => 2,
        CampaignSort.completion => 5,
        CampaignSort.newest => null,
      };

  void _onSort(int columnIndex, bool ascending) {
    final sort = switch (columnIndex) {
      0 => CampaignSort.name,
      2 => CampaignSort.budget,
      5 => CampaignSort.completion,
      _ => CampaignSort.newest,
    };
    setState(() => _page = 0);
    controller.setSort(sort, ascending);
  }

  @override
  Widget build(BuildContext context) {
    final all = controller.filteredCampaigns;
    final pageCount = (all.length / _pageSize).ceil();
    if (_page >= pageCount && pageCount > 0) _page = pageCount - 1;
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, all.length);
    final pageItems = all.isEmpty ? <Campaign>[] : all.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Campaigns',
          subtitle: 'Manage campaigns that feed the viewer mobile app.',
          trailing: FilledButton.icon(
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New campaign'),
          ),
        ),
        const SizedBox(height: 20),
        _FilterBar(
          controller: controller,
          onChanged: () => setState(() => _page = 0),
        ),
        const SizedBox(height: 16),
        if (controller.isEmpty)
          EmptyState(
            icon: Icons.campaign_outlined,
            title: 'No campaigns yet',
            message: 'Create a campaign to start collecting verified attention.',
            actionLabel: 'Create campaign',
            onAction: widget.onCreate,
          )
        else if (all.isEmpty)
          const EmptyState(
            icon: Icons.search_off,
            title: 'No matches',
            message:
                'No campaigns match your search or filter. Try adjusting them.',
          )
        else ...[
          _CampaignTable(
            campaigns: pageItems,
            sortColumnIndex: _sortColumnIndex(),
            sortAscending: controller.sortAscending,
            onSort: _onSort,
            onAction: (campaign, action) =>
                _handleAction(context, campaign, action),
            onOpen: widget.onOpen,
          ),
          const SizedBox(height: 14),
          _Pagination(
            page: _page,
            pageCount: pageCount,
            start: all.isEmpty ? 0 : start + 1,
            end: end,
            total: all.length,
            onPrev: _page > 0 ? () => setState(() => _page--) : null,
            onNext: _page < pageCount - 1 ? () => setState(() => _page++) : null,
          ),
        ],
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller, required this.onChanged});

  final DashboardController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterChip(
          label: 'All',
          selected: controller.statusFilter == null,
          onTap: () {
            controller.setStatusFilter(null);
            onChanged();
          },
        ),
        for (final status in CampaignStatus.values)
          _FilterChip(
            label: status.label,
            selected: controller.statusFilter == status,
            onTap: () {
              controller.setStatusFilter(status);
              onChanged();
            },
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.mint : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.mint : AppColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.pageCount,
    required this.start,
    required this.end,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int pageCount;
  final int start;
  final int end;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Showing $start–$end of $total',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const Spacer(),
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous',
        ),
        Text(
          '${page + 1} / ${pageCount == 0 ? 1 : pageCount}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next',
        ),
      ],
    );
  }
}

enum _CampaignAction { open, edit, pause, resume, complete, duplicate, delete }

class _CampaignTable extends StatelessWidget {
  const _CampaignTable({
    required this.campaigns,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onAction,
    required this.onOpen,
  });

  final List<Campaign> campaigns;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending) onSort;
  final void Function(Campaign campaign, _CampaignAction action) onAction;
  final ValueChanged<Campaign> onOpen;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 360,
          ),
          child: DataTable(
            columnSpacing: 26,
            horizontalMargin: 16,
            headingRowHeight: 46,
            dataRowMinHeight: 62,
            dataRowMaxHeight: 72,
            showCheckboxColumn: false,
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
            columns: [
              DataColumn(label: const Text('Campaign'), onSort: onSort),
              const DataColumn(label: Text('Task')),
              DataColumn(label: const Text('Budget'), numeric: true, onSort: onSort),
              const DataColumn(label: Text('Reward')),
              const DataColumn(label: Text('Status')),
              DataColumn(label: const Text('Completion'), onSort: onSort),
              const DataColumn(label: Text('')),
            ],
            rows: [for (final campaign in campaigns) _row(context, campaign)],
          ),
        ),
      ),
    );
  }

  DataRow _row(BuildContext context, Campaign campaign) {
    final active = campaign.status == CampaignStatus.active;
    return DataRow(
      onSelectChanged: (_) => onOpen(campaign),
      cells: [
        DataCell(
          SizedBox(
            width: 240,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  campaign.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        DataCell(_TaskChip(label: campaign.interactions.first.type.label)),
        DataCell(Text(formatCurrency(campaign.budget))),
        DataCell(Text(formatCurrency(campaign.rewardPerCompletion))),
        DataCell(StatusBadge(status: campaign.status)),
        DataCell(_CompletionCell(rate: campaign.completionRate)),
        DataCell(
          PopupMenuButton<_CampaignAction>(
            icon: const Icon(Icons.more_horiz, color: AppColors.muted),
            onSelected: (action) => onAction(campaign, action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _CampaignAction.open,
                child: _MenuRow(icon: Icons.open_in_full, label: 'Open'),
              ),
              const PopupMenuItem(
                value: _CampaignAction.edit,
                child: _MenuRow(icon: Icons.edit_outlined, label: 'Edit'),
              ),
              if (active)
                const PopupMenuItem(
                  value: _CampaignAction.pause,
                  child: _MenuRow(
                    icon: Icons.pause_circle_outline,
                    label: 'Pause',
                  ),
                )
              else
                const PopupMenuItem(
                  value: _CampaignAction.resume,
                  child: _MenuRow(
                    icon: Icons.play_circle_outline,
                    label: 'Resume',
                  ),
                ),
              const PopupMenuItem(
                value: _CampaignAction.complete,
                child: _MenuRow(
                  icon: Icons.check_circle_outline,
                  label: 'Mark completed',
                ),
              ),
              const PopupMenuItem(
                value: _CampaignAction.duplicate,
                child: _MenuRow(
                  icon: Icons.copy_all_outlined,
                  label: 'Duplicate',
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _CampaignAction.delete,
                child: _MenuRow(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  danger: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompletionCell extends StatelessWidget {
  const _CompletionCell({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: rate.clamp(0, 1),
                minHeight: 6,
                color: AppColors.mint,
                backgroundColor: AppColors.mintSoft,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatPercent(rate),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.blue,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.ink;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
