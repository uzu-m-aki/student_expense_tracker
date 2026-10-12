import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'add_expense_screen.dart';
import 'expense_details_screen.dart';
import 'expenses_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  double _totalExpenses = 0.0;
  double _monthlyBudget = 0.0;
  double _currentMonthExpenses = 0.0;

  Map<String, double> _categoryTotals = {};
  List<Map<String, dynamic>> _recentExpenses = [];

  bool _isLoading = true;

  final List<String> _allCategories = [
    'Food',
    'Transport',
    'School',
    'Shopping',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final total =
          await _databaseHelper.getTotalExpenses(widget.userId);

      final categories =
          await _databaseHelper.getCategoryTotals(widget.userId);

      final expenses =
          await _databaseHelper.getExpenses(widget.userId);

      final budget =
          await _databaseHelper.getMonthlyBudget(widget.userId);

      final monthlyExpenses =
          await _databaseHelper.getCurrentMonthExpenses(
        widget.userId,
      );

      if (!mounted) return;

      setState(() {
        _totalExpenses = total;
        _categoryTotals = categories;
        _recentExpenses = expenses.take(4).toList();
        _monthlyBudget = budget;
        _currentMonthExpenses = monthlyExpenses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load dashboard: $e',
          ),
        ),
      );
    }
  }

  Future<void> _openReports() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsScreen(
          userId: widget.userId,
        ),
      ),
    );
  }

  Future<void> _openAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          userId: widget.userId,
        ),
      ),
    );

    if (result == true) {
      await _loadDashboardData();
    }
  }

  Future<void> _openExpenseDetails(
    Map<String, dynamic> expense,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseDetailsScreen(
          expense: expense,
        ),
      ),
    );

    if (result == true) {
      await _loadDashboardData();
    }
  }

  Future<void> _openAllExpenses() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpensesScreen(
          userId: widget.userId,
        ),
      ),
    );

    if (result == true) {
      await _loadDashboardData();
    }
  }

  Future<void> _setBudget() async {
    final controller = TextEditingController(
      text: _monthlyBudget > 0
          ? _monthlyBudget.toStringAsFixed(2)
          : '',
    );

    final budget = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Monthly Budget',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Set the amount you plan to spend this month.',
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: 'KSh ',
                  labelText: 'Monthly budget',
                  hintText: 'e.g. 10000',
                  filled: true,
                  fillColor: Theme.of(dialogContext)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.45),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(dialogContext)
                          .colorScheme
                          .primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.trim(),
                );

                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid budget amount.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child: const Text('Save Budget'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (budget == null) {
      return;
    }

    try {
      await _databaseHelper.setMonthlyBudget(
        widget.userId,
        budget,
      );

      await _loadDashboardData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Monthly budget updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save budget: $e',
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
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

  double _getCategoryAmount(String category) {
    for (final entry in _categoryTotals.entries) {
      if (entry.key.toLowerCase() ==
          category.toLowerCase()) {
        return entry.value;
      }
    }

    return 0.0;
  }

  String _formatAmount(dynamic amount) {
    double value;

    if (amount is num) {
      value = amount.toDouble();
    } else {
      value = double.tryParse(
            amount.toString(),
          ) ??
          0.0;
    }

    return value.toStringAsFixed(2);
  }

  String _formatDate(String date) {
    if (date.isEmpty) {
      return '';
    }

    try {
      final parsedDate = DateTime.parse(date);

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${months[parsedDate.month - 1]} '
          '${parsedDate.day}, '
          '${parsedDate.year}';
    } catch (_) {
      return date;
    }
  }

  Widget _buildSectionTitle(
    String title, {
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBudgetCard() {
    final hasBudget = _monthlyBudget > 0;

    final progress = hasBudget
        ? (_currentMonthExpenses / _monthlyBudget)
            .clamp(0.0, 1.0)
            .toDouble()
        : 0.0;

    final remaining =
        _monthlyBudget - _currentMonthExpenses;

    final isOverBudget = remaining < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withOpacity(0.55),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 7),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.savings_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasBudget
                          ? 'Your spending plan for this month'
                          : 'Set a budget to start tracking',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _setBudget,
                tooltip: hasBudget
                    ? 'Update budget'
                    : 'Set budget',
                icon: const Icon(
                  Icons.edit_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (!hasBudget)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.45),
                borderRadius:
                    BorderRadius.circular(17),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Set a monthly budget to see how much you have left to spend.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KSh ${_currentMonthExpenses.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'spent this month',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KSh ${_monthlyBudget.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'monthly limit',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 11,
                backgroundColor:
                    Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                valueColor:
                    AlwaysStoppedAnimation<Color>(
                  isOverBudget
                      ? Colors.redAccent
                      : Theme.of(context)
                          .colorScheme
                          .primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isOverBudget
                      ? Icons.warning_amber_rounded
                      : Icons
                          .account_balance_wallet_rounded,
                  size: 18,
                  color: isOverBudget
                      ? Colors.redAccent
                      : Theme.of(context)
                          .colorScheme
                          .primary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    isOverBudget
                        ? 'Over budget by KSh ${remaining.abs().toStringAsFixed(2)}'
                        : 'KSh ${remaining.toStringAsFixed(2)} remaining',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isOverBudget
                          ? Colors.redAccent
                          : Colors.grey[700],
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String categoryName) {
    final amount = _getCategoryAmount(categoryName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
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
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _getCategoryIcon(categoryName),
              color: Theme.of(context)
                  .colorScheme
                  .onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            categoryName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'KSh ${_formatAmount(amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExpense(
    Map<String, dynamic> expense,
  ) {
    final title =
        expense['title']?.toString() ?? 'Expense';

    final category =
        expense['category']?.toString() ?? 'Other';

    final amount = expense['amount'] ?? 0;

    final date =
        expense['date']?.toString() ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        _openExpenseDetails(expense);
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surface,
          borderRadius: BorderRadius.circular(20),
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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$category • ${_formatDate(date)}',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'KSh ${_formatAmount(amount)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Expense Tracker',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openReports,
            tooltip: 'Reports',
            icon: const Icon(
              Icons.analytics_rounded,
            ),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout_rounded,
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
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  120,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Hello, ${widget.userName}! 👋',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keep track of your spending with ease.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
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
                        borderRadius:
                            BorderRadius.circular(26),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.65),
                                  borderRadius:
                                      BorderRadius.circular(
                                    17,
                                  ),
                                ),
                                child: Icon(
                                  Icons
                                      .account_balance_wallet_rounded,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  size: 27,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Total Expenses',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'KSh ${_totalExpenses.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Your total recorded spending',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildBudgetCard(),
                    const SizedBox(height: 30),
                    _buildSectionTitle(
                      'Spending by Category',
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 158,
                      ),
                      itemCount:
                          _allCategories.length,
                      itemBuilder:
                          (context, index) {
                        return _buildCategoryCard(
                          _allCategories[index],
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    _buildSectionTitle(
                      'Recent Expenses',
                      actionText: 'View All',
                      onAction: _openAllExpenses,
                    ),
                    const SizedBox(height: 12),
                    if (_recentExpenses.isEmpty)
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 35,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons
                                  .receipt_long_rounded,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No expenses yet',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Add your first expense to get started.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children:
                            _recentExpenses.map(
                          (expense) => Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child:
                                _buildRecentExpense(
                              expense,
                            ),
                          ),
                        ).toList(),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _openAddExpense,
        elevation: 6,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Add Expense',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}