import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/expense_service.dart';
import '../utils/formatters.dart';

/// Pops with:
///  'added'   -> a new expense was saved
///  'updated' -> an existing expense was saved
///  'delete'  -> user asked to delete (HomeScreen performs the delete + undo)
class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({
    super.key,
    this.expense,
  });

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final ExpenseService _expenseService = ExpenseService();

  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  late DateTime _selectedDate;
  late final String _newExpenseId;

  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();

    // Allocate this once, rather than inside _saveExpense. If a save has to be
    // retried, it targets the same Firestore document.
    _newExpenseId = _isEditing ? '' : _expenseService.createExpenseId();

    final expense = widget.expense;

    if (expense != null) {
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _noteController.text = expense.note ?? '';
      _selectedCategory = expense.category;
      _selectedDate = DateUtils.dateOnly(expense.date);
    } else {
      _selectedDate = DateUtils.dateOnly(DateTime.now());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // DATE
  // ------------------------------------------------------------

  bool get _isToday =>
      DateUtils.isSameDay(_selectedDate, DateTime.now());

  bool get _isYesterday => DateUtils.isSameDay(
        _selectedDate,
        DateTime.now().subtract(const Duration(days: 1)),
      );

  Future<void> _selectDate() async {
    final earliest = DateTime(2020);
    final today = DateUtils.dateOnly(DateTime.now());

    // firstDate/lastDate are widened if needed so initialDate is always valid
    // (otherwise editing an old or future-dated expense would crash).
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _selectedDate.isBefore(earliest) ? _selectedDate : earliest,
      lastDate: _selectedDate.isAfter(today) ? _selectedDate : today,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(pickedDate);
      });
    }
  }

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------

  Future<void> _saveExpense() async {
    // setState does not rebuild the button until the next frame, so a very
    // quick double-tap could otherwise start two Firestore writes.
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Keep a time-of-day so expenses on the same day stay in order.
    final timeSource = widget.expense?.date ?? DateTime.now();

    final expense = Expense(
      id: widget.expense?.id ?? _newExpenseId,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim().replaceAll(',', '')),
      category: _selectedCategory,
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        timeSource.hour,
        timeSource.minute,
      ),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    try {
      await (_isEditing
          ? _expenseService.updateExpense(expense)
          : _expenseService.addExpense(expense));

      if (!mounted) return;

      Navigator.pop(context, _isEditing ? 'updated' : 'added');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save expense. Please try again.'),
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

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text(
            'Are you sure you want to delete "${widget.expense!.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    Navigator.pop(context, 'delete');
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete expense',
              onPressed: _isSaving ? null : _confirmDelete,
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // AMOUNT (big, first)
                TextFormField(
                  controller: _amountController,
                  autofocus: !_isEditing,
                  enabled: !_isSaving,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: '0.00',
                    prefixText: 'Rs. ',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 20,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }

                    final amount = double.tryParse(
                      value.trim().replaceAll(',', ''),
                    );

                    if (amount == null) {
                      return 'Please enter a valid number';
                    }

                    if (amount <= 0) {
                      return 'Amount must be greater than 0';
                    }

                    if (amount > 100000000) {
                      return 'Amount is too large';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // TITLE
                TextFormField(
                  controller: _titleController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Lunch',
                    prefixIcon: Icon(Icons.title),
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }

                    if (value.trim().length < 2) {
                      return 'Title must contain at least 2 characters';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // CATEGORY (chips instead of dropdown)
                _sectionLabel('Category'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in ExpenseCategory.values)
                      ChoiceChip(
                        avatar: Icon(
                          category.icon,
                          size: 18,
                          color: _selectedCategory == category
                              ? null
                              : category.color,
                        ),
                        label: Text(category.displayName),
                        selected: _selectedCategory == category,
                        onSelected: _isSaving
                            ? null
                            : (_) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // DATE (quick chips + picker)
                _sectionLabel('Date'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Today'),
                      selected: _isToday,
                      onSelected: _isSaving
                          ? null
                          : (_) {
                              setState(() {
                                _selectedDate =
                                    DateUtils.dateOnly(DateTime.now());
                              });
                            },
                    ),
                    ChoiceChip(
                      label: const Text('Yesterday'),
                      selected: _isYesterday,
                      onSelected: _isSaving
                          ? null
                          : (_) {
                              setState(() {
                                _selectedDate = DateUtils.dateOnly(
                                  DateTime.now()
                                      .subtract(const Duration(days: 1)),
                                );
                              });
                            },
                    ),
                    ActionChip(
                      avatar: const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                      ),
                      label: Text(
                        _isToday || _isYesterday
                            ? 'Pick date'
                            : Formatters.date(_selectedDate),
                      ),
                      onPressed: _isSaving ? null : _selectDate,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // NOTE
                TextFormField(
                  controller: _noteController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    hintText: 'Add a description',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  maxLength: 250,
                ),
                const SizedBox(height: 16),

                // SAVE
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveExpense,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : _isEditing
                              ? 'Update Expense'
                              : 'Save Expense',
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
