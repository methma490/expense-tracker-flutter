import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

class ExpenseService {
  final CollectionReference<Map<String, dynamic>> _expenses =
      FirebaseFirestore.instance.collection('expenses');

  // READ
  // Listen to all expenses in Firestore.
  Stream<List<Expense>> getExpenses() {
    return _expenses
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((document) => Expense.fromFirestore(document))
          .toList();
    });
  }

  // CREATE
  /// Allocates an ID before saving so a retry from the same form writes to the
  /// same document instead of creating another expense.
  String createExpenseId() => _expenses.doc().id;

  Future<void> addExpense(Expense expense) async {
    if (expense.id.isEmpty) {
      throw ArgumentError(
        'Expense ID cannot be empty when adding an expense.',
      );
    }

    // Do not use CollectionReference.add here. `add` generates a new document
    // ID on every call, so a retry can create a duplicate expense. A stable ID
    // assigned by the form makes the write idempotent.
    await _expenses.doc(expense.id).set(expense.toMap());
  }

  // UPDATE
  Future<void> updateExpense(Expense expense) async {
    if (expense.id.isEmpty) {
      throw ArgumentError(
        'Expense ID cannot be empty when updating an expense.',
      );
    }

    await _expenses.doc(expense.id).update({
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category.name,
      'date': Timestamp.fromDate(expense.date),
      'note': expense.note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // DELETE
  Future<void> deleteExpense(String id) async {
    if (id.isEmpty) {
      throw ArgumentError(
        'Expense ID cannot be empty when deleting an expense.',
      );
    }

    await _expenses.doc(id).delete();
  }

  // UNDO DELETE
  // Re-creates a deleted expense using its original document ID.
  Future<void> restoreExpense(Expense expense) async {
    if (expense.id.isEmpty) {
      throw ArgumentError(
        'Expense ID cannot be empty when restoring an expense.',
      );
    }

    await _expenses.doc(expense.id).set(expense.toMap());
  }
}
