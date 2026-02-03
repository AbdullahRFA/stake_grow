import 'package:stake_grow/features/activity/domain/activity_model.dart';
import 'package:stake_grow/features/donation/domain/donation_model.dart';
import 'package:stake_grow/features/investment/domain/investment_model.dart';
import 'package:stake_grow/features/loan/domain/loan_model.dart';

class FinancialCalculator {
  /// Calculates the Liquid Balance (Available Funds) for every user in the community.
  /// Logic matches UserStats:
  /// Liquid = Total Approved Deposits - (Active Investment Locks + Active Loan Locks + Expense Shares)
  static Map<String, double> calculateUserLiquidBalances({
    required List<DonationModel> donations,
    required List<InvestmentModel> investments,
    required List<LoanModel> loans,
    required List<ActivityModel> activities,
  }) {
    Map<String, double> userBalances = {};

    // 1. Add Approved Donations (Net Contribution)
    for (var d in donations) {
      if (d.status == 'approved') {
        userBalances[d.senderId] = (userBalances[d.senderId] ?? 0.0) + d.amount;
      }
    }

    // 2. Subtract Active Investments (Locked Money)
    for (var invest in investments) {
      if (invest.status == 'active') {
        invest.userShares.forEach((uid, share) {
          if (userBalances.containsKey(uid)) {
            userBalances[uid] = userBalances[uid]! - share;
          }
        });
      }
    }

    // 3. Subtract Active Loans (Money lent to others)
    // Note: We only subtract for 'approved' (active) loans.
    // 'repaid' loans release the lock, so we don't subtract them here.
    for (var loan in loans) {
      if (loan.status == 'approved') {
        loan.lenderShares.forEach((uid, share) {
          if (userBalances.containsKey(uid)) {
            userBalances[uid] = userBalances[uid]! - share;
          }
        });
      }
    }

    // 4. Subtract Activities (Money spent/burned)
    for (var activity in activities) {
      activity.expenseShares.forEach((uid, share) {
        if (userBalances.containsKey(uid)) {
          userBalances[uid] = userBalances[uid]! - share;
        }
      });
    }

    // 5. Ensure no negative balances (Safety check against data inconsistencies)
    userBalances.updateAll((key, value) => value < 0 ? 0.0 : value);

    return userBalances;
  }
}