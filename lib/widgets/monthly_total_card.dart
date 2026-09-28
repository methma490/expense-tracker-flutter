import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../utils/formatters.dart';

class MonthlyTotalCard extends StatelessWidget {
  final DateTime month;
  final double total;
  final double previousTotal;
  final int count;
  final Map<ExpenseCategory, double> byCategory;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const MonthlyTotalCard({
    super.key,
    required this.month,
    required this.total,
    required this.previousTotal,
    required this.count,
    required this.byCategory,
    required this.onPrevious,
    required this.onNext,
  });

  String? _comparisonText() {
    if (previousTotal <= 0 || total <= 0) return null;

    final previousMonth = DateTime(month.year, month.month - 1);
    final previousName = Formatters.monthName(previousMonth.month);
    final difference = total - previousTotal;
    final percent = (difference.abs() / previousTotal * 100).round();

    if (percent == 0) return 'About the same as $previousName';

    return '$percent% ${difference > 0 ? 'more' : 'less'} than $previousName';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onColor = colorScheme.onPrimaryContainer;
    final comparison = _comparisonText();
    final spendingUp = total > previousTotal;

    final entries = byCategory.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MONTH NAVIGATION
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: onPrevious,
                icon: Icon(Icons.chevron_left, color: onColor),
              ),
              Expanded(
                child: Text(
                  Formatters.monthYear(month),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: onNext,
                icon: Icon(
                  Icons.chevron_right,
                  color: onNext == null ? onColor.withValues(alpha: 0.3) : onColor,
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'TOTAL SPENT',
                  style: TextStyle(
                    color: onColor.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Formatters.currency(total),
                    style: TextStyle(
                      color: onColor,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (comparison != null) ...[
                      Icon(
                        spendingUp
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 18,
                        color: onColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          comparison,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: onColor, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: onColor)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '$count ${count == 1 ? 'expense' : 'expenses'}',
                      style: TextStyle(color: onColor, fontSize: 13),
                    ),
                  ],
                ),

                // CATEGORY BREAKDOWN
                if (entries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          for (final entry in entries)
                            Expanded(
                              flex: math.max(1, (entry.value * 100).round()),
                              child: Container(color: entry.key.color),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      for (final entry in entries.take(4))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: entry.key.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${entry.key.displayName} '
                              '${(entry.value / total * 100).round()}%',
                              style: TextStyle(color: onColor, fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
