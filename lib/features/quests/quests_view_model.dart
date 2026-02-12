import '../../db/app_db.dart';
import '../../shared/local_day.dart';
import '../habits/habit_repository.dart';
import '../habits/schedule_picker.dart';

enum QuestQuickFilter {
  all,
  today,
  urgent,
  morning,
  highXp,
  notScheduled,
  archived,
}

enum QuestSortMode { nextDue, urgency, xpReward, az, recentlyEdited }

enum QuestSectionKey {
  today,
  morning,
  afternoon,
  evening,
  anytime,
  backlog,
  archived,
}

enum QuestSummaryFilter { active, scheduledToday, atRisk, backlog, archived }

class QuestUiItem {
  const QuestUiItem({
    required this.habit,
    required this.streak,
    required this.isScheduledToday,
    required this.isCompletedToday,
    required this.isAtRisk,
    required this.isBacklog,
    required this.timeOfDay,
    required this.weekCompleted,
    required this.weekScheduled,
    required this.xpReward,
    required this.nextDueDate,
    required this.scheduleText,
    required this.manualOrder,
    required this.isArchived,
    required this.createdAt,
  });

  final Habit habit;
  final StreakStats streak;
  final bool isScheduledToday;
  final bool isCompletedToday;
  final bool isAtRisk;
  final bool isBacklog;
  final String timeOfDay;
  final int weekCompleted;
  final int weekScheduled;
  final int xpReward;
  final DateTime? nextDueDate;
  final String scheduleText;
  final int manualOrder;
  final bool isArchived;
  final int createdAt;
}

class QuestsSummaryCounts {
  const QuestsSummaryCounts({
    required this.active,
    required this.scheduledToday,
    required this.atRisk,
    required this.backlog,
    required this.archived,
  });

  final int active;
  final int scheduledToday;
  final int atRisk;
  final int backlog;
  final int archived;
}

class QuestsViewModel {
  static QuestUiItem fromHabit({
    required Habit habit,
    required StreakStats streak,
    required bool isArchived,
    required DateTime now,
    required Set<String> completionDaysThisWeek,
    required int manualOrder,
  }) {
    final today = startOfLocalDay(now);
    final todayKey = localDay(today);
    final timeLabel = timeOfDayLabel(habit.timeOfDay);
    final isBacklog = habit.scheduleMask == 0;
    final scheduledToday =
        !isBacklog && _isScheduledOn(today, habit.scheduleMask);
    final completedToday = completionDaysThisWeek.contains(todayKey);

    final weekStart = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekScheduled = isBacklog
        ? 0
        : _countScheduledDaysInRange(habit.scheduleMask, weekStart, weekEnd);
    final weekCompleted = isBacklog
        ? 0
        : _countCompletedInRange(
            habit.scheduleMask,
            completionDaysThisWeek,
            weekStart,
            weekEnd,
          );

    final atRisk =
        !isArchived && scheduledToday && !completedToday && streak.current == 0;

    return QuestUiItem(
      habit: habit,
      streak: streak,
      isScheduledToday: scheduledToday,
      isCompletedToday: completedToday,
      isAtRisk: atRisk,
      isBacklog: isBacklog,
      timeOfDay: habit.timeOfDay,
      weekCompleted: weekCompleted,
      weekScheduled: weekScheduled,
      xpReward: xpRewardFor(streak: streak, scheduleMask: habit.scheduleMask),
      nextDueDate: _nextDueDate(now, habit.scheduleMask),
      scheduleText: humanScheduleText(habit.scheduleMask, timeLabel),
      manualOrder: manualOrder,
      isArchived: isArchived,
      createdAt: habit.createdAt,
    );
  }

  static QuestsSummaryCounts computeSummary({
    required List<QuestUiItem> active,
    required List<QuestUiItem> archived,
  }) {
    final scheduledToday = active.where((q) => q.isScheduledToday).length;
    final atRisk = active.where((q) => q.isAtRisk).length;
    final backlog = active.where((q) => q.isBacklog).length;
    return QuestsSummaryCounts(
      active: active.length,
      scheduledToday: scheduledToday,
      atRisk: atRisk,
      backlog: backlog,
      archived: archived.length,
    );
  }

