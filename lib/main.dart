import 'package:flutter/material.dart';
import 'db/app_db.dart';
import 'features/habits/habit_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppDb db;
  late final HabitRepository repo;

  bool loading = true;
  bool completedToday = false;

  @override
  void initState() {
    super.initState();
    db = AppDb();
    repo = HabitRepository(db);
    _init();
  }

  Future<void> _init() async {
    await repo.seedOneHabitIfEmpty();
    completedToday = await repo.isCompletedToday('habit-1');
    setState(() => loading = false);
  }

  Future<void> _complete() async {
    await repo.completeHabit('habit-1');
    completedToday = await repo.isCompletedToday('habit-1');
    setState(() {});
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Habit Tracker')),
        body: Center(
          child: loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(completedToday ? 'Completed today' : 'Not completed today'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: completedToday ? null : _complete,
                      child: const Text('Complete habit'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}