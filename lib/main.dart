import 'package:flutter/material.dart';
import 'db/app_db.dart';
import 'features/avatar/avatar_page.dart';
import 'features/avatar/avatar_repository.dart';
import 'features/battles/battle_rewards_repository.dart';
import 'features/battles/battles_page.dart';
import 'features/habits/habit_repository.dart';
import 'features/habits/habits_manage_page.dart';
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
  late final AppDb db;
  late final bool _ownsDb;
  late final HabitRepository repo;
  late final SettingsRepository settingsRepo;
  late final AvatarRepository avatarRepo;
  late final BattleRewardsRepository battleRewardsRepo;
  late final AudioService audio;
  late Future<UserSetting> _settingsFuture;

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
    _settingsFuture = settingsRepo.getSettings();
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
    return FutureBuilder<UserSetting>(
      future: _settingsFuture,
      builder: (context, snap) {
        final themeId = snap.data?.themeId ?? 'forest';
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeForId(themeId),
          home: HomeScaffold(
            repo: repo,
            settingsRepo: settingsRepo,
            avatarRepo: avatarRepo,
            battleRewardsRepo: battleRewardsRepo,
            audio: audio,
            onThemeChanged: () {
              setState(() {
                _settingsFuture = settingsRepo.getSettings();
              });
            },
          ),
        );
      },
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
        dataVersion: _dataVersion,
        onDataChanged: _notifyDataChanged,
        onOpenHabits: () => _setIndex(1),
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
        dataVersion: _dataVersion,
        onDataChanged: _notifyDataChanged,
      ),
      SettingsPage(
        settingsRepo: widget.settingsRepo,
        audio: widget.audio,
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
            label: 'Habits',
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
