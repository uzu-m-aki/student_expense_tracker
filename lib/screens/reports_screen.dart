import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  final int userId;

  const ReportsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  bool _isLoading = true;

  List<Map<String, dynamic>> _expenses = [];
  Map<String, double> _categoryTotals = {};

  double _totalSpent = 0.0;
  double _thisMonthSpent = 0.0;
  double _monthlyBudget = 0.0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final expenses =
          await _databaseHelper.getExpenses(widget.userId);

      final categoryTotals =
          await _databaseHelper.getCategoryTotals(widget.userId);

      final total =
          await _databaseHelper.getTotalExpenses(widget.userId);

      final thisMonth =
          await _databaseHelper.getCurrentMonthExpenses(widget.userId);

      final budget =
          await _databaseHelper.getMonthlyBudget(widget.userId);

      if (!mounted) return;

      setState(() {
        _expenses = expenses;
        _categoryTotals = categoryTotals;
        _totalSpent = total;
        _thisMonthSpent = thisMonth;
        _monthlyBudget = budget;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load reports: $e'),
        ),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  String _getHighestCategory() {
    if (_categoryTotals.isEmpty) {
      return 'None';
    }

    final sorted = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  double _getHighestCategoryAmount() {
    if (_categoryTotals.isEmpty) {
      return 0.0;
    }

    final sorted = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.value;
  }

  double _getAverageExpense() {
    if (_expenses.isEmpty) {
      return 0.0;
    }

    return _totalSpent / _expenses.length;
  }

  double _getCategoryPercentage(double amount) {
    if (_totalSpent <= 0) {
      return 0.0;
    }

    return (amount / _totalSpent) * 100;
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 5),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategory() {
    final category = _getHighestCategory();
    final amount = _getHighestCategoryAmount();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context)
                .colorScheme
                .primaryContainer,
            Theme.of(context)
                .colorScheme
                .secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              _getCategoryIcon(category),
              size: 29,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Highest Spending Category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'KSh ${_formatAmount(amount)} spent',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_categoryTotals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withOpacity(0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 55,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            const Text(
              'No spending data yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Add expenses to see your spending breakdown.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final categories = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final highest = categories.first.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 5),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        children: categories.map((entry) {
          final category = entry.key;
          final amount = entry.value;

          final barValue =
              highest > 0 ? amount / highest : 0.0;

          final percentage =
              _getCategoryPercentage(amount);

          return Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        size: 21,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${percentage.toStringAsFixed(1)}% of total spending',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'KSh ${_formatAmount(amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: barValue,
                    minHeight: 9,
                    backgroundColor:
                        Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBudgetAnalysis() {
    if (_monthlyBudget <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withOpacity(0.45),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 27,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                'Set a monthly budget on the dashboard to see your budget performance here.',
                style: TextStyle(
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final progress = (_thisMonthSpent / _monthlyBudget)
        .clamp(0.0, 1.0)
        .toDouble();

    final remaining =
        _monthlyBudget - _thisMonthSpent;

    final overBudget = remaining < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 5),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Budget Performance',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'KSh ${_formatAmount(_thisMonthSpent)} spent of KSh ${_formatAmount(_monthlyBudget)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor:
                  Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                overBudget
                    ? Colors.redAccent
                    : Theme.of(context)
                        .colorScheme
                        .primary,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(
                overBudget
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                size: 19,
                color: overBudget
                    ? Colors.redAccent
                    : Theme.of(context)
                        .colorScheme
                        .primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  overBudget
                      ? 'You are KSh ${_formatAmount(remaining.abs())} over your monthly budget.'
                      : 'You have KSh ${_formatAmount(remaining)} remaining this month.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: overBudget
                        ? Colors.redAccent
                        : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseCount = _expenses.length;
    final average = _getAverageExpense();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadReports,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  40,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Financial Overview',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Understand where your money is going.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons
                                .account_balance_wallet_rounded,
                            title: 'Total Spent',
                            value:
                                'KSh ${_formatAmount(_totalSpent)}',
                            subtitle: 'all time',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons
                                .calendar_month_rounded,
                            title: 'This Month',
                            value:
                                'KSh ${_formatAmount(_thisMonthSpent)}',
                            subtitle: 'current month',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons
                                .receipt_long_rounded,
                            title: 'Expenses',
                            value: '$expenseCount',
                            subtitle: 'records',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.calculate_rounded,
                            title: 'Average',
                            value:
                                'KSh ${_formatAmount(average)}',
                            subtitle: 'per expense',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Top Spending Category',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildTopCategory(),

                    const SizedBox(height: 30),

                    const Text(
                      'Spending by Category',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildCategoryBreakdown(),

                    const SizedBox(height: 30),

                    const Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildBudgetAnalysis(),
                  ],
                ),
              ),
            ),
    );
  }
}