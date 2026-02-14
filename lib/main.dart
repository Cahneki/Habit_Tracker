import 'package:flutter/material.dart';
import 'db/app_db.dart';
import 'features/avatar/avatar_page.dart';
import 'features/avatar/avatar_repository.dart';
import 'features/battles/battle_rewards_repository.dart';
import 'features/battles/battles_page.dart';
import 'features/habits/habit_repository.dart';
import 'features/habits/habits_manage_page.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/settings/settings_page.dart';
import 'features/settings/settings_repository.dart';
import 'features/today/today_page.dart';
import 'services/audio_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.db});

  final AppDb? db;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const Duration _splashMinDuration = Duration(milliseconds: 1400);

  late final AppDb db;
  late final bool _ownsDb;
  late final HabitRepository repo;
  late final SettingsRepository settingsRepo;
  late final AvatarRepository avatarRepo;
  late final BattleRewardsRepository battleRewardsRepo;
  late final AudioService audio;
  late final Future<void> _startupFuture;
  UserSetting? _settings;

  @override
  void initState() {
    super.initState();
    if (widget.db != null) {
      db = widget.db!;
      _ownsDb = false;
    } else {
      db = AppDb();
      _ownsDb = true;
    }
    repo = HabitRepository(db);
    settingsRepo = SettingsRepository(db);
    avatarRepo = AvatarRepository(db);
    battleRewardsRepo = BattleRewardsRepository(db);
    audio = AudioService(settingsRepo);
    _startupFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    final start = DateTime.now();
    _settings = await settingsRepo.getSettings();
    if (mounted) {
      setState(() {});
    }
    final elapsed = DateTime.now().difference(start);
    if (elapsed < _splashMinDuration) {
      await Future<void>.delayed(_splashMinDuration - elapsed);
    }
  }

  void _refreshThemeFromSettings() {
    settingsRepo.getSettings().then((next) {
      if (!mounted) return;
      setState(() {
        _settings = next;
      });
    });
  }

  @override
  void dispose() {
    if (_ownsDb) {
      db.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeId = _settings?.themeId ?? 'light';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeForId(themeId),
      home: FutureBuilder<void>(
        future: _startupFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const _StartupSplashScreen();
          }
          if (_settings?.onboardingCompleted != true) {
            return OnboardingFlow(
              repo: repo,
              settingsRepo: settingsRepo,
              onCompleted: _refreshThemeFromSettings,
            );
          }
          return HomeScaffold(
            repo: repo,
            settingsRepo: settingsRepo,
            avatarRepo: avatarRepo,
            battleRewardsRepo: battleRewardsRepo,
            audio: audio,
            onThemeChanged: _refreshThemeFromSettings,
          );
        },
      ),
    );
  }
}

class _StartupSplashScreen extends StatelessWidget {
  const _StartupSplashScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.surfaceContainerLowest, scheme.surface],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.14),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: scheme.primary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Habit Tracker',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 132,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: scheme.surfaceContainerHigh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({
    super.key,
    required this.repo,
    required this.settingsRepo,
    required this.avatarRepo,
    required this.battleRewardsRepo,
    required this.audio,
    required this.onThemeChanged,
  });

  final HabitRepository repo;
  final SettingsRepository settingsRepo;
  final AvatarRepository avatarRepo;
  final BattleRewardsRepository battleRewardsRepo;
  final AudioService audio;
  final VoidCallback onThemeChanged;

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _index = 0;
  final ValueNotifier<int> _dataVersion = ValueNotifier(0);

  void _setIndex(int next) {
    setState(() {
      _index = next;
    });
  }

  void _notifyDataChanged() {
    _dataVersion.value++;
  }

  @override
  void dispose() {
    _dataVersion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayPage(
        repo: widget.repo,
        audio: widget.audio,
        avatarRepo: widget.avatarRepo,
        settingsRepo: widget.settingsRepo,
        dataVersion: _dataVersion,
        onDataChanged: _notifyDataChanged,
        onOpenHabits: () => _setIndex(1),
        onOpenBattles: () => _setIndex(2),
      ),
      HabitsManagePage(
        repo: widget.repo,
        dataVersion: _dataVersion,
        onDataChanged: _notifyDataChanged,
      ),
      BattlesPage(
        repo: widget.repo,
        avatarRepo: widget.avatarRepo,
        rewardsRepo: widget.battleRewardsRepo,
        dataVersion: _dataVersion,
        onDataChanged: _notifyDataChanged,
      ),
      AvatarPage(
        repo: widget.repo,
        avatarRepo: widget.avatarRepo,
        audio: widget.audio,
        settingsRepo: widget.settingsRepo,
        dataVersion: _dataVersion,
        onDataChanged: _notifyDataChanged,
      ),
      SettingsPage(
        settingsRepo: widget.settingsRepo,
        audio: widget.audio,
        habitRepo: widget.repo,
        avatarRepo: widget.avatarRepo,
        dataVersion: _dataVersion,
        onDataChanged: () {
          _notifyDataChanged();
          widget.onThemeChanged();
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _setIndex,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Quests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_martial_arts_rounded),
            label: 'Battles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_rounded),
            label: 'Avatar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
