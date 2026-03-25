import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/interpolation_result.dart';

class ResultCard extends StatelessWidget {
  final InterpolationResult result;
  final String outputColumn;

  const ResultCard({
    super.key,
    required this.result,
    required this.outputColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  outputColumn,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textLight,
                      ),
                ),
                _buildMethodBadge(context),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              result.value.toStringAsFixed(6),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.primaryBrown,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (result.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.cardBeige.withAlpha(128),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: AppTheme.textLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.description,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textLight,
                                  fontSize: 12,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMethodBadge(BuildContext context) {
    Color badgeColor;
    IconData badgeIcon;

    switch (result.method) {
      case InterpolationMethod.exact:
        badgeColor = AppTheme.successGreen;
        badgeIcon = Icons.check_circle_rounded;
        break;
      case InterpolationMethod.interpolated:
        badgeColor = AppTheme.primaryBrown;
        badgeIcon = Icons.timeline_rounded;
        break;
      case InterpolationMethod.averaged:
        badgeColor = AppTheme.warningAmber;
        badgeIcon = Icons.calculate_rounded;
        break;
      case InterpolationMethod.nearest:
        badgeColor = AppTheme.lightBrown;
        badgeIcon = Icons.near_me_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withAlpha(76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            result.methodLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
