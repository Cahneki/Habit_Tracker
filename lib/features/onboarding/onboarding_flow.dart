import 'package:flutter/material.dart';

import '../../shared/habit_icons.dart';
import '../habits/habit_repository.dart';
import '../habits/schedule_picker.dart';
import '../settings/settings_repository.dart';

const Color _kOnboardingBg = Color(0xFF0F1115);
const Color _kOnboardingCard = Color(0xFF1A1D23);
const Color _kOnboardingSurface = Color(0xFF242833);

enum OnboardingExperience { novice, adept, veteran }

enum OnboardingArchetype { warrior, rogue, mage }

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.repo,
    required this.settingsRepo,
    required this.onCompleted,
  });

  final HabitRepository repo;
  final SettingsRepository settingsRepo;
  final VoidCallback onCompleted;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _StarterQuestDraft {
  const _StarterQuestDraft({
    required this.id,
    required this.title,
    required this.description,
    required this.xp,
    required this.durationMinutes,
    required this.iconId,
    required this.timeOfDay,
    required this.days,
    required this.isCustom,
  });

  final String id;
  final String title;
  final String description;
  final int xp;
  final int durationMinutes;
  final String iconId;
  final String timeOfDay;
  final Set<int> days;
  final bool isCustom;

  _StarterQuestDraft copyWith({
    String? title,
    String? description,
    int? xp,
    int? durationMinutes,
    String? iconId,
    String? timeOfDay,
    Set<int>? days,
    bool? isCustom,
  }) {
    return _StarterQuestDraft(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      xp: xp ?? this.xp,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      iconId: iconId ?? this.iconId,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      days: days ?? this.days,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

class _QuestTemplate {
  const _QuestTemplate({
    required this.title,
    required this.description,
    required this.baseXp,
    required this.minutes,
    required this.iconId,
    required this.timeOfDay,
  });

  final String title;
  final String description;
  final int baseXp;
  final int minutes;
  final String iconId;
  final String timeOfDay;
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;
  bool _busy = false;

  OnboardingExperience? _experience;
  final Set<String> _focusTags = <String>{};
  OnboardingArchetype? _archetype;
  List<_StarterQuestDraft> _quests = const <_StarterQuestDraft>[];

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final settings = await widget.settingsRepo.getSettings();
    final exp = OnboardingExperience.values.where(
      (e) => e.name == settings.experienceLevel,
    );
    final arch = OnboardingArchetype.values.where(
      (a) => a.name == settings.archetype,
    );
    final focus = settings.focusTags
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toSet();
    if (!mounted) return;
    setState(() {
      _experience = exp.isEmpty ? null : exp.first;
      _archetype = arch.isEmpty ? null : arch.first;
      _focusTags
        ..clear()
        ..addAll(focus);
    });
  }

  void _next() {
    setState(() {
      _step = (_step + 1).clamp(0, 5);
    });
  }

  void _back() {
    setState(() {
      _step = (_step - 1).clamp(0, 5);
    });
  }

  Future<void> _setExperience(OnboardingExperience value) async {
    setState(() => _experience = value);
    await widget.settingsRepo.setExperienceLevel(value.name);
  }

  Future<void> _toggleFocusTag(String tag) async {
    if (_focusTags.contains(tag)) {
      setState(() => _focusTags.remove(tag));
      await widget.settingsRepo.setFocusTags(_focusTags.toList());
      return;
    }
    if (_focusTags.length >= 2) return;
    setState(() => _focusTags.add(tag));
    await widget.settingsRepo.setFocusTags(_focusTags.toList());
  }

  Future<void> _setArchetype(OnboardingArchetype value) async {
    setState(() => _archetype = value);
    await widget.settingsRepo.setArchetype(value.name);
  }

  void _prepareQuests() {
    if (_experience == null) return;
    final generated = _generateStarterQuests(
      experience: _experience!,
      focusTags: _focusTags.toList(),
    );
    setState(() => _quests = generated);
  }

  List<_StarterQuestDraft> _generateStarterQuests({
    required OnboardingExperience experience,
    required List<String> focusTags,
  }) {
    const templatesByFocus = <String, List<_QuestTemplate>>{
      'Fitness': [
        _QuestTemplate(
          title: 'Morning Mobility',
          description: 'Loosen up with light movement.',
          baseXp: 20,
          minutes: 12,
          iconId: 'run',
          timeOfDay: 'morning',
        ),
        _QuestTemplate(
          title: 'Strength Circuit',
          description: 'Bodyweight set to build momentum.',
          baseXp: 28,
          minutes: 20,
          iconId: 'lift',
          timeOfDay: 'afternoon',
        ),
      ],
      'Productivity': [
        _QuestTemplate(
          title: 'Deep Work Sprint',
          description: 'Single-task your top priority.',
          baseXp: 25,
          minutes: 25,
          iconId: 'focus',
          timeOfDay: 'morning',
        ),
        _QuestTemplate(
          title: 'Inbox Zero Pass',
          description: 'Clear and triage your backlog.',
          baseXp: 18,
          minutes: 15,
          iconId: 'scroll',
          timeOfDay: 'afternoon',
        ),
      ],
      'Mental': [
        _QuestTemplate(
          title: 'Breathing Reset',
          description: 'Calm your mind before the grind.',
          baseXp: 18,
          minutes: 10,
          iconId: 'meditate',
          timeOfDay: 'morning',
        ),
        _QuestTemplate(
          title: 'Evening Reflection',
          description: 'Capture wins and lessons.',
          baseXp: 16,
          minutes: 10,
          iconId: 'potion',
          timeOfDay: 'evening',
        ),
      ],
      'Learning': [
        _QuestTemplate(
          title: 'Study Session',
          description: 'Focused learning block.',
          baseXp: 24,
          minutes: 25,
          iconId: 'read',
          timeOfDay: 'evening',
        ),
        _QuestTemplate(
          title: 'Skill Drill',
          description: 'Practice one key concept.',
          baseXp: 22,
          minutes: 20,
          iconId: 'code',
          timeOfDay: 'afternoon',
        ),
      ],
      'Discipline': [
        _QuestTemplate(
          title: 'Hydration Check',
          description: 'Stay fueled through the day.',
          baseXp: 14,
          minutes: 5,
          iconId: 'water',
          timeOfDay: 'anytime',
        ),
        _QuestTemplate(
          title: 'Sleep Winddown',
          description: 'Power down and prepare for recovery.',
          baseXp: 20,
          minutes: 15,
          iconId: 'sleep',
          timeOfDay: 'evening',
        ),
      ],
    };

    const fallback = <_QuestTemplate>[
      _QuestTemplate(
        title: 'Quest Planning',
        description: 'Set your top objective for the day.',
        baseXp: 16,
        minutes: 10,
        iconId: 'quest',
        timeOfDay: 'morning',
      ),
      _QuestTemplate(
        title: 'Focus Block',
        description: 'Guard one uninterrupted work block.',
        baseXp: 22,
        minutes: 20,
        iconId: 'focus',
        timeOfDay: 'afternoon',
      ),
      _QuestTemplate(
        title: 'Recovery Ritual',
        description: 'Wrap your day with intention.',
        baseXp: 18,
        minutes: 12,
        iconId: 'camp',
        timeOfDay: 'evening',
      ),
      _QuestTemplate(
        title: 'Daily Reading',
        description: 'Read for growth and clarity.',
        baseXp: 20,
        minutes: 15,
        iconId: 'read',
        timeOfDay: 'anytime',
      ),
      _QuestTemplate(
        title: 'Movement Break',
        description: 'Keep your body active and alert.',
        baseXp: 18,
        minutes: 10,
        iconId: 'run',
        timeOfDay: 'afternoon',
      ),
    ];

    final templates = <_QuestTemplate>[];
    for (final tag in focusTags) {
      final group = templatesByFocus[tag];
      if (group == null || group.isEmpty) continue;
      templates.add(group.first);
    }
    for (final item in fallback) {
      if (templates.any((q) => q.title == item.title)) continue;
      templates.add(item);
    }

    final count = switch (experience) {
      OnboardingExperience.novice => 3,
      OnboardingExperience.adept => 4,
      OnboardingExperience.veteran => 5,
    };
    final mult = switch (experience) {
      OnboardingExperience.novice => 0.9,
      OnboardingExperience.adept => 1.0,
      OnboardingExperience.veteran => 1.15,
    };
    final scheduleDays = switch (experience) {
      OnboardingExperience.novice => <int>{0, 2, 4},
      OnboardingExperience.adept => <int>{0, 1, 2, 4, 5},
      OnboardingExperience.veteran => <int>{0, 1, 2, 3, 4, 5},
    };

    return List<_StarterQuestDraft>.generate(count, (index) {
      final source = templates[index % templates.length];
      final xp = (source.baseXp * mult).round();
      final minutes = (source.minutes * (1 + (mult - 1) * 0.6)).round();
      return _StarterQuestDraft(
        id: 'seed-$index',
        title: source.title,
        description: source.description,
        xp: xp,
        durationMinutes: minutes,
        iconId: source.iconId,
        timeOfDay: source.timeOfDay,
        days: scheduleDays,
        isCustom: false,
      );
    });
  }

  Future<void> _upsertQuestDialog({_StarterQuestDraft? source}) async {
    final titleCtl = TextEditingController(text: source?.title ?? '');
    final descCtl = TextEditingController(text: source?.description ?? '');
    final minsCtl = TextEditingController(
      text: source == null ? '15' : '${source.durationMinutes}',
    );
    final xpCtl = TextEditingController(
      text: source == null ? '20' : '${source.xp}',
    );
    final next = await showDialog<_StarterQuestDraft>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _kOnboardingCard,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: const TextStyle(color: Colors.white70),
          title: Text(source == null ? 'Add Custom Quest' : 'Edit Quest'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minsCtl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minutes'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: xpCtl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'XP Reward'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            FilledButton(
              onPressed: () {
                final title = titleCtl.text.trim();
                if (title.isEmpty) return;
                final minutes = int.tryParse(minsCtl.text.trim()) ?? 10;
                final xp = int.tryParse(xpCtl.text.trim()) ?? 15;
                Navigator.of(context).pop(
                  _StarterQuestDraft(
                    id:
                        source?.id ??
                        'custom-${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    description: descCtl.text.trim().isEmpty
                        ? 'Custom quest'
                        : descCtl.text.trim(),
                    xp: xp.clamp(5, 120),
                    durationMinutes: minutes.clamp(5, 180),
                    iconId: source?.iconId ?? 'quest',
                    timeOfDay: source?.timeOfDay ?? 'anytime',
                    days: source?.days ?? <int>{0, 1, 2, 3, 4},
                    isCustom: true,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _kOnboardingSurface,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (!mounted || next == null) return;
    setState(() {
      if (source == null) {
        _quests = [..._quests, next];
      } else {
        _quests = _quests.map((q) => q.id == source.id ? next : q).toList();
      }
    });
  }

  Future<void> _seedStarterHabitsIfNeeded() async {
    final settings = await widget.settingsRepo.getSettings();
    if (settings.starterHabitsSeeded) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < _quests.length; i++) {
      final quest = _quests[i];
      await widget.repo.createHabit(
        id: 'h-onb-$now-$i',
        name: quest.title,
        scheduleMask: ScheduleMask.maskFromDays(quest.days),
        baseXp: quest.xp,
        iconId: quest.iconId,
        timeOfDay: quest.timeOfDay,
      );
    }
    await widget.settingsRepo.setStarterHabitsSeeded(true);
  }

  Future<void> _complete() async {
    if (_busy || _experience == null || _archetype == null || _quests.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    await widget.settingsRepo.setExperienceLevel(_experience!.name);
    await widget.settingsRepo.setFocusTags(_focusTags.toList());
    await widget.settingsRepo.setArchetype(_archetype!.name);
    await _seedStarterHabitsIfNeeded();
    await widget.settingsRepo.setOnboardingCompleted(true);
    if (!mounted) return;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final current = switch (_step) {
      0 => _AwakeningStep(onBegin: _next),
      1 => _SelfAssessmentStep(
        selected: _experience,
        onSelected: _setExperience,
        onContinue: _experience == null ? null : _next,
        onBack: _back,
      ),
      2 => _AlignmentStep(
        selectedTags: _focusTags,
        onToggle: _toggleFocusTag,
        onContinue: _next,
        onBack: _back,
      ),
      3 => _PathSelectionStep(
        selected: _archetype,
        onSelected: _setArchetype,
        onContinue: _archetype == null
            ? null
            : () {
                _prepareQuests();
                _next();
              },
        onBack: _back,
      ),
      4 => _FirstQuestsStep(
        quests: _quests,
        onBack: _back,
        onContinue: _quests.isEmpty ? null : _next,
        onEdit: _upsertQuestDialog,
        onRemove: (id) {
          setState(() {
            _quests = _quests.where((q) => q.id != id).toList();
          });
        },
        onAddCustom: _quests.any((q) => q.isCustom)
            ? null
            : () => _upsertQuestDialog(),
      ),
      _ => _OathStep(
        archetype: _archetype,
        questCount: _quests.length,
        busy: _busy,
        onBack: _back,
        onEnter: _complete,
      ),
    };

    return Scaffold(
      backgroundColor: _kOnboardingBg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: KeyedSubtree(key: ValueKey(_step), child: current),
        ),
      ),
    );
  }
}

class _AwakeningStep extends StatelessWidget {
  const _AwakeningStep({required this.onBegin});

  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kOnboardingSurface,
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 72,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Awakening',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Forge your path and begin your first campaign.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onBegin,
              style: FilledButton.styleFrom(
                backgroundColor: _kOnboardingSurface,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Begin Journey'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfAssessmentStep extends StatelessWidget {
  const _SelfAssessmentStep({
    required this.selected,
    required this.onSelected,
    required this.onContinue,
    required this.onBack,
  });

  final OnboardingExperience? selected;
  final ValueChanged<OnboardingExperience> onSelected;
  final VoidCallback? onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const items = <(OnboardingExperience, String, String, String)>[
      (
        OnboardingExperience.novice,
        'Novice',
        'Start with simple repeatable wins.',
        '15–25 min/day',
      ),
      (
        OnboardingExperience.adept,
        'Adept',
        'Balanced challenge and steady pace.',
        '30–45 min/day',
      ),
      (
        OnboardingExperience.veteran,
        'Veteran',
        'High-intensity progression track.',
        '45–70 min/day',
      ),
    ];

    return _OnboardingStepScaffold(
      title: 'Self Assessment',
      subtitle: 'Choose your starting pace.',
      onBack: onBack,
      ctaLabel: 'Continue',
      onContinue: onContinue,
      child: Column(
        children: items.map((entry) {
          final active = selected == entry.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 140),
              scale: active ? 1.02 : 1.0,
              child: InkWell(
                onTap: () => onSelected(entry.$1),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kOnboardingCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active
                          ? Colors.cyanAccent.withValues(alpha: 0.7)
                          : Colors.white24,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.2),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.$3,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.$4,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AlignmentStep extends StatelessWidget {
  const _AlignmentStep({
    required this.selectedTags,
    required this.onToggle,
    required this.onContinue,
    required this.onBack,
  });

  final Set<String> selectedTags;
  final ValueChanged<String> onToggle;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const tags = [
      'Fitness',
      'Productivity',
      'Mental',
      'Learning',
      'Discipline',
    ];

    return _OnboardingStepScaffold(
      title: 'Alignment',
      subtitle: 'Pick up to 2 focus areas.',
      onBack: onBack,
      ctaLabel: 'Continue',
      onContinue: onContinue,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.8,
        ),
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final label = tags[index];
          final selected = selectedTags.contains(label);
          final disabled = !selected && selectedTags.length >= 2;
          return Opacity(
            opacity: disabled ? 0.55 : 1,
            child: InkWell(
              onTap: disabled ? null : () => onToggle(label),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kOnboardingCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? Colors.cyanAccent.withValues(alpha: 0.8)
                        : Colors.white24,
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PathSelectionStep extends StatelessWidget {
  const _PathSelectionStep({
    required this.selected,
    required this.onSelected,
    required this.onContinue,
    required this.onBack,
  });

  final OnboardingArchetype? selected;
  final ValueChanged<OnboardingArchetype> onSelected;
  final VoidCallback? onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const items = <(OnboardingArchetype, String, String, Color, List<double>)>[
      (
        OnboardingArchetype.warrior,
        'Warrior',
        'Relentless focus through strength and grit.',
        Color(0xFFB94E4E),
        [0.85, 0.55, 0.45],
      ),
      (
        OnboardingArchetype.rogue,
        'Rogue',
        'Fast adaptation and precision execution.',
        Color(0xFF3FA8A2),
        [0.6, 0.8, 0.65],
      ),
      (
        OnboardingArchetype.mage,
        'Mage',
        'Mastery through knowledge and consistency.',
        Color(0xFF8B63D9),
        [0.5, 0.6, 0.88],
      ),
    ];

    return _OnboardingStepScaffold(
      title: 'Path Selection',
      subtitle: 'Choose your archetype.',
      onBack: onBack,
      ctaLabel: 'Continue',
      onContinue: onContinue,
      child: Column(
        children: items.map((entry) {
          final active = selected == entry.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onSelected(entry.$1),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kOnboardingCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active
                        ? entry.$4.withValues(alpha: 0.9)
                        : Colors.white24,
                    width: active ? 1.6 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.$2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.$3,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    ...entry.$5.map(
                      (v) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            color: entry.$4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FirstQuestsStep extends StatelessWidget {
  const _FirstQuestsStep({
    required this.quests,
    required this.onBack,
    required this.onContinue,
    required this.onEdit,
    required this.onRemove,
    required this.onAddCustom,
  });

  final List<_StarterQuestDraft> quests;
  final VoidCallback onBack;
  final VoidCallback? onContinue;
  final Future<void> Function({_StarterQuestDraft? source}) onEdit;
  final ValueChanged<String> onRemove;
  final VoidCallback? onAddCustom;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = quests.fold<int>(
      0,
      (sum, q) => sum + q.durationMinutes,
    );
    final totalXp = quests.fold<int>(0, (sum, q) => sum + q.xp);

    return _OnboardingStepScaffold(
      title: 'First Quests',
      subtitle: 'Starter quests forged from your choices.',
      onBack: onBack,
      ctaLabel: 'Continue',
      onContinue: onContinue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kOnboardingSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(
                  'Daily time: ${totalMinutes}m',
                  style: const TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                Text(
                  'Potential XP: +$totalXp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...quests.map((quest) {
            final icon = iconForHabit(quest.iconId, quest.title);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kOnboardingCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _kOnboardingSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white70, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                quest.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '+${quest.xp} XP',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${quest.durationMinutes} min',
                          style: const TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quest.description,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => onEdit(source: quest),
                    icon: const Icon(Icons.edit_rounded, color: Colors.white70),
                  ),
                  IconButton(
                    onPressed: () => onRemove(quest.id),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (onAddCustom != null)
            OutlinedButton.icon(
              onPressed: onAddCustom,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add custom quest'),
            ),
        ],
      ),
    );
  }
}

class _OathStep extends StatelessWidget {
  const _OathStep({
    required this.archetype,
    required this.questCount,
    required this.busy,
    required this.onBack,
    required this.onEnter,
  });

  final OnboardingArchetype? archetype;
  final int questCount;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final archetypeLabel = switch (archetype) {
      OnboardingArchetype.warrior => 'Warrior',
      OnboardingArchetype.rogue => 'Rogue',
      OnboardingArchetype.mage => 'Mage',
      null => 'Unchosen',
    };

    return _OnboardingStepScaffold(
      title: 'Oath',
      subtitle: 'Seal your setup and enter the realm.',
      onBack: onBack,
      ctaLabel: busy ? 'Preparing...' : 'Enter the Realm',
      onContinue: busy ? null : onEnter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kOnboardingCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Archetype: $archetypeLabel',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Level 1', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(
              'Quest count: $questCount',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                value: 0,
                minHeight: 8,
                backgroundColor: Colors.white12,
                color: Colors.cyanAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStepScaffold extends StatelessWidget {
  const _OnboardingStepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.ctaLabel,
    required this.onContinue,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String ctaLabel;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
            ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Expanded(child: SingleChildScrollView(child: child)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: _kOnboardingSurface,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}
