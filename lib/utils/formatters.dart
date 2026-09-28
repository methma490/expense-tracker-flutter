class Formatters {
  Formatters._();

  static const List<String> _months = [
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

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// 1250.5 -> "Rs. 1,250.50"
  static String currency(double amount) {
    final fixed = amount.abs().toStringAsFixed(2);
    final parts = fixed.split('.');

    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    final sign = amount < 0 ? '-' : '';

    return '${sign}Rs. $whole.${parts[1]}';
  }

  static String monthName(int month) => _months[month - 1];

  /// "September 2026"
  static String monthYear(DateTime date) {
    return '${monthName(date.month)} ${date.year}';
  }

  /// "05/09/2026"
  static String date(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  /// "Today", "Yesterday" or "Mon, 21 Sep"
  static String dayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final difference = today.difference(target).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';

    final weekday = _weekdays[target.weekday - 1];
    final month = _months[target.month - 1].substring(0, 3);

    return '$weekday, ${target.day} $month';
  }
}
