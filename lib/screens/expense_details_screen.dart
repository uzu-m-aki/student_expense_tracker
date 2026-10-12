
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> expense;

  const ExpenseDetailsScreen({
    super.key,
    required this.expense,
  });

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  late String _selectedCategory;
  late DateTime _selectedDate;

  bool _isSaving = false;

  final List<String> _categories = [
    'Food',
    'Transport',
    'School',
    'Shopping',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'School': Icons.school_rounded,
    'Shopping': Icons.shopping_bag_rounded,
  };

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.expense['title'],
    );

    _amountController = TextEditingController(
      text: (widget.expense['amount'] as num).toString(),
    );

    _notesController = TextEditingController(
      text: widget.expense['notes'] ?? '',
    );

    _selectedCategory = widget.expense['category'];

    _selectedDate = DateTime.parse(
      widget.expense['date'],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
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

  Future<void> _updateExpense() async {
    if (_titleController.text.trim().isEmpty) {
      _showMessage('Please enter an expense title.');
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _databaseHelper.updateExpense(
        widget.expense['id'],
        _titleController.text.trim(),
        amount,
        _selectedCategory,
        DateFormat('yyyy-MM-dd').format(_selectedDate),
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Could not update expense.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text('Delete Expense'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this expense? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _databaseHelper.deleteExpense(
        widget.expense['id'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Could not delete expense.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _categoryColor() {
    switch (_selectedCategory) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'School':
        return Colors.green;
      case 'Shopping':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF4F46E5),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF6366F1),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF6366F1),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7FB),
        foregroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Expense Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4F46E5),
                    Color(0xFF7C3AED),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      _categoryIcons[_selectedCategory] ??
                          Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit your expense',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _titleController.text.isEmpty
                              ? 'Expense'
                              : _titleController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _buildSectionTitle(
              'Expense Information',
              Icons.receipt_long_rounded,
            ),

            const SizedBox(height: 14),

            // Title
            TextField(
              controller: _titleController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: _inputDecoration(
                label: 'Expense Title',
                icon: Icons.receipt_long_rounded,
              ),
            ),

            const SizedBox(height: 15),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                label: 'Amount (KSh)',
                icon: Icons.payments_rounded,
              ),
            ),

            const SizedBox(height: 15),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: _inputDecoration(
                label: 'Category',
                icon: Icons.category_rounded,
              ),
              borderRadius: BorderRadius.circular(16),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        _categoryIcons[category],
                        size: 21,
                        color: categoryColor,
                      ),
                      const SizedBox(width: 10),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),

            const SizedBox(height: 15),

            // Date
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: _inputDecoration(
                  label: 'Date',
                  icon: Icons.calendar_month_rounded,
                ),
                child: Text(
                  DateFormat(
                    'dd MMM yyyy',
                  ).format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            _buildSectionTitle(
              'Additional Notes',
              Icons.notes_rounded,
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: _inputDecoration(
                label: 'Notes',
                icon: Icons.notes_rounded,
              ),
            ),

            const SizedBox(height: 30),

            // Update button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _updateExpense,
                icon: _isSaving
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving ? 'Saving...' : 'Update Expense',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Delete button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _deleteExpense,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text(
                  'Delete Expense',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}