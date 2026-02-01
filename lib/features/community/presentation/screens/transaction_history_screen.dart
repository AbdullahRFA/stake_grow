import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/community/presentation/transaction_providers.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  final String communityId;
  const TransactionHistoryScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3, // ৩টি ট্যাব
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transparency & History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Donations', icon: Icon(Icons.volunteer_activism)),
              Tab(text: 'Investments', icon: Icon(Icons.trending_up)),
              Tab(text: 'Expenses', icon: Icon(Icons.money_off)),
            ],
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Donations List
            _DonationList(communityId: communityId),

            // Tab 2: Investments List
            _InvestmentList(communityId: communityId),

            // Tab 3: Activities (Expenses) List
            _ActivityList(communityId: communityId),
          ],
        ),
      ),
    );
  }
}

// ---------------- Sub Widgets ----------------

class _DonationList extends ConsumerWidget {
  final String communityId;
  const _DonationList({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donations = ref.watch(communityDonationsProvider(communityId));

    return donations.when(
      loading: () => const Loader(),
      // ✅ UPDATE: এরর প্রিন্ট করার জন্য ব্লক বডি ব্যবহার করা হলো
      error: (e, s) {
        print('🔴 Donation Error: $e');
        print('Stack Trace: $s'); // কোন লাইন থেকে এরর এসেছে তা দেখাবে
        return Center(child: Text('Error: $e'));
      },
      data: (data) {
        if (data.isEmpty) return const Center(child: Text('No donations yet.'));
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final donation = data[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.arrow_downward, color: Colors.white),
              ),
              title: Text(donation.senderName),
              subtitle: Text(DateFormat('dd MMM, hh:mm a').format(donation.timestamp)),
              trailing: Text(
                '+ ৳${donation.amount}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            );
          },
        );
      },
    );
  }
}

class _InvestmentList extends ConsumerWidget {
  final String communityId;
  const _InvestmentList({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investments = ref.watch(communityInvestmentsProvider(communityId));

    return investments.when(
      loading: () => const Loader(),
      // ✅ UPDATE
      error: (e, s) {
        print('🔴 Investment Error: $e');
        print('Stack Trace: $s');
        return Center(child: Text('Error: $e'));
      },
      data: (data) {
        if (data.isEmpty) return const Center(child: Text('No investments yet.'));
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final invest = data[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.bar_chart, color: Colors.white),
              ),
              title: Text(invest.projectName),
              subtitle: Text(invest.status.toUpperCase()),
              trailing: Text(
                '- ৳${invest.investedAmount}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            );
          },
        );
      },
    );
  }
}

class _ActivityList extends ConsumerWidget {
  final String communityId;
  const _ActivityList({required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(communityActivitiesProvider(communityId));

    return activities.when(
      loading: () => const Loader(),
      // ✅ UPDATE
      error: (e, s) {
        print('🔴 Activity Error: $e');
        print('Stack Trace: $s');
        return Center(child: Text('Error: $e'));
      },
      data: (data) {
        if (data.isEmpty) return const Center(child: Text('No expenses yet.'));
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final activity = data[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.volunteer_activism, color: Colors.white),
              ),
              title: Text(activity.title),
              subtitle: Text(activity.type),
              trailing: Text(
                '- ৳${activity.cost}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            );
          },
        );
      },
    );
  }
}