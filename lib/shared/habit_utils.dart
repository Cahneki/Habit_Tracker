import '../features/habits/schedule_picker.dart';

bool isDailySchedule(int? mask) {
  return mask == null || mask == 0x7f;
}

String formatScheduleSummary(int? mask) {
  if (mask == null) return 'Schedule: daily';
  if (mask == 0) return 'Schedule: none';
  if (mask == 0x7f) return 'Schedule: daily';

  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final days = ScheduleMask.daysFromMask(mask).toList()..sort();
  final short = days.map((i) => labels[i]).join(' ');
  return 'Schedule: $short';
}
