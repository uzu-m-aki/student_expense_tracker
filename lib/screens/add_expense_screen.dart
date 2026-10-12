import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';

class AddExpenseScreen extends StatefulWidget {
  final int userId;

  const AddExpenseScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AddExpenseScreen> createState() =>
      _AddExpenseScreenState();
}

class _AddExpenseScreenState
    extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController =
      TextEditingController();

  final _amountController =
      TextEditingController();

  final _notesController =
      TextEditingController();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  String _selectedCategory = 'Food';

  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  final List<String> _categories = [
    'Food',
    'Transport',
    'School',
    'Shopping',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate =
        await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme:
                DatePickerThemeData(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(
      _amountController.text
          .trim()
          .replaceAll(',', '.'),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid amount.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _databaseHelper.addExpense(
        widget.userId,
        _titleController.text.trim(),
        amount,
        _selectedCategory,
        DateFormat('yyyy-MM-dd')
            .format(_selectedDate),
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Expense added successfully!',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not save expense: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  IconData _categoryIcon(
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

  Widget _buildField({
    required Widget child,
  }) {
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
            blurRadius: 10,
            offset:
                const Offset(0, 4),
            color: Colors.black
                .withOpacity(0.035),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: InputBorder.none,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      labelStyle: TextStyle(
        color: Colors.grey[700],
      ),
      hintStyle: TextStyle(
        color: Colors.grey[500],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Expense',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            35,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  decoration:
                      BoxDecoration(
                    gradient:
                        LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
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
                        BorderRadius.circular(
                      24,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withOpacity(
                            0.7,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            18,
                          ),
                        ),
                        child: Icon(
                          Icons
                              .receipt_long_rounded,
                          size: 29,
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .primary,
                        ),
                      ),

                      const SizedBox(
                        width: 15,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              'New Expense',
                              style:
                                  TextStyle(
                                fontSize: 21,
                                fontWeight:
                                    FontWeight
                                        .w800,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              'Record your spending details below.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors
                                    .grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                const Text(
                  'Expense Details',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                _buildField(
                  child: TextFormField(
                    controller:
                        _titleController,
                    textCapitalization:
                        TextCapitalization
                            .sentences,
                    decoration:
                        _inputDecoration(
                      label:
                          'Expense Title',
                      hint:
                          'e.g. Lunch at school',
                      icon: Icons
                          .receipt_long_rounded,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Please enter an expense title.';
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                _buildField(
                  child: TextFormField(
                    controller:
                        _amountController,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        _inputDecoration(
                      label: 'Amount',
                      hint: '0.00',
                      icon: Icons
                          .payments_rounded,
                      suffixIcon:
                          const Padding(
                        padding:
                            EdgeInsets.only(
                          right: 16,
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            'KSh',
                            style:
                                TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'Please enter an amount.';
                      }

                      final amount =
                          double.tryParse(
                        value
                            .trim()
                            .replaceAll(
                              ',',
                              '.',
                            ),
                      );

                      if (amount == null ||
                          amount <= 0) {
                        return 'Enter a valid amount.';
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                _buildField(
                  child:
                      DropdownButtonFormField<
                          String>(
                    value:
                        _selectedCategory,
                    decoration:
                        _inputDecoration(
                      label: 'Category',
                      hint: 'Select category',
                      icon: _categoryIcon(
                        _selectedCategory,
                      ),
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    items:
                        _categories.map(
                      (category) {
                        return DropdownMenuItem<
                            String>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                _categoryIcon(
                                  category,
                                ),
                                size: 21,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                category,
                              ),
                            ],
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedCategory =
                            value;
                      });
                    },
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                _buildField(
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    child: InputDecorator(
                      decoration:
                          _inputDecoration(
                        label: 'Date',
                        hint:
                            'Select date',
                        icon: Icons
                            .calendar_month_rounded,
                        suffixIcon:
                            const Icon(
                          Icons
                              .arrow_drop_down_rounded,
                        ),
                      ),
                      child: Text(
                        DateFormat(
                          'dd MMM yyyy',
                        ).format(
                          _selectedDate,
                        ),
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                _buildField(
                  child: TextFormField(
                    controller:
                        _notesController,
                    textCapitalization:
                        TextCapitalization
                            .sentences,
                    maxLines: 4,
                    decoration:
                        _inputDecoration(
                      label:
                          'Notes (Optional)',
                      hint:
                          'Add any additional information...',
                      icon: Icons
                          .notes_rounded,
                    ).copyWith(
                      alignLabelWithHint:
                          true,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 58,
                  child:
                      FilledButton.icon(
                    onPressed: _isSaving
                        ? null
                        : _saveExpense,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2.5,
                            ),
                          )
                        : const Icon(
                            Icons
                                .check_rounded,
                          ),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : 'Save Expense',
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    style:
                        FilledButton.styleFrom(
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Center(
                  child: Text(
                    'Your expense will be saved to your account.',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}