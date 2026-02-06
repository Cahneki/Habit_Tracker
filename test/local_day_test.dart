import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/shared/local_day.dart';

void main() {
  test('local day helpers are consistent', () {
    final dt = DateTime(2026, 2, 6, 23, 45, 30);
    expect(localDay(dt), '2026-02-06');
    expect(startOfLocalDay(dt), DateTime(2026, 2, 6));
    expect(endOfLocalDay(dt), DateTime(2026, 2, 7).subtract(const Duration(milliseconds: 1)));
    expect(dayAtNoon(dt).hour, 12);
  });
}
