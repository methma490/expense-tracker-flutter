import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/expense_service.dart';
import '../utils/formatters.dart';
import '../widgets/expense_card.dart';
import '../widgets/monthly_total_card.dart';
import 'add_edit_expense_screen.dart';

// A day heading row inside the grouped list.
class _DayHeader {
  final DateTime day;
  final double total;

  const _DayHeader(this.day, this.total);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final TextEditingController _searchController = TextEditingController();

  // The stream is created once (not on every rebuild) so the list
  // doesn't flicker when filters change.
  late Stream<List<Expense>> _expensesStream;

  // Expenses hidden immediately while their delete is in flight.
  final Set<String> _pendingDeleteIds = {};

  late DateTime _month;
  ExpenseCategory? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  String _query = '';

  bool get _hasFilters =>
      _selectedCategory != null ||
      _selectedDateRange != null ||
      _query.isNotEmpty;

  @override
  void initState() {
    super.initState();

    _expensesStream = _expenseService.getExpenses();

    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  bool _isInMonth(DateTime date, DateTime month) {
    return date.year == month.year && date.month == month.month;
  }

  double _sum(Iterable<Expense> expenses) {
    return expenses.fold(0.0, (total, expense) => total + expense.amount);
  }

  bool get _canGoToNextMonth {
    final now = DateTime.now();
    return _month.isBefore(DateTime(now.year, now.month));
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _selectedCategory = null;
      _selectedDateRange = null;
      _query = '';
    });
  }

  Future<void> _selectDateRange() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final initialRange = _selectedDateRange ??
        DateTimeRange(
          start: DateTime(_month.year, _month.month),
          end: DateTime(_month.year, _month.month + 1).subtract(
            const Duration(days: 1),
          ),
        );

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
      helpText: 'Select expense date range',
    );

    if (pickedRange == null || !mounted) return;

    setState(() {
      _selectedDateRange = DateTimeRange(
        start: DateUtils.dateOnly(pickedRange.start),
        end: DateUtils.dateOnly(pickedRange.end),
      );
    });
  }

  void _showSnack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  Future<void> _openAddExpenseScreen() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditExpenseScreen()),
    );

    if (!mounted || result == null) return;

    _showSnack('Expense added');
  }

  Future<void> _openEditExpenseScreen(Expense expense) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditExpenseScreen(expense: expense),
      ),
    );

    if (!mounted || result == null) return;

    if (result == 'delete') {
      _deleteWithUndo(expense);
    } else {
      _showSnack('Expense updated');
    }
  }

  // ------------------------------------------------------------
  // DELETE + UNDO
  // ------------------------------------------------------------

  void _deleteWithUndo(Expense expense) {
    // Hide it right away (required for Dismissible) and delete in background.
    setState(() {
      _pendingDeleteIds.add(expense.id);
    });

    _runDelete(expense);

    _showSnack(
      'Deleted "${expense.title}"',
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () => _undoDelete(expense),
      ),
    );
  }

  Future<void> _runDelete(Expense expense) async {
    try {
      await _expenseService.deleteExpense(expense.id);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _pendingDeleteIds.remove(expense.id);
      });

      _showSnack('Unable to delete expense. Please try again.');
    }
  }

  Future<void> _undoDelete(Expense expense) async {
    if (mounted) {
      setState(() {
        _pendingDeleteIds.remove(expense.id);
      });
    }

    try {
      await _expenseService.restoreExpense(expense);
    } catch (error) {
      if (!mounted) return;

      _showSnack('Unable to restore expense.');
    }
  }

  // ------------------------------------------------------------
  // FILTERING + GROUPING
  // ------------------------------------------------------------

  List<Expense> _applyFilters(List<Expense> expenses) {
    final filtered = expenses.where((expense) {
      if (_selectedCategory != null && expense.category != _selectedCategory) {
        return false;
      }

      if (_selectedDateRange != null) {
        final expenseDate = DateUtils.dateOnly(expense.date);
        if (expenseDate.isBefore(_selectedDateRange!.start) ||
            expenseDate.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }

      if (_query.isNotEmpty) {
        final haystack =
            '${expense.title} ${expense.note ?? ''} ${expense.category.displayName}'
                .toLowerCase();

        if (!haystack.contains(_query)) return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  List<Object> _buildListItems(List<Expense> expenses) {
    final dayTotals = <DateTime, double>{};

    for (final expense in expenses) {
      final day = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      dayTotals[day] = (dayTotals[day] ?? 0) + expense.amount;
    }

    final items = <Object>[];
    DateTime? currentDay;

    for (final expense in expenses) {
      final day = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      if (currentDay != day) {
        currentDay = day;
        items.add(_DayHeader(day, dayTotals[day] ?? 0));
      }

      items.add(expense);
    }

    return items;
  }

  // ------------------------------------------------------------
  // MAIN UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          if (_hasFilters)
            IconButton(
              tooltip: 'Clear filters',
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off),
            ),
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expensesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState();
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!
              .where((expense) => !_pendingDeleteIds.contains(expense.id))
              .toList();

          // Month data (summary card is never affected by search/category).
          final monthExpenses =
              all.where((e) => _isInMonth(e.date, _month)).toList();

          final previousMonth = DateTime(_month.year, _month.month - 1);
          final previousTotal =
              _sum(all.where((e) => _isInMonth(e.date, previousMonth)));

          final byCategory = <ExpenseCategory, double>{};
          for (final expense in monthExpenses) {
            byCategory[expense.category] =
                (byCategory[expense.category] ?? 0) + expense.amount;
          }

          // A chosen date range searches the full expense history; otherwise
          // the list follows the month selected in the summary card.
          final listExpenses =
              _selectedDateRange == null ? monthExpenses : all;
          final filtered = _applyFilters(listExpenses);
          final items = _buildListItems(filtered);

          final bottomInset = MediaQuery.of(context).padding.bottom;

          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: MonthlyTotalCard(
                  month: _month,
                  total: _sum(monthExpenses),
                  previousTotal: previousTotal,
                  count: monthExpenses.length,
                  byCategory: byCategory,
                  onPrevious: () => _changeMonth(-1),
                  onNext: _canGoToNextMonth ? () => _changeMonth(1) : null,
                ),
              ),
              SliverToBoxAdapter(child: _buildFilters()),
              SliverToBoxAdapter(child: _buildListHeader(filtered)),
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: listExpenses.isEmpty && !_hasFilters
                      ? _buildEmptyState()
                      : _buildNoResultsState(),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 96 + bottomInset),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      if (item is _DayHeader) {
                        return _buildDayHeader(item);
                      }

                      final expense = item as Expense;

                      return ExpenseCard(
                        key: ValueKey(expense.id),
                        expense: expense,
                        onTap: () => _openEditExpenseScreen(expense),
                        onDismissed: () => _deleteWithUndo(expense),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpenseScreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  // ------------------------------------------------------------
  // FILTERS (search, category, and date range)
  // ------------------------------------------------------------

  Widget _buildFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              setState(() {
                _query = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search title, note or category',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                        });
                      },
                    ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
              ),
              for (final category in ExpenseCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      category.icon,
                      size: 18,
                      color: _selectedCategory == category
                          ? null
                          : category.color,
                    ),
                    label: Text(category.displayName),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                _selectedDateRange == null
                    ? 'Date range'
                    : '${Formatters.date(_selectedDateRange!.start)} – '
                        '${Formatters.date(_selectedDateRange!.end)}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // LIST HEADERS
  // ------------------------------------------------------------

  Widget _buildListHeader(List<Expense> filtered) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = filtered.length;

    final summary = _hasFilters
        ? '$count found • ${Formatters.currency(_sum(filtered))}'
        : '$count ${count == 1 ? 'expense' : 'expenses'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Transactions',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            summary,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(_DayHeader header) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              Formatters.dayHeader(header.day),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            Formatters.currency(header.total),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY / NO RESULTS / ERROR STATES
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 96),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses in ${Formatters.monthYear(_month)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Expense" to record one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 96),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 68, color: colorScheme.outline),
          const SizedBox(height: 16),
          const Text(
            'No matching expenses',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your search, category, or date range.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 70),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unable to load your expenses. '
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _expensesStream = _expenseService.getExpenses();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
