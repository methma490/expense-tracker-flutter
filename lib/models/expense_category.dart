import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  transport,
  shopping,
  bills,
  entertainment,
  health,
  education,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
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

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFF57C00);
      case ExpenseCategory.transport:
        return const Color(0xFF1E88E5);
      case ExpenseCategory.shopping:
        return const Color(0xFFD81B60);
      case ExpenseCategory.bills:
        return const Color(0xFF6D4C41);
      case ExpenseCategory.entertainment:
        return const Color(0xFF8E24AA);
      case ExpenseCategory.health:
        return const Color(0xFF43A047);
      case ExpenseCategory.education:
        return const Color(0xFF3949AB);
      case ExpenseCategory.other:
        return const Color(0xFF757575);
    }
  }
}
