import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'expense_details_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final int userId;

  const ExpensesScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ExpensesScreen> createState() =>
      _ExpensesScreenState();
}

class _ExpensesScreenState
    extends State<ExpensesScreen> {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  final TextEditingController _searchController =
      TextEditingController();

  List<Map<String, dynamic>> _allExpenses = [];
  List<Map<String, dynamic>> _filteredExpenses = [];

  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Food',
    'Transport',
    'School',
    'Shopping',
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _filterExpenses,
    );

    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _filterExpenses,
    );

    _searchController.dispose();

    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenses =
          await _databaseHelper.getExpenses(
        widget.userId,
      );

      if (!mounted) return;

      setState(() {
        _allExpenses = expenses;
        _filteredExpenses = expenses;
        _isLoading = false;
      });

      _filterExpenses();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load expenses: $e',
          ),
        ),
      );
    }
  }

  void _filterExpenses() {
    final searchText =
        _searchController.text.trim().toLowerCase();

    final filtered = _allExpenses.where((expense) {
      final title =
          expense['title']?.toString().toLowerCase() ??
              '';

      final category =
          expense['category']?.toString() ?? '';

      final matchesSearch =
          title.contains(searchText);

      final matchesCategory =
          _selectedCategory == 'All' ||
              category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    if (!mounted) return;

    setState(() {
      _filteredExpenses = filtered;
    });
  }

  Future<void> _openExpense(
    Map<String, dynamic> expense,
  ) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExpenseDetailsScreen(
          expense: expense,
        ),
      ),
    );

    if (changed == true) {
      await _loadExpenses();
    }
  }

  IconData _getCategoryIcon(
    String category,
  ) {
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

  Color _getCategoryColor(
    String category,
  ) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;

      case 'transport':
        return Colors.blue;

      case 'school':
        return Colors.purple;

      case 'shopping':
        return Colors.pink;

      default:
        return Colors.grey;
    }
  }

  String _formatAmount(dynamic amount) {
    double value;

    if (amount is num) {
      value = amount.toDouble();
    } else {
      value =
          double.tryParse(
                amount.toString(),
              ) ??
              0.0;
    }

    return value.toStringAsFixed(2);
  }

  String _formatDate(dynamic date) {
    if (date == null) {
      return '';
    }

    final value = date.toString();

    if (value.isEmpty) {
      return '';
    }

    try {
      final parsed =
          DateTime.parse(value);

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

      return '${months[parsed.month - 1]} '
          '${parsed.day}, '
          '${parsed.year}';
    } catch (_) {
      return value;
    }
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black
                .withOpacity(0.04),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText:
              'Search expenses...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
          ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    )
                  : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder:
            (context, index) {
          final category =
              _categories[index];

          final selected =
              category ==
                  _selectedCategory;

          return Padding(
            padding:
                const EdgeInsets.only(
              right: 9,
            ),
            child: ChoiceChip(
              label: Text(category),
              selected: selected,
              showCheckmark: false,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              selectedColor:
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer,
              backgroundColor:
                  Theme.of(context)
                      .colorScheme
                      .surface,
              side: BorderSide(
                color: selected
                    ? Colors.transparent
                    : Theme.of(context)
                        .colorScheme
                        .outlineVariant,
              ),
              labelStyle: TextStyle(
                fontWeight:
                    selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                color: selected
                    ? Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                    : null,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedCategory =
                      category;
                });

                _filterExpenses();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpenseCard(
    Map<String, dynamic> expense,
  ) {
    final title =
        expense['title']?.toString() ??
            'Expense';

    final category =
        expense['category']?.toString() ??
            'Other';

    final date =
        expense['date'];

    final amount =
        expense['amount'] ?? 0;

    final categoryColor =
        _getCategoryColor(category);

    return InkWell(
      borderRadius:
          BorderRadius.circular(20),
      onTap: () {
        _openExpense(expense);
      },
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surface,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset:
                  const Offset(0, 5),
              color: Colors.black
                  .withOpacity(0.04),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: categoryColor
                    .withOpacity(0.12),
                borderRadius:
                    BorderRadius.circular(
                  17,
                ),
              ),
              child: Icon(
                _getCategoryIcon(
                  category,
                ),
                color: categoryColor,
                size: 25,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w500,
                      color:
                          categoryColor,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  'KSh ${_formatAmount(amount)}',
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Icon(
                  Icons
                      .chevron_right_rounded,
                  size: 20,
                  color:
                      Colors.grey[500],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons
                    .receipt_long_rounded,
                size: 42,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              'No expenses found',
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _searchController
                          .text
                          .isNotEmpty ||
                      _selectedCategory !=
                          'All'
                  ? 'Try another search or category.'
                  : 'Your expenses will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Expenses',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    10,
                  ),
                  child:
                      _buildSearchBox(),
                ),

                Padding(
                  padding:
                      const EdgeInsets.only(
                    left: 20,
                    bottom: 8,
                  ),
                  child:
                      _buildCategoryFilters(),
                ),

                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    12,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        'Your Expenses',
                        style:
                            TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .primaryContainer,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child: Text(
                          '${_filteredExpenses.length} found',
                          style:
                              TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w700,
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child:
                      _filteredExpenses
                              .isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh:
                                  _loadExpenses,
                              child:
                                  ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets
                                        .fromLTRB(
                                  20,
                                  4,
                                  20,
                                  30,
                                ),
                                itemCount:
                                    _filteredExpenses
                                        .length,
                                itemBuilder:
                                    (context,
                                        index) {
                                  return _buildExpenseCard(
                                    _filteredExpenses[
                                        index],
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
    );
  }
}