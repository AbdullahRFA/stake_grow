import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';

class ActivityHistoryScreen extends ConsumerWidget {
  final String communityId;
  const ActivityHistoryScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(communityActivitiesProvider(communityId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: activities.when(
        loading: () => const Center(child: Loader()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Something went wrong', style: theme.textTheme.titleMedium),
              Text(e.toString(), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        data: (data) {
          if (data.isEmpty) return _buildEmptyState(theme);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(theme, data.length),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final activity = data[index];
                      return _ActivityCard(activity: activity);
                    },
                    childCount: data.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, int count) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'History',
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        centerTitle: false,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count Entries',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 24),
          Text(
            'No Activities Yet',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Expenses and activities will appear here.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final dynamic activity; // Type properly in your real code
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = activity.date as DateTime;

    // Formatting
    final day = DateFormat('dd').format(date);
    final month = DateFormat('MMM').format(date).toUpperCase();
    final currencyFormatter = NumberFormat.decimalPattern();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Date Badge
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    day,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    month,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      activity.type.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '- ৳${currencyFormatter.format(activity.cost)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'RobotoMono', // Optional: if you want monospaced numbers
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.arrow_outward, size: 14, color: Colors.red.shade200),
              ],
            ),
          ],
        ),
      ),
    );
  }
}