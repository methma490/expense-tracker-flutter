import 'package:cloud_firestore/cloud_firestore.dart';

import 'expense_category.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  // Converts an Expense object into data that Firebase can store.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Converts a Firebase document back into an Expense object.
  factory Expense.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError(
        'Expense document ${document.id} contains no data.',
      );
    }

    final categoryName = data['category'] as String? ?? 'other';

    final category = ExpenseCategory.values.firstWhere(
      (category) => category.name == categoryName,
      orElse: () => ExpenseCategory.other,
    );

    final timestamp = data['date'] as Timestamp?;

    return Expense(
      id: document.id,
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: category,
      date: timestamp?.toDate() ?? DateTime.now(),
      note: data['note'] as String?,
    );
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}