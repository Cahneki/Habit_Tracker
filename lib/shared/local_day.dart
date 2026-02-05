DateTime startOfLocalDay(DateTime dt) {
  return DateTime(dt.year, dt.month, dt.day);
}

DateTime endOfLocalDay(DateTime dt) {
  return DateTime(dt.year, dt.month, dt.day + 1).subtract(
    const Duration(milliseconds: 1),
  );
}

DateTime dayAtNoon(DateTime dt) {
  return DateTime(dt.year, dt.month, dt.day, 12);
}

String localDay(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
