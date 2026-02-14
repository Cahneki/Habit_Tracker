import 'package:flutter/material.dart';

import '../../db/app_db.dart';
import '../../shared/habit_icons.dart';
import '../../shared/local_day.dart';
import '../quests/quests_view_model.dart';
import '../quests/widgets/quests_skeleton.dart';
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

  final Set<String> _selectedIds = <String>{};
  final Map<QuestSectionKey, bool> _sectionExpanded = <QuestSectionKey, bool>{
    QuestSectionKey.today: true,
    QuestSectionKey.morning: false,
    QuestSectionKey.afternoon: false,
    QuestSectionKey.archived: false,
  };
  bool _searchExpanded = false;
  bool _selectionMode = false;

  QuestSummaryFilter? _summaryFilter = QuestSummaryFilter.scheduledToday;
  QuestSortMode _sortMode = QuestSortMode.nextDue;

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
      _selectionMode = false;
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

  void _clearFilters() {
    setState(() {
      _summaryFilter = null;
      _searchController.clear();
      _searchExpanded = false;
    });
  }

  void _collapseSearch({bool clear = false}) {
    if (!_searchExpanded) return;
    setState(() {
      _searchExpanded = false;
      if (clear) {
        _searchController.clear();
      }
    });
    _searchFocusNode.unfocus();
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

  void _enterSelectionMode() {
    _collapseSearch();
    setState(() {
      _selectionMode = true;
      _selectedIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  bool _allVisibleSelected(List<QuestUiItem> visible) {
    if (visible.isEmpty) return false;
    for (final item in visible) {
      if (!_selectedIds.contains(item.habit.id)) {
        return false;
      }
    }
    return true;
  }

  void _toggleSelectAllVisible(List<QuestUiItem> visible) {
    if (visible.isEmpty) return;
    setState(() {
      final allSelected = _allVisibleSelected(visible);
      if (allSelected) {
        for (final item in visible) {
          _selectedIds.remove(item.habit.id);
        }
      } else {
        for (final item in visible) {
          _selectedIds.add(item.habit.id);
        }
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
    if (mounted) {
      _exitSelectionMode();
    }
  }

  Future<void> _bulkPause(_HabitsManageVm vm) async {
    final selectedCount = vm.allItems
        .where((q) => _selectedIds.contains(q.habit.id))
        .length;
    if (selectedCount == 0) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pause for $selectedCount quest(s) is not available yet.',
        ),
      ),
    );
    _exitSelectionMode();
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
    if (mounted) {
      _exitSelectionMode();
    }
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

  Future<void> _showItemActions(QuestUiItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
      return true;
    }).toList();

    return QuestsViewModel.sortItems(filtered, _sortMode);
  }

  List<Widget> _buildSectionRows(
    BuildContext context,
    List<QuestUiItem> items,
  ) {
    return items
        .map(
          (item) => _QuestCardTile(
            item: item,
            selected: _selectedIds.contains(item.habit.id),
            selectionMode: _selectionMode,
            onTap: () {
              if (_selectionMode) {
                _toggleSelection(item.habit.id);
                return;
              }
              _editHabit(item.habit);
            },
            onLongPress: _selectionMode
                ? () => _toggleSelection(item.habit.id)
                : null,
            onOverflow: () => _showItemActions(item),
            onChevron: () => _editHabit(item.habit),
          ),
        )
        .toList();
  }

  Widget _selectionTopBar(List<QuestUiItem> visible) {
    final allVisibleSelected = _allVisibleSelected(visible);
    return Row(
      children: [
        TextButton(
          onPressed: _exitSelectionMode,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Select quests',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: visible.isEmpty
              ? null
              : () => _toggleSelectAllVisible(visible),
          child: Text(allVisibleSelected ? 'Deselect all' : 'Select all'),
        ),
      ],
    );
  }

  Widget _standardTopBar(_HabitsManageVm vm) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Quests',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _searchExpanded
              ? SizedBox(
                  key: const ValueKey('header-search'),
                  width: 220,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (_) => setState(() {}),
                          onTapOutside: (_) => _collapseSearch(),
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search',
                            isDense: true,
                            filled: true,
                            fillColor: scheme.surfaceContainerLowest.withValues(
                              alpha: 0.45,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.trim().isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close search',
                        onPressed: () => _collapseSearch(clear: true),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                )
              : Row(
                  key: const ValueKey('header-actions'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Search',
                      onPressed: () {
                        setState(() {
                          _searchExpanded = true;
                        });
                        _searchFocusNode.requestFocus();
                      },
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
                        if (value == 'select') {
                          _enterSelectionMode();
                          return;
                        }
                        if (value == 'archived') {
                          setState(() {
                            _summaryFilter = QuestSummaryFilter.archived;
                            _sectionExpanded[QuestSectionKey.archived] = true;
                          });
                          return;
                        }
                        if (value == 'active') {
                          setState(() {
                            _summaryFilter = QuestSummaryFilter.scheduledToday;
                          });
                          return;
                        }
                        if (value == 'clear') {
                          _clearFilters();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'select',
                          child: Text(
                            'Select quests',
                            style: TextStyle(color: scheme.onSurface),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: _summaryFilter == QuestSummaryFilter.archived
                              ? 'active'
                              : 'archived',
                          child: Text(
                            _summaryFilter == QuestSummaryFilter.archived
                                ? 'View Active'
                                : 'View Archived (${vm.summary.archived})',
                            style: TextStyle(color: scheme.onSurface),
                          ),
                        ),
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
                ),
        ),
      ],
    );
  }

  Widget _statusChip({
    required String label,
    required int count,
    required QuestSummaryFilter filter,
  }) {
    final selected = _summaryFilter == filter;
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      selected: selected,
      onSelected: (nextSelected) {
        setState(() {
          _summaryFilter = nextSelected ? filter : null;
          if (_summaryFilter != QuestSummaryFilter.archived) {
            _sectionExpanded[QuestSectionKey.today] = true;
          }
        });
      },
      side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              color: selected
                  ? scheme.onPrimary.withValues(alpha: 0.8)
                  : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryChipsRow(_HabitsManageVm vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statusChip(
            label: 'Active',
            count: vm.summary.active,
            filter: QuestSummaryFilter.active,
          ),
          const SizedBox(width: 8),
          _statusChip(
            label: 'Today',
            count: vm.summary.scheduledToday,
            filter: QuestSummaryFilter.scheduledToday,
          ),
          const SizedBox(width: 8),
          _statusChip(
            label: 'At Risk',
            count: vm.summary.atRisk,
            filter: QuestSummaryFilter.atRisk,
          ),
          const SizedBox(width: 8),
          _statusChip(
            label: 'Backlog',
            count: vm.summary.backlog,
            filter: QuestSummaryFilter.backlog,
          ),
        ],
      ),
    );
  }

  Widget _selectionActionsBar(_HabitsManageVm vm) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _bulkPause(vm),
                icon: const Icon(Icons.pause_circle_outline_rounded),
                label: const Text('Pause'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _bulkArchive(vm),
                icon: const Icon(Icons.archive_rounded),
                label: const Text('Archive'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: () => _bulkDelete(vm),
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _selectionMode
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: FloatingActionButton(
                  heroTag: 'fab-quests',
                  tooltip: 'Add Quest',
                  onPressed: _createHabit,
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  child: const Icon(Icons.add),
                ),
              ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: dark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.surfaceContainerLowest.withValues(alpha: 0.75),
                      scheme.surface,
                    ],
                  )
                : null,
          ),
          child: FutureBuilder<_HabitsManageVm>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const QuestsSkeleton();
              }

              final vm = snap.data!;
              final visible = _visibleItems(vm);
              final grouped = QuestsViewModel.groupBySection(visible);
              final todayItems =
                  grouped[QuestSectionKey.today] ?? const <QuestUiItem>[];
              final morningItems =
                  grouped[QuestSectionKey.morning] ?? const <QuestUiItem>[];
              final laterItems = <QuestUiItem>[
                ...(grouped[QuestSectionKey.afternoon] ?? const <QuestUiItem>[]),
                ...(grouped[QuestSectionKey.evening] ?? const <QuestUiItem>[]),
                ...(grouped[QuestSectionKey.anytime] ?? const <QuestUiItem>[]),
                ...(grouped[QuestSectionKey.backlog] ?? const <QuestUiItem>[]),
              ];
              final archivedItems =
                  grouped[QuestSectionKey.archived] ?? const <QuestUiItem>[];

              final showSelectionActions =
                  _selectionMode && _selectedIds.isNotEmpty;
              final archivedView = _summaryFilter == QuestSummaryFilter.archived;
              final showNoResults = !vm.isEmpty && visible.isEmpty;
              final showTodayEmpty =
                  !vm.isEmpty &&
                  !archivedView &&
                  _summaryFilter == QuestSummaryFilter.scheduledToday &&
                  _searchController.text.trim().isEmpty &&
                  todayItems.isEmpty;
              final selectableVisible = <QuestUiItem>[
                if (archivedView &&
                    _isSectionExpanded(QuestSectionKey.archived)) ...archivedItems,
                if (!archivedView) ...[
                  if (todayItems.isNotEmpty &&
                      _isSectionExpanded(QuestSectionKey.today)) ...todayItems,
                  if (morningItems.isNotEmpty &&
                      _isSectionExpanded(QuestSectionKey.morning))
                    ...morningItems,
                  if (laterItems.isNotEmpty &&
                      _isSectionExpanded(QuestSectionKey.afternoon))
                    ...laterItems,
                ],
              ];

              return SafeArea(
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      color: _selectionMode
                          ? scheme.scrim.withValues(alpha: 0.06)
                          : Colors.transparent,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          showSelectionActions ? 188 : 120,
                        ),
                        children: [
                          _selectionMode
                              ? _selectionTopBar(selectableVisible)
                              : _standardTopBar(vm),
                          if (!vm.isEmpty) ...[
                            const SizedBox(height: 12),
                            _primaryChipsRow(vm),
                          ],
                          const SizedBox(height: 6),
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
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _createHabit,
                                      child: const Text(
                                        'Create your first quest',
                                      ),
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
                                      'No quests match your current filters.',
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
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
                            if (showTodayEmpty)
                              Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'No quests scheduled today',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'You can add a quest now or switch filters to review other quests.',
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton(
                                        onPressed: _createHabit,
                                        child: const Text('Add quest'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (archivedView)
                              _QuestSectionCard(
                                title: 'Archived',
                                count: archivedItems.length,
                                expanded: _isSectionExpanded(
                                  QuestSectionKey.archived,
                                ),
                                selectionMode: _selectionMode,
                                onToggle: () =>
                                    _toggleSection(QuestSectionKey.archived),
                                children: _buildSectionRows(
                                  context,
                                  archivedItems,
                                ),
                              )
                            else ...[
                              if (todayItems.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _QuestSectionCard(
                                    title: 'Today',
                                    count: todayItems.length,
                                    expanded: _isSectionExpanded(
                                      QuestSectionKey.today,
                                    ),
                                    selectionMode: _selectionMode,
                                    onToggle: () =>
                                        _toggleSection(QuestSectionKey.today),
                                    children: _buildSectionRows(
                                      context,
                                      todayItems,
                                    ),
                                  ),
                                ),
                              if (morningItems.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _QuestSectionCard(
                                    title: 'Morning',
                                    count: morningItems.length,
                                    expanded: _isSectionExpanded(
                                      QuestSectionKey.morning,
                                    ),
                                    selectionMode: _selectionMode,
                                    onToggle: () =>
                                        _toggleSection(QuestSectionKey.morning),
                                    children: _buildSectionRows(
                                      context,
                                      morningItems,
                                    ),
                                  ),
                                ),
                              if (laterItems.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _QuestSectionCard(
                                    title: 'Later',
                                    count: laterItems.length,
                                    expanded: _isSectionExpanded(
                                      QuestSectionKey.afternoon,
                                    ),
                                    selectionMode: _selectionMode,
                                    onToggle: () =>
                                        _toggleSection(
                                          QuestSectionKey.afternoon,
                                        ),
                                    children: _buildSectionRows(
                                      context,
                                      laterItems,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    if (showSelectionActions)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _selectionActionsBar(vm),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuestSectionCard extends StatelessWidget {
  const _QuestSectionCard({
    required this.title,
    required this.count,
    required this.expanded,
    required this.selectionMode,
    required this.onToggle,
    required this.children,
  });

  final String title;
  final int count;
  final bool expanded;
  final bool selectionMode;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: selectionMode ? 0 : 1.2,
      color: scheme.surfaceContainerLow.withValues(
        alpha: selectionMode ? 0.84 : 0.92,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      expanded ? title : '$title ($count)',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(children: children),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _QuestCardTile extends StatelessWidget {
  const _QuestCardTile({
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onOverflow,
    required this.onChevron,
  });

  final QuestUiItem item;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onOverflow;
  final VoidCallback onChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final leadingIcon = iconForHabit(item.habit.iconId, item.habit.name);
    final background = selected
        ? scheme.primary.withValues(alpha: 0.18)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.88);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: background,
      elevation: selectionMode ? 0 : 1.2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(left: 2, right: 6),
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => onTap(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: scheme.surface.withValues(alpha: 0.55),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    leadingIcon,
                    size: 17,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.scheduleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!selectionMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'More',
                      onPressed: onOverflow,
                      icon: const Icon(Icons.more_horiz_rounded),
                    ),
                    IconButton(
                      tooltip: 'Edit quest',
                      onPressed: onChevron,
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
