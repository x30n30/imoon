import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imoon/data/database.dart';
import 'package:imoon/logic/cycle_calculator.dart';

// ── Database ──────────────────────────────────────────────────────────────────

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── Cycles ────────────────────────────────────────────────────────────────────

final cyclesProvider = StreamProvider<List<Cycle>>((ref) {
  return ref.watch(dbProvider).appDao.watchAllCycles();
});

// ── Cycle stats ───────────────────────────────────────────────────────────────

final cycleStatsProvider = Provider<CycleStats?>((ref) {
  return ref.watch(cyclesProvider).when(
    data:    (cycles) => CycleCalculator.calculate(cycles, DateTime.now()),
    loading: () => null,
    error:   (_, __) => null,
  );
});

// ── Active cycle ──────────────────────────────────────────────────────────────

final activeCycleProvider = FutureProvider<Cycle?>((ref) {
  return ref.watch(dbProvider).appDao.getActiveCycle();
});

// ── Monthly logs (calendar) ───────────────────────────────────────────────────

final focusedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final monthLogsProvider = StreamProvider<List<DailyLog>>((ref) {
  final month = ref.watch(focusedMonthProvider);
  return ref.watch(dbProvider).appDao.watchLogsForMonth(month);
});

/// Map of dateString → DailyLog for the focused month, for O(1) lookup.
final logMapProvider = Provider<Map<String, DailyLog>>((ref) {
  return ref.watch(monthLogsProvider).when(
    data: (logs) => {for (final l in logs) _dateKey(l.date): l},
    loading: () => {},
    error: (_, __) => {},
  );
});

// ── Settings ──────────────────────────────────────────────────────────────────

final settingsProvider = ChangeNotifierProvider<SettingsNotifier>((ref) {
  return SettingsNotifier(ref.watch(dbProvider).appDao);
});

class SettingsNotifier extends ChangeNotifier {
  final AppDao _dao;
  int reminderDaysBefore = 2;
  bool remindersEnabled  = false;

  SettingsNotifier(this._dao) {
    _load();
  }

  Future<void> _load() async {
    reminderDaysBefore = await _dao.getIntSetting('reminder_days', fallback: 2) ?? 2;
    final r = await _dao.getSetting('reminders_enabled');
    remindersEnabled = r == 'true';
    notifyListeners();
  }

  Future<void> setReminderDays(int days) async {
    reminderDaysBefore = days;
    await _dao.setIntSetting('reminder_days', days);
    notifyListeners();
  }

  Future<void> setRemindersEnabled(bool v) async {
    remindersEnabled = v;
    await _dao.setSetting('reminders_enabled', v.toString());
    notifyListeners();
  }
}

// ── Actions ───────────────────────────────────────────────────────────────────

class CycleActions {
  final AppDao _dao;
  CycleActions(this._dao);

  Future<void> startPeriod() async {
    // Close any open cycle first (safety)
    final active = await _dao.getActiveCycle();
    if (active != null) {
      await _dao.endCycle(active.id, DateTime.now());
    }
    await _dao.startCycle(DateTime.now());
  }

  Future<void> endPeriod(int cycleId) =>
      _dao.endCycle(cycleId, DateTime.now());

  Future<void> deleteCycle(int id) => _dao.deleteCycle(id);

  Future<void> saveLog({
    required DateTime date,
    required String flow,
    required List<String> moods,
    required List<String> symptoms,
    required String notes,
  }) {
    final existing = _dao.getLogForDate(date);
    return existing.then((log) => _dao.upsertLog(DailyLogsCompanion(
      id:       log != null ? Value(log.id) : const Value.absent(),
      date:     Value(DateTime.utc(date.year, date.month, date.day)),
      flow:     Value(flow),
      moods:    Value(jsonEncode(moods)),
      symptoms: Value(jsonEncode(symptoms)),
      notes:    Value(notes),
    )));
  }
}

final cycleActionsProvider = Provider<CycleActions>((ref) {
  return CycleActions(ref.watch(dbProvider).appDao);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
