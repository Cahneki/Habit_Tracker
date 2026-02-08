import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../db/app_db.dart';
import '../../shared/habit_icons.dart';
import '../../theme/app_theme.dart';
import 'schedule_picker.dart';

enum HabitFrequency { daily, weekly, custom }

enum HabitEditorAction { save, archive }

class HabitEditorResult {
  const HabitEditorResult({
    required this.action,
    required this.name,
    required this.days,
    required this.timeOfDay,
    required this.iconId,
    required this.iconPath,
  });

  final HabitEditorAction action;
  final String name;
  final Set<int> days;
  final String timeOfDay;
  final String iconId;
  final String iconPath;
}

class HabitEditorPage extends StatefulWidget {
  const HabitEditorPage({
    super.key,
    this.habit,
    this.draftId,
  });

  final Habit? habit;
  final String? draftId;

  @override
  State<HabitEditorPage> createState() => _HabitEditorPageState();
}

class _HabitEditorPageState extends State<HabitEditorPage> {
  late final TextEditingController _controller;
  late Set<int> _selectedDays;
  late HabitFrequency _frequency;
  String _timeOfDay = 'morning';
  late String _iconId;
  late String _iconPath;
  late final String _draftId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.habit?.name ?? '');
    _selectedDays = widget.habit == null
        ? <int>{0, 1, 2, 3, 4, 5, 6}
        : ScheduleMask.daysFromMask(widget.habit!.scheduleMask);
    _timeOfDay = widget.habit?.timeOfDay ?? 'morning';
    _iconId = widget.habit?.iconId ?? 'magic';
    _iconPath = widget.habit?.iconPath ?? '';
    _draftId = widget.habit?.id ??
        widget.draftId ??
        'draft-${DateTime.now().millisecondsSinceEpoch}';
    _frequency = _selectedDays.length == 7
        ? HabitFrequency.daily
        : HabitFrequency.custom;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.habit != null;

  void _setFrequency(HabitFrequency next) {
    setState(() {
      _frequency = next;
      if (next == HabitFrequency.daily) {
        _selectedDays = <int>{0, 1, 2, 3, 4, 5, 6};
      }
    });
  }

  void _toggleDay(int day) {
    setState(() {
      if (_frequency == HabitFrequency.daily) {
        _frequency = HabitFrequency.custom;
      }
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _setTimeOfDay(String value) {
    setState(() => _timeOfDay = value);
  }

  Future<void> _pickCustomIcon() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(path);
    final targetDir = p.join(dir.path, 'custom_icons');
    await Directory(targetDir).create(recursive: true);
    final targetPath = p.join(targetDir, '$_draftId$ext');
    await File(path).copy(targetPath);
    if (!mounted) return;
    setState(() {
      _iconId = 'custom';
      _iconPath = targetPath;
    });
  }

  Future<void> _pickIcon() async {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<GameTokens>()!;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose icon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: habitIconOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final option = habitIconOptions[index];
                    final isSelected = _iconId == option.id;
                    final color = toneColor(option.tone, scheme, tokens);
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context, option.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? scheme.primary : scheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(option.icon, color: color),
                            const SizedBox(height: 6),
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == _iconId) return;
    if (selected == 'custom') {
      await _pickCustomIcon();
      return;
    }
    setState(() {
      _iconId = selected;
      _iconPath = '';
    });
  }

  Widget _iconPreview() {
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<GameTokens>()!;
    final icon = iconForHabit(_iconId, _controller.text);
    final color = iconColorForHabit(_iconId, _controller.text, scheme, tokens);
    final path = _iconPath.trim();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      child: path.isNotEmpty && _iconId == 'custom'
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(icon, color: color),
              ),
            )
          : Icon(icon, color: color),
    );
  }

  int get _xpReward => widget.habit?.baseXp ?? 20;

  int get _goldReward => 10;

  bool get _canSave {
    if (_controller.text.trim().isEmpty) return false;
    if (_isEditing) return true;
    return _selectedDays.isNotEmpty;
  }

  Widget _sectionLabel(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        fontSize: 12,
      ),
    );
  }

  Widget _pill(String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _frequencyToggle() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget item(String label, HabitFrequency value) {
      final selected = _frequency == value;
      return Expanded(
        child: InkWell(
          onTap: () => _setFrequency(value),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? scheme.surfaceContainerHigh : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                label,
                style: textTheme.titleSmall?.copyWith(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          item('Daily', HabitFrequency.daily),
          item('Weekly', HabitFrequency.weekly),
          item('Custom', HabitFrequency.custom),
        ],
      ),
    );
  }

  Widget _dayChip(String label, int dayIndex) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedDays.contains(dayIndex);
    final border = selected ? scheme.primary : scheme.outline;
    final textColor = selected ? scheme.onSurface : scheme.onSurfaceVariant;

    return InkWell(
      onTap: () => _toggleDay(dayIndex),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: border, width: 2),
          color: scheme.surface,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _timeCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _timeOfDay == value;

    return Expanded(
      child: InkWell(
        onTap: () => _setTimeOfDay(value),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? scheme.surfaceContainerHigh : scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bountyReward() {
    final scheme = Theme.of(context).colorScheme;
    final xp = _xpReward;
    final gold = _goldReward;

    Widget rewardItem({
      required IconData icon,
      required String value,
      required Color color,
    }) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BOUNTY REWARD',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              rewardItem(
                icon: Icons.bolt_rounded,
                value: '$xp XP',
                color: scheme.primary,
              ),
              const SizedBox(width: 20),
              rewardItem(
                icon: Icons.monetization_on_rounded,
                value: '$gold GOLD',
                color: scheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedCount = _selectedDays.length;
    final dayLabels = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'EDIT QUEST' : 'ADD QUEST',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionLabel('Quest Title'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Drink Water',
                suffixIcon: InkWell(
                  onTap: _pickIcon,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _iconPreview(),
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 56,
                  minHeight: 56,
                ),
              ),
              autofocus: !_isEditing,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            _sectionLabel('Frequency'),
            const SizedBox(height: 12),
            _frequencyToggle(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('Active Days'),
                _pill('$selectedCount/7 SELECTED'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(dayLabels.length, (i) {
                return _dayChip(dayLabels[i], i == 0 ? 6 : i - 1);
              }),
            ),
            const SizedBox(height: 24),
            _sectionLabel('Time of Day'),
            const SizedBox(height: 12),
            Row(
              children: [
                _timeCard(
                  label: 'Morning',
                  value: 'morning',
                  icon: Icons.wb_twilight_rounded,
                ),
                const SizedBox(width: 12),
                _timeCard(
                  label: 'Afternoon',
                  value: 'afternoon',
                  icon: Icons.wb_sunny_rounded,
                ),
                const SizedBox(width: 12),
                _timeCard(
                  label: 'Evening',
                  value: 'evening',
                  icon: Icons.nights_stay_rounded,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _bountyReward(),
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _canSave
                    ? () {
                        Navigator.pop(
                          context,
                          HabitEditorResult(
                            action: HabitEditorAction.save,
                            name: _controller.text.trim(),
                            days: Set<int>.from(_selectedDays),
                            timeOfDay: _timeOfDay,
                            iconId: _iconId,
                            iconPath: _iconId == 'custom' ? _iconPath : '',
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text('SAVE QUEST'),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      HabitEditorResult(
                        action: HabitEditorAction.archive,
                        name: _controller.text.trim(),
                        days: Set<int>.from(_selectedDays),
                        timeOfDay: _timeOfDay,
                        iconId: _iconId,
                        iconPath: _iconId == 'custom' ? _iconPath : '',
                      ),
                    );
                  },
                  child: const Text('CAST ASIDE'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