  static String timeOfDayLabel(String value) {
    switch (value) {
      case 'morning':
        return 'Morning';
      case 'afternoon':
        return 'Afternoon';
      case 'evening':
        return 'Evening';
      default:
        return 'Anytime';
    }
  }

  static String humanScheduleText(int? scheduleMask, String timeLabel) {
    if (scheduleMask == 0) return 'Not scheduled';
    if (scheduleMask == null || scheduleMask == 0x7f) {
      return 'Daily • $timeLabel';
    }
    final days = ScheduleMask.daysFromMask(scheduleMask).toList()..sort();
    final labels = days.map(_weekdayShortLabel).join(', ');
    return '$labels • $timeLabel';
  }

  static bool matchesSearch(QuestUiItem item, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return item.habit.name.toLowerCase().contains(q);
  }

  static bool matchesSummary(
    QuestUiItem item,
    QuestSummaryFilter? summaryFilter,
  ) {
    switch (summaryFilter) {
      case null:
        return true;
      case QuestSummaryFilter.active:
        return !item.isArchived;
      case QuestSummaryFilter.scheduledToday:
        return !item.isArchived && item.isScheduledToday;
      case QuestSummaryFilter.atRisk:
        return !item.isArchived && item.isAtRisk;
      case QuestSummaryFilter.backlog:
        return !item.isArchived && item.isBacklog;
      case QuestSummaryFilter.archived:
        return item.isArchived;
    }
  }

  static bool matchesQuickFilters(
    QuestUiItem item,
    Set<QuestQuickFilter> filters,
  ) {
    if (filters.isEmpty) return true;
    for (final filter in filters) {
      switch (filter) {
        case QuestQuickFilter.all:
          continue;
        case QuestQuickFilter.today:
          if (item.isArchived || !item.isScheduledToday) return false;
          break;
        case QuestQuickFilter.urgent:
          if (!item.isAtRisk) return false;
          break;
        case QuestQuickFilter.morning:
          if (item.timeOfDay != 'morning' || item.isArchived) return false;
          break;
        case QuestQuickFilter.highXp:
          if (item.xpReward < 35) return false;
          break;
        case QuestQuickFilter.notScheduled:
          if (!item.isBacklog || item.isArchived) return false;
          break;
        case QuestQuickFilter.archived:
          if (!item.isArchived) return false;
          break;
      }
    }
    return true;
  }

  static List<QuestUiItem> sortItems(
    List<QuestUiItem> items,
    QuestSortMode mode,
  ) {
    final sorted = List<QuestUiItem>.from(items);
    int compareBase(QuestUiItem a, QuestUiItem b) {
      if (a.isArchived != b.isArchived) {
        return a.isArchived ? 1 : -1;
      }
      return a.manualOrder.compareTo(b.manualOrder);
    }

    switch (mode) {
      case QuestSortMode.nextDue:
        sorted.sort((a, b) {
          if (a.isArchived != b.isArchived) {
            return a.isArchived ? 1 : -1;
          }
          if (a.nextDueDate == null && b.nextDueDate == null) {
            return compareBase(a, b);
          }
          if (a.nextDueDate == null) return 1;
          if (b.nextDueDate == null) return -1;
          final due = a.nextDueDate!.compareTo(b.nextDueDate!);
          if (due != 0) return due;
          return compareBase(a, b);
        });
        break;
      case QuestSortMode.urgency:
        sorted.sort((a, b) {
          final aScore = a.isAtRisk ? 0 : (a.isScheduledToday ? 1 : 2);
          final bScore = b.isAtRisk ? 0 : (b.isScheduledToday ? 1 : 2);
          if (aScore != bScore) return aScore.compareTo(bScore);
          return compareBase(a, b);
        });
        break;
      case QuestSortMode.xpReward:
        sorted.sort((a, b) {
          final xp = b.xpReward.compareTo(a.xpReward);
          if (xp != 0) return xp;
          return compareBase(a, b);
        });
        break;
      case QuestSortMode.az:
        sorted.sort((a, b) {
          final name = a.habit.name.toLowerCase().compareTo(
            b.habit.name.toLowerCase(),
          );
          if (name != 0) return name;
          return compareBase(a, b);
        });
        break;
      case QuestSortMode.recentlyEdited:
        sorted.sort((a, b) {
          final created = b.createdAt.compareTo(a.createdAt);
          if (created != 0) return created;
          return compareBase(a, b);
        });
        break;
    }
    return sorted;
  }

