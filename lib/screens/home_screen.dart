import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/expense_service.dart';
import 'add_edit_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExpenseService _expenseService = ExpenseService();

  ExpenseCategory? _selectedCategory;
  DateTimeRange? _selectedDateRange;

  // ------------------------------------------------------------
  // OPEN ADD EXPENSE SCREEN
  // ------------------------------------------------------------

  Future<void> _openAddExpenseScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditExpenseScreen(),
      ),
    );
  }

  // ------------------------------------------------------------
  // OPEN EDIT EXPENSE SCREEN
  // ------------------------------------------------------------

  Future<void> _openEditExpenseScreen(Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditExpenseScreen(
          expense: expense,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DELETE EXPENSE
  // ------------------------------------------------------------

  Future<void> _deleteExpense(Expense expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text(
            'Are you sure you want to delete "${expense.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _expenseService.deleteExpense(expense.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete expense. Please try again.',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // DATE FILTER
  // ------------------------------------------------------------

  Future<void> _selectDateRange() async {
    final now = DateTime.now();

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedDateRange,
    );

    if (pickedRange != null) {
      setState(() {
        _selectedDateRange = pickedRange;
      });
    }
  }

  // ------------------------------------------------------------
  // CLEAR FILTERS
  // ------------------------------------------------------------

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDateRange = null;
    });
  }

  // ------------------------------------------------------------
  // FILTER EXPENSES
  // ------------------------------------------------------------

  List<Expense> _filterExpenses(List<Expense> expenses) {
    return expenses.where((expense) {
      bool matchesCategory = true;
      bool matchesDate = true;

      if (_selectedCategory != null) {
        matchesCategory =
            expense.category == _selectedCategory;
      }

      if (_selectedDateRange != null) {
        final expenseDate = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );

        final startDate = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );

        final endDate = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
        );

        matchesDate =
            !expenseDate.isBefore(startDate) &&
            !expenseDate.isAfter(endDate);
      }

      return matchesCategory && matchesDate;
    }).toList();
  }

  // ------------------------------------------------------------
  // CURRENT MONTH TOTAL
  // ------------------------------------------------------------

  double _calculateMonthlyTotal(List<Expense> expenses) {
    final now = DateTime.now();

    return expenses
        .where(
          (expense) =>
              expense.date.year == now.year &&
              expense.date.month == now.month,
        )
        .fold(
          0.0,
          (total, expense) => total + expense.amount,
        );
  }

  // ------------------------------------------------------------
  // CATEGORY ICON
  // ------------------------------------------------------------

  IconData _categoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;

      case ExpenseCategory.transport:
        return Icons.directions_bus;

      case ExpenseCategory.shopping:
        return Icons.shopping_bag;

      case ExpenseCategory.bills:
        return Icons.receipt_long;

      case ExpenseCategory.entertainment:
        return Icons.movie;

      case ExpenseCategory.health:
        return Icons.medical_services;

      case ExpenseCategory.education:
        return Icons.school;

      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  // ------------------------------------------------------------
  // MONTH NAME
  // ------------------------------------------------------------

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  // ------------------------------------------------------------
  // FORMAT DATE
  // ------------------------------------------------------------

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ------------------------------------------------------------
  // MAIN UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedCategory != null ||
              _selectedDateRange != null)
            IconButton(
              tooltip: 'Clear filters',
              onPressed: _clearFilters,
              icon: const Icon(
                Icons.filter_alt_off,
              ),
            ),
        ],
      ),

      // ----------------------------------------------------------
      // FIREBASE STREAM
      // ----------------------------------------------------------

      body: StreamBuilder<List<Expense>>(
        stream: _expenseService.getExpenses(),

        builder: (context, snapshot) {
          // ------------------------------------------------------
          // LOADING STATE
          // ------------------------------------------------------

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ------------------------------------------------------
          // ERROR STATE
          // ------------------------------------------------------

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final expenses = snapshot.data ?? [];

          final monthlyTotal =
              _calculateMonthlyTotal(expenses);

          final filteredExpenses =
              _filterExpenses(expenses);

          return Column(
            children: [
              // --------------------------------------------------
              // MONTHLY TOTAL CARD
              // --------------------------------------------------

              _buildMonthlyTotalCard(monthlyTotal),

              // --------------------------------------------------
              // FILTERS
              // --------------------------------------------------

              _buildFilters(),

              // --------------------------------------------------
              // EXPENSE HISTORY HEADER
              // --------------------------------------------------

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Expense History',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),
                    ),
                    Text(
                      '${filteredExpenses.length} '
                      '${filteredExpenses.length == 1 ? 'expense' : 'expenses'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // --------------------------------------------------
              // LIST / EMPTY STATE
              // --------------------------------------------------

              Expanded(
                child: expenses.isEmpty
                    ? _buildEmptyState()
                    : filteredExpenses.isEmpty
                        ? _buildNoResultsState()
                        : _buildExpenseList(
                            filteredExpenses,
                          ),
              ),
            ],
          );
        },
      ),

      // ----------------------------------------------------------
      // ADD BUTTON
      // ----------------------------------------------------------

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _openAddExpenseScreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  // ------------------------------------------------------------
  // MONTHLY TOTAL CARD
  // ------------------------------------------------------------

  Widget _buildMonthlyTotalCard(double monthlyTotal) {
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              const Text(
                'TOTAL EXPENSES',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Rs. ${monthlyTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_monthName(now.month)} ${now.year}',
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FILTER UI
  // ------------------------------------------------------------

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8,
      ),
      child: Row(
        children: [
          // CATEGORY FILTER

          Expanded(
            child: DropdownButtonFormField<
                ExpenseCategory?>(
              initialValue: _selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.filter_list),
                contentPadding:
                    EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: [
                const DropdownMenuItem<
                    ExpenseCategory?>(
                  value: null,
                  child: Text('All'),
                ),
                ...ExpenseCategory.values.map(
                  (category) {
                    return DropdownMenuItem<
                        ExpenseCategory?>(
                      value: category,
                      child: Text(
                        category.displayName,
                      ),
                    );
                  },
                ),
              ],
              onChanged: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          ),

          const SizedBox(width: 10),

          // DATE FILTER

          OutlinedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(
              Icons.date_range,
            ),
            label: Text(
              _selectedDateRange == null
                  ? 'Date'
                  : '${_selectedDateRange!.start.day}/'
                      '${_selectedDateRange!.start.month}'
                      ' - '
                      '${_selectedDateRange!.end.day}/'
                      '${_selectedDateRange!.end.month}',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(
                110,
                56,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // EXPENSE LIST
  // ------------------------------------------------------------

  Widget _buildExpenseList(
    List<Expense> expenses,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        100,
      ),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];

        return Card(
          margin: const EdgeInsets.only(
            bottom: 10,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              _openEditExpenseScreen(expense);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 6,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    _categoryIcon(
                      expense.category,
                    ),
                  ),
                ),

                // TITLE + CATEGORY + DATE

                title: Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                subtitle: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${expense.category.displayName}'
                      ' • '
                      '${_formatDate(expense.date)}',
                    ),

                    if (expense.note != null &&
                        expense.note!
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        expense.note!,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),

                // AMOUNT + MENU

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rs. ${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEditExpenseScreen(
                            expense,
                          );
                        }

                        if (value == 'delete') {
                          _deleteExpense(
                            expense,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                              ),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                              ),
                              SizedBox(width: 10),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // EMPTY DATABASE
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 75,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              'No expenses yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Expense" to add your '
              'first expense.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FILTER RETURNS NOTHING
  // ------------------------------------------------------------

  Widget _buildNoResultsState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching expenses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try changing or clearing your filters.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(
                Icons.filter_alt_off,
              ),
              label: const Text(
                'Clear Filters',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FIREBASE ERROR
  // ------------------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 70,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unable to load your expenses. '
              'Please check your connection '
              'and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}