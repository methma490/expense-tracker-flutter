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
  Future<void> addExpense(Expense expense) async {
    await _expenses.add(expense.toMap());
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
}