  static Map<QuestSectionKey, List<QuestUiItem>> groupBySection(
    List<QuestUiItem> items,
  ) {
    final sections = <QuestSectionKey, List<QuestUiItem>>{
      QuestSectionKey.today: <QuestUiItem>[],
      QuestSectionKey.morning: <QuestUiItem>[],
      QuestSectionKey.afternoon: <QuestUiItem>[],
      QuestSectionKey.evening: <QuestUiItem>[],
      QuestSectionKey.anytime: <QuestUiItem>[],
      QuestSectionKey.backlog: <QuestUiItem>[],
      QuestSectionKey.archived: <QuestUiItem>[],
    };

    for (final item in items) {
      if (item.isArchived) {
        sections[QuestSectionKey.archived]!.add(item);
        continue;
      }
      if (item.isBacklog) {
        sections[QuestSectionKey.backlog]!.add(item);
        continue;
      }
      if (item.isScheduledToday) {
        sections[QuestSectionKey.today]!.add(item);
        continue;
      }
      switch (item.timeOfDay) {
        case 'morning':
          sections[QuestSectionKey.morning]!.add(item);
          break;
        case 'afternoon':
          sections[QuestSectionKey.afternoon]!.add(item);
          break;
        case 'evening':
          sections[QuestSectionKey.evening]!.add(item);
          break;
        default:
          sections[QuestSectionKey.anytime]!.add(item);
      }
    }

    return sections;
  }

  static String sectionTitle(QuestSectionKey key) {
    switch (key) {
      case QuestSectionKey.today:
        return 'Today';
      case QuestSectionKey.morning:
        return 'Morning';
      case QuestSectionKey.afternoon:
        return 'Afternoon';
      case QuestSectionKey.evening:
        return 'Evening';
      case QuestSectionKey.anytime:
        return 'Anytime';
      case QuestSectionKey.backlog:
        return 'Backlog';
      case QuestSectionKey.archived:
        return 'Archived';
    }
  }

  static int xpRewardFor({
    required StreakStats streak,
    required int? scheduleMask,
  }) {
    var xp = 20;
    if (scheduleMask == null || scheduleMask == 0x7f) {
      xp += 10;
    }
    xp += (streak.current ~/ 5) * 5;
    return xp.clamp(20, 60);
  }

  static DateTime? _nextDueDate(DateTime now, int? scheduleMask) {
    if (scheduleMask == 0) return null;
    final start = startOfLocalDay(now);
    for (var i = 0; i <= 14; i++) {
      final day = start.add(Duration(days: i));
      if (_isScheduledOn(day, scheduleMask)) {
        return day;
      }
    }
    return null;
  }

  static int _countScheduledDaysInRange(
    int? scheduleMask,
    DateTime start,
    DateTime endExclusive,
  ) {
    var count = 0;
    for (
      var d = start;
      d.isBefore(endExclusive);
      d = d.add(const Duration(days: 1))
    ) {
      if (_isScheduledOn(d, scheduleMask)) {
        count += 1;
      }
    }
    return count;
  }

  static int _countCompletedInRange(
    int? scheduleMask,
    Set<String> completionDays,
    DateTime start,
    DateTime endExclusive,
  ) {
    var count = 0;
    for (
      var d = start;
      d.isBefore(endExclusive);
      d = d.add(const Duration(days: 1))
    ) {
      if (!_isScheduledOn(d, scheduleMask)) continue;
      if (completionDays.contains(localDay(d))) {
        count += 1;
      }
    }
    return count;
  }

  static bool _isScheduledOn(DateTime date, int? scheduleMask) {
    if (scheduleMask == null) return true;
    if (scheduleMask == 0) return false;
    final bit = 1 << (date.weekday - 1);
    return (scheduleMask & bit) != 0;
  }

  static String _weekdayShortLabel(int dayIndex) {
    switch (dayIndex) {
      case 0:
        return 'Mon';
      case 1:
        return 'Tue';
      case 2:
        return 'Wed';
      case 3:
        return 'Thu';
      case 4:
        return 'Fri';
      case 5:
        return 'Sat';
      case 6:
        return 'Sun';
      default:
        return '';
    }
  }
}
