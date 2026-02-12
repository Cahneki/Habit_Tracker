import 'package:flutter/material.dart';

import '../../db/app_db.dart';
import '../../shared/local_day.dart';
import '../quests/quests_view_model.dart';
import '../quests/widgets/quest_list_tile.dart';
import '../quests/widgets/quests_search_and_filters.dart';
import '../quests/widgets/quests_section.dart';
import '../quests/widgets/quests_skeleton.dart';
import '../quests/widgets/quests_summary_strip.dart';
import 'habit_detail_page.dart';
import 'habit_editor_page.dart';
import 'habit_repository.dart';
import 'schedule_picker.dart';

class HabitsManagePage extends StatefulWidget {
  const HabitsManagePage({
    super.key,
    required this.repo,
    required this.dataVersion,
    required this.onDataChanged,
  });

  final HabitRepository repo;
  final ValueNotifier<int> dataVersion;
  final VoidCallback onDataChanged;

  @override
  State<HabitsManagePage> createState() => _HabitsManagePageState();
}

class _HabitsManageVm {
  const _HabitsManageVm({
    required this.activeItems,
    required this.archivedItems,
    required this.summary,
  });

  final List<QuestUiItem> activeItems;
  final List<QuestUiItem> archivedItems;
  final QuestsSummaryCounts summary;

  bool get isEmpty => activeItems.isEmpty && archivedItems.isEmpty;

  bool get hasScheduledActive => activeItems.any((q) => !q.isBacklog);

  List<QuestUiItem> get allItems => [...activeItems, ...archivedItems];
}

class _HabitsManagePageState extends State<HabitsManagePage> {
  late Future<_HabitsManageVm> _future;
  late final VoidCallback _dataListener;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  final Set<QuestQuickFilter> _quickFilters = <QuestQuickFilter>{};
  final Set<String> _selectedIds = <String>{};
  final Map<QuestSectionKey, bool> _sectionExpanded = <QuestSectionKey, bool>{
    QuestSectionKey.archived: false,
  };

  QuestSummaryFilter? _summaryFilter;
  QuestSortMode _sortMode = QuestSortMode.nextDue;

  bool get _selectionMode => _selectedIds.isNotEmpty;

  bool get _hasActiveFilterState {
    return _searchController.text.trim().isNotEmpty ||
        _quickFilters.isNotEmpty ||
        _summaryFilter != null;
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
    _dataListener = _refresh;
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    widget.dataVersion.addListener(_dataListener);
  }

  @override
  void dispose() {
    widget.dataVersion.removeListener(_dataListener);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<_HabitsManageVm> _load() async {
    final now = DateTime.now();
    final activeHabits = await widget.repo.listActiveHabits();
    final archivedHabits = await widget.repo.listArchivedHabits();

    final allHabits = <Habit>[...activeHabits, ...archivedHabits];
    if (allHabits.isEmpty) {
      return const _HabitsManageVm(
        activeItems: <QuestUiItem>[],
        archivedItems: <QuestUiItem>[],
        summary: QuestsSummaryCounts(
          active: 0,
          scheduledToday: 0,
          atRisk: 0,
          backlog: 0,
          archived: 0,
        ),
      );
    }

    final streakById = await widget.repo.getStreakStatsForHabits(allHabits);
    final weekStart = startOfLocalDay(
      now,
    ).subtract(Duration(days: now.weekday - DateTime.monday));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final completionByHabit = await widget.repo
        .getCompletionDaysForRangeByHabit(
          weekStart,
          weekEnd,
          habitIds: allHabits.map((h) => h.id).toList(),
        );

    final activeItems = <QuestUiItem>[];
    final archivedItems = <QuestUiItem>[];

    for (final entry in activeHabits.asMap().entries) {
      final idx = entry.key;
      final habit = entry.value;
      final streak =
          streakById[habit.id] ??
          const StreakStats(
            current: 0,
            longest: 0,
            totalCompletions: 0,
            lastLocalDay: null,
            completedToday: false,
          );
      activeItems.add(
        QuestsViewModel.fromHabit(
          habit: habit,
          streak: streak,
          isArchived: false,
          now: now,
          completionDaysThisWeek:
              completionByHabit[habit.id] ?? const <String>{},
          manualOrder: idx,
        ),
      );
    }

    for (final entry in archivedHabits.asMap().entries) {
      final idx = entry.key;
      final habit = entry.value;
      final streak =
          streakById[habit.id] ??
          const StreakStats(
            current: 0,
            longest: 0,
            totalCompletions: 0,
            lastLocalDay: null,
            completedToday: false,
          );
      archivedItems.add(
        QuestsViewModel.fromHabit(
          habit: habit,
          streak: streak,
          isArchived: true,
          now: now,
          completionDaysThisWeek:
              completionByHabit[habit.id] ?? const <String>{},
          manualOrder: activeHabits.length + idx,
        ),
      );
    }

    final summary = QuestsViewModel.computeSummary(
      active: activeItems,
      archived: archivedItems,
    );

    return _HabitsManageVm(
      activeItems: activeItems,
      archivedItems: archivedItems,
      summary: summary,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
      _selectedIds.clear();
    });
  }

