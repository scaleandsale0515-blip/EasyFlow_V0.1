import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();

class Fmt {
  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _currencyDecimal = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static final _date = DateFormat('d MMM yyyy');
  static final _dateShort = DateFormat('d MMM');
  static final _dayHeader = DateFormat('EEEE, d MMM yyyy');

  static String money(double v) => _currency.format(v);
  static String moneyDecimal(double v) => _currencyDecimal.format(v);
  static String date(DateTime d) => _date.format(d);
  static String dateShort(DateTime d) => _dateShort.format(d);
  static String dayHeader(DateTime d) => _dayHeader.format(d);

  static String qty(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

enum DateRangeFilter { today, thisWeek, thisMonth, thisQuarter, thisYear, custom }

class DateRange {
  final DateTime start;
  final DateTime end;
  DateRange(this.start, this.end);

  static DateRange forFilter(DateRangeFilter filter, {DateTime? customStart, DateTime? customEnd}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (filter) {
      case DateRangeFilter.today:
        return DateRange(today, today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)));
      case DateRangeFilter.thisWeek:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return DateRange(start, start.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1)));
      case DateRangeFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        return DateRange(start, end);
      case DateRangeFilter.thisQuarter:
        final q = ((now.month - 1) ~/ 3);
        final start = DateTime(now.year, q * 3 + 1, 1);
        final end = DateTime(now.year, q * 3 + 4, 1).subtract(const Duration(milliseconds: 1));
        return DateRange(start, end);
      case DateRangeFilter.thisYear:
        return DateRange(DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1).subtract(const Duration(milliseconds: 1)));
      case DateRangeFilter.custom:
        return DateRange(customStart ?? today, customEnd ?? today);
    }
  }

  bool contains(DateTime d) => !d.isBefore(start) && !d.isAfter(end);
}
