import 'package:flutter/foundation.dart';

import '../../data/daily_actions/daily_free_action_model.dart';
import '../../data/daily_actions/daily_free_action_repository.dart';
import '../../data/daily_intent/daily_intent_model.dart';
import '../../data/daily_intent/daily_intent_repository.dart';

class TodayViewModel extends ChangeNotifier {
  TodayViewModel({
    required DailyIntentRepository dailyIntentRepository,
    required DailyFreeActionRepository dailyFreeActionRepository,
  }) : _dailyIntentRepository = dailyIntentRepository,
       _dailyFreeActionRepository = dailyFreeActionRepository;

  final DailyIntentRepository _dailyIntentRepository;
  final DailyFreeActionRepository _dailyFreeActionRepository;

  bool _loadingIntent = false;
  bool _savingIntent = false;
  bool _loadingFreeActions = false;
  final Set<DailyFreeActionType> _savingFreeActions = <DailyFreeActionType>{};
  Object? _intentError;
  Object? _freeActionsError;
  DailyIntentSelection? _todayIntent;
  DailyIntentType? _pendingIntent;
  List<DailyFreeActionRecord> _todayFreeActions = const [];

  bool get loadingIntent => _loadingIntent;
  bool get savingIntent => _savingIntent;
  bool get loadingFreeActions => _loadingFreeActions;
  bool get anyFreeActionSaving => _savingFreeActions.isNotEmpty;
  Set<DailyFreeActionType> get savingFreeActions =>
      Set<DailyFreeActionType>.unmodifiable(_savingFreeActions);
  bool isSavingFreeAction(DailyFreeActionType action) =>
      _savingFreeActions.contains(action);
  Object? get intentError => _intentError;
  Object? get freeActionsError => _freeActionsError;
  DailyIntentSelection? get todayIntent => _todayIntent;
  DailyIntentType? get pendingIntent => _pendingIntent;
  List<DailyFreeActionRecord> get todayFreeActions => _todayFreeActions;
  Set<DailyFreeActionType> get completedFreeActions =>
      _todayFreeActions.map((record) => record.actionType).toSet();
  DailyIntentType? get selectedIntentType => _todayIntent?.intent;
  bool get hasSelectedIntent => _todayIntent != null;
  bool get intentLocked => _todayIntent != null;

  Future<void> loadTodayState() async {
    await Future.wait([loadTodayIntent(), loadTodayFreeActions()]);
  }

  Future<void> loadTodayIntent() async {
    _loadingIntent = true;
    _intentError = null;
    notifyListeners();
    try {
      _todayIntent = await _dailyIntentRepository.getForDate(DateTime.now());
    } catch (error) {
      _intentError = error;
    } finally {
      _loadingIntent = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayFreeActions() async {
    _loadingFreeActions = true;
    _freeActionsError = null;
    notifyListeners();
    try {
      _todayFreeActions = await _dailyFreeActionRepository.listForDate(
        DateTime.now(),
      );
    } catch (error) {
      _freeActionsError = error;
    } finally {
      _loadingFreeActions = false;
      notifyListeners();
    }
  }

  Future<void> selectIntent(DailyIntentType intent) async {
    if (intentLocked) return;
    _savingIntent = true;
    _pendingIntent = intent;
    _intentError = null;
    notifyListeners();
    try {
      await _dailyIntentRepository.setForDate(DateTime.now(), intent);
      _todayIntent = await _dailyIntentRepository.getForDate(DateTime.now());
    } catch (error) {
      _intentError = error;
    } finally {
      _savingIntent = false;
      _pendingIntent = null;
      notifyListeners();
    }
  }

  Future<bool> performFreeAction(DailyFreeActionType action) async {
    if (!hasSelectedIntent) return false;
    if (completedFreeActions.contains(action)) return false;

    _savingFreeActions.add(action);
    _freeActionsError = null;
    notifyListeners();
    try {
      final performed = await _dailyFreeActionRepository.performForDate(
        DateTime.now(),
        action,
      );
      if (performed) {
        _todayFreeActions = await _dailyFreeActionRepository.listForDate(
          DateTime.now(),
        );
      }
      return performed;
    } catch (error) {
      _freeActionsError = error;
      return false;
    } finally {
      _savingFreeActions.remove(action);
      notifyListeners();
    }
  }

  Future<void> clearTodayIntentForDebug() async {
    await _dailyIntentRepository.clearForDate(DateTime.now());
    await loadTodayIntent();
  }

  Future<void> clearTodayFreeActionsForDebug() async {
    await _dailyFreeActionRepository.clearForDate(DateTime.now());
    await loadTodayFreeActions();
  }
}