  Future<HabitEditorResult?> _showHabitEditor({Habit? habit, String? draftId}) {
    return Navigator.of(context).push<HabitEditorResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => HabitEditorPage(habit: habit, draftId: draftId),
      ),
    );
  }

  Future<void> _createHabit() async {
    final id = 'h-${DateTime.now().millisecondsSinceEpoch}';
    final result = await _showHabitEditor(draftId: id);
    if (result == null) return;
    if (result.action != HabitEditorAction.save) return;
    if (result.name.isEmpty || result.days.isEmpty) return;

    final scheduleMask = ScheduleMask.maskFromDays(result.days);
    await widget.repo.createHabit(
      id: id,
      name: result.name,
      scheduleMask: scheduleMask,
      timeOfDay: result.timeOfDay,
      iconId: result.iconId,
      iconPath: result.iconPath,
    );
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _editHabit(Habit habit) async {
    final result = await _showHabitEditor(habit: habit);
    if (result == null) return;
    if (result.action == HabitEditorAction.archive) {
      await _archiveHabit(habit);
      return;
    }
    if (result.action != HabitEditorAction.save) return;

    if (result.name.trim() != habit.name) {
      await widget.repo.renameHabit(habit.id, result.name.trim());
    }
    final nextMask = ScheduleMask.maskFromDays(result.days);
    if (nextMask != habit.scheduleMask) {
      await widget.repo.updateScheduleMask(habit.id, nextMask);
    }
    if (result.timeOfDay != habit.timeOfDay) {
      await widget.repo.updateTimeOfDay(habit.id, result.timeOfDay);
    }
    if (result.iconId != habit.iconId || result.iconPath != habit.iconPath) {
      if (result.iconId == 'custom') {
        await widget.repo.updateHabitCustomIcon(habit.id, result.iconPath);
      } else {
        await widget.repo.updateHabitIcon(habit.id, result.iconId);
      }
    }

    _refresh();
    widget.onDataChanged();
  }

  Future<void> _archiveHabit(Habit habit) async {
    await widget.repo.archiveHabit(habit.id);
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _restoreHabit(Habit habit) async {
    await widget.repo.unarchiveHabit(habit.id);
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete quest?'),
        content: const Text('This removes the quest and its history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await widget.repo.deleteHabit(habit.id);
    _refresh();
    widget.onDataChanged();
  }

  void _onToggleQuickFilter(QuestQuickFilter filter) {
    setState(() {
      if (filter == QuestQuickFilter.all) {
        _quickFilters.clear();
        return;
      }
      if (_quickFilters.contains(filter)) {
        _quickFilters.remove(filter);
      } else {
        _quickFilters.add(filter);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _summaryFilter = null;
      _quickFilters.clear();
      _searchController.clear();
    });
  }

  void _toggleSection(QuestSectionKey key) {
    final current = _sectionExpanded[key] ?? (key != QuestSectionKey.archived);
    setState(() {
      _sectionExpanded[key] = !current;
    });
  }

  bool _isSectionExpanded(QuestSectionKey key) {
    return _sectionExpanded[key] ?? (key != QuestSectionKey.archived);
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _bulkArchive(_HabitsManageVm vm) async {
    final selectedItems = vm.allItems.where(
      (q) => _selectedIds.contains(q.habit.id),
    );
    var changed = false;
    for (final item in selectedItems) {
      if (item.isArchived) continue;
      await widget.repo.archiveHabit(item.habit.id);
      changed = true;
    }
    if (!changed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active quests selected to archive.')),
      );
      return;
    }

    _refresh();
    widget.onDataChanged();
  }

  Future<void> _bulkDelete(_HabitsManageVm vm) async {
    final selectedItems = vm.allItems
        .where((q) => _selectedIds.contains(q.habit.id))
        .toList();
    if (selectedItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete selected quests?'),
        content: Text(
          'This will delete ${selectedItems.length} quest(s) and history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    for (final item in selectedItems) {
      await widget.repo.deleteHabit(item.habit.id);
    }
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _showSortSheet() async {
    final selection = await showModalBottomSheet<QuestSortMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        Widget tile(QuestSortMode mode, String label) {
          final selected = _sortMode == mode;
          return ListTile(
            title: Text(label),
            trailing: selected ? const Icon(Icons.check_rounded) : null,
            onTap: () => Navigator.of(context).pop(mode),
          );
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              tile(QuestSortMode.nextDue, 'Next due'),
              tile(QuestSortMode.urgency, 'Urgency/At risk'),
              tile(QuestSortMode.xpReward, 'XP reward'),
              tile(QuestSortMode.az, 'A–Z'),
              tile(QuestSortMode.recentlyEdited, 'Recently edited'),
            ],
          ),
        );
      },
    );

    if (selection != null) {
      setState(() {
        _sortMode = selection;
      });
    }
  }

  Future<void> _openDetail(QuestUiItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitDetailPage(
          repo: widget.repo,
          habit: item.habit,
          onDataChanged: widget.onDataChanged,
        ),
      ),
    );
    _refresh();
    widget.onDataChanged();
  }

  Future<void> _handleSwipeComplete(QuestUiItem item) async {
    if (item.isArchived || !item.isScheduledToday) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completion is only available for today\'s quests.'),
        ),
      );
      return;
    }
    if (item.isCompletedToday) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Already completed today.')));
      return;
    }

    await widget.repo.toggleCompletionForDay(item.habit.id, DateTime.now());
    _refresh();
    widget.onDataChanged();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Marked complete for today.')));
  }

  Future<void> _showSwipeActions(QuestUiItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.snooze_rounded),
                title: const Text('Snooze'),
                onTap: () => Navigator.of(context).pop('snooze'),
              ),
              ListTile(
                leading: const Icon(Icons.more_horiz_rounded),
                title: const Text('More'),
                onTap: () => Navigator.of(context).pop('more'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    if (action == 'snooze') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TODO: snooze behavior wiring.')),
      );
      return;
    }
    if (action == 'more') {
      await _showItemActions(item);
    }
  }

  Future<void> _showItemActions(QuestUiItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!item.isArchived)
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Edit'),
                  onTap: () => Navigator.of(context).pop('edit'),
                ),
              ListTile(
                leading: const Icon(Icons.pause_circle_rounded),
                title: Text(item.isArchived ? 'Resume (TODO)' : 'Pause (TODO)'),
                onTap: () => Navigator.of(context).pop('pause'),
              ),
              if (!item.isArchived)
                ListTile(
                  leading: const Icon(Icons.archive_rounded),
                  title: const Text('Archive'),
                  onTap: () => Navigator.of(context).pop('archive'),
                ),
              if (item.isArchived)
                ListTile(
                  leading: const Icon(Icons.unarchive_rounded),
                  title: const Text('Restore'),
                  onTap: () => Navigator.of(context).pop('restore'),
                ),
              ListTile(
                leading: const Icon(Icons.delete_rounded),
                title: const Text('Delete'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'edit':
        await _editHabit(item.habit);
        break;
      case 'pause':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TODO: Pause/Resume requires data model support.'),
          ),
        );
        break;
      case 'archive':
        await _archiveHabit(item.habit);
        break;
      case 'restore':
        await _restoreHabit(item.habit);
        break;
      case 'delete':
        await _deleteHabit(item.habit);
        break;
    }
  }

  List<QuestUiItem> _visibleItems(_HabitsManageVm vm) {
    final filtered = vm.allItems.where((item) {
      if (!QuestsViewModel.matchesSearch(item, _searchController.text)) {
        return false;
      }
      if (!QuestsViewModel.matchesSummary(item, _summaryFilter)) {
        return false;
      }
      if (!QuestsViewModel.matchesQuickFilters(item, _quickFilters)) {
        return false;
      }
      return true;
    }).toList();

    return QuestsViewModel.sortItems(filtered, _sortMode);
  }

  List<Widget> _buildSectionRows(
    BuildContext context,
    List<QuestUiItem> items,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return items
        .map(
          (item) => Dismissible(
            key: ValueKey('quest-${item.habit.id}-${item.isArchived}'),
            direction: DismissDirection.horizontal,
            confirmDismiss: (direction) async {
              if (_selectionMode) return false;
              if (direction == DismissDirection.startToEnd) {
                await _handleSwipeComplete(item);
                return false;
              }
              await _showSwipeActions(item);
              return false;
            },
            background: Container(
              color: scheme.primary.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.check_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Complete',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            secondaryBackground: Container(
              color: scheme.secondary.withValues(alpha: 0.16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Actions',
                    style: TextStyle(
                      color: scheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.more_horiz_rounded, color: scheme.secondary),
                ],
              ),
            ),
            child: QuestListTile(
              item: item,
              selected: _selectedIds.contains(item.habit.id),
              selectionMode: _selectionMode,
              onTap: () {
                if (_selectionMode) {
                  _toggleSelection(item.habit.id);
                  return;
                }
                _openDetail(item);
              },
              onLongPress: () => _toggleSelection(item.habit.id),
              onOverflow: () => _showItemActions(item),
            ),
          ),
        )
        .toList();
  }

  Widget _selectionTopBar(_HabitsManageVm vm) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          tooltip: 'Cancel selection',
          onPressed: () => setState(() => _selectedIds.clear()),
          icon: const Icon(Icons.close_rounded),
        ),
        Text(
          '${_selectedIds.length} selected',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Archive selected',
          onPressed: () => _bulkArchive(vm),
          icon: Icon(Icons.archive_rounded, color: scheme.primary),
        ),
        IconButton(
          tooltip: 'Delete selected',
          onPressed: () => _bulkDelete(vm),
          icon: Icon(Icons.delete_rounded, color: scheme.error),
        ),
      ],
    );
  }

  Widget _standardTopBar() {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Quests',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          tooltip: 'Search',
          onPressed: () => _searchFocusNode.requestFocus(),
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: 'Sort & filters',
          onPressed: _showSortSheet,
          icon: const Icon(Icons.filter_list_rounded),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            if (value == 'clear') {
              _clearFilters();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'clear',
              child: Text(
                'Clear filters',
                style: TextStyle(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-quests',
        onPressed: _createHabit,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<_HabitsManageVm>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const QuestsSkeleton();
          }

          final vm = snap.data!;

          final visible = _visibleItems(vm);
          final grouped = QuestsViewModel.groupBySection(visible);

          final sectionOrder = [
            QuestSectionKey.today,
            QuestSectionKey.morning,
            QuestSectionKey.afternoon,
            QuestSectionKey.evening,
            QuestSectionKey.anytime,
            QuestSectionKey.backlog,
            QuestSectionKey.archived,
          ];

          final showNoResults = !vm.isEmpty && visible.isEmpty;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
              children: [
                _selectionMode ? _selectionTopBar(vm) : _standardTopBar(),
                const SizedBox(height: 10),
                QuestsSummaryStrip(
                  counts: vm.summary,
                  activeFilter: _summaryFilter,
                  onSelectFilter: (next) => setState(() {
                    _summaryFilter = next;
                    _selectedIds.clear();
                  }),
                  showClear: _hasActiveFilterState,
                  onClear: _clearFilters,
                ),
                const SizedBox(height: 10),
                QuestsSearchAndFilters(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (_) => setState(() {}),
                  activeFilters: _quickFilters,
                  onToggleFilter: _onToggleQuickFilter,
                  showClear: _hasActiveFilterState,
                  onClearFilters: _clearFilters,
                ),
                const SizedBox(height: 12),
                if (vm.isEmpty)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No quests yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first quest to start planning your week.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _createHabit,
                            child: const Text('Create your first quest'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (showNoResults)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No quests match your search and filter combination.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  if (!vm.hasScheduledActive && !_hasActiveFilterState)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Schedule quests to appear on Today.',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...sectionOrder.map((sectionKey) {
                    final items = grouped[sectionKey] ?? const <QuestUiItem>[];
                    if (items.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: QuestsSection(
                        title: QuestsViewModel.sectionTitle(sectionKey),
                        count: items.length,
                        expanded: _isSectionExpanded(sectionKey),
                        onToggle: () => _toggleSection(sectionKey),
                        children: _buildSectionRows(context, items),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
