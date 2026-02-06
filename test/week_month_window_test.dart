import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/shared/local_day.dart';

void main() {
  test('ISO week window starts on Monday', () {
    final now = DateTime.now();
    final offset = now.weekday - DateTime.monday;
    final weekStart = startOfLocalDay(now).subtract(Duration(days: offset));
    final weekEnd = weekStart.add(const Duration(days: 7));

    expect(weekStart.weekday, DateTime.monday);
    expect(weekEnd.difference(weekStart).inDays, 7);
  });

  test('month window starts on first day and ends next month start', () {
    final now = DateTime.now();
    final monthStart = startOfLocalDay(DateTime(now.year, now.month, 1));
    final monthEnd = startOfLocalDay(DateTime(now.year, now.month + 1, 1));

    expect(monthStart.day, 1);
    expect(monthEnd.isAfter(monthStart), true);
    expect(monthEnd.difference(monthStart).inDays >= 28, true);
  });
}
