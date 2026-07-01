import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final CampaignStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      CampaignStatus.active => (AppColors.mintSoft, AppColors.mintDark),
      CampaignStatus.draft => (const Color(0xFFFFF3CD), const Color(0xFF976B12)),
      CampaignStatus.paused => (const Color(0xFFEFEFF6), AppColors.blue),
      CampaignStatus.completed => (const Color(0xFFE8EEF9), const Color(0xFF355483)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: colors.$2,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
