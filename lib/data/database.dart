import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ── Tables ───────────────────────────────────────────────────────────────────

/// A menstrual cycle record. endedOn is null while the period is ongoing.
class Cycles extends Table {
  IntColumn get id        => integer().autoIncrement()();
  DateTimeColumn get startedOn => dateTime()();
  DateTimeColumn get endedOn   => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One log entry per calendar day.
/// flow: 'none' | 'light' | 'medium' | 'heavy'
/// moods / symptoms: JSON-encoded List<String>
class DailyLogs extends Table {
  IntColumn  get id       => integer().autoIncrement()();
  /// Stored as midnight UTC of that day for unique-per-day constraint.
  DateTimeColumn get date => dateTime().unique()();
  TextColumn get flow     => text().withDefault(const Constant('none'))();
  TextColumn get moods    => text().withDefault(const Constant('[]'))();
  TextColumn get symptoms => text().withDefault(const Constant('[]'))();
  TextColumn get notes    => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Simple key-value store for user preferences.
class AppSettings extends Table {
  TextColumn get settingKey   => text()();
  TextColumn get settingValue => text()();

  @override
  Set<Column> get primaryKey => {settingKey};
}

// ── DAO ──────────────────────────────────────────────────────────────────────

@DriftAccessor(tables: [Cycles, DailyLogs, AppSettings])
class AppDao extends DatabaseAccessor<AppDatabase> with _$AppDaoMixin {
  AppDao(super.db);

  // ── Cycles ────────────────────────────────────────────────────────────────

  Stream<List<Cycle>> watchAllCycles() =>
      (select(cycles)
        ..orderBy([(t) => OrderingTerm.desc(t.startedOn)]))
          .watch();

  Future<List<Cycle>> getAllCycles() =>
      (select(cycles)
        ..orderBy([(t) => OrderingTerm.desc(t.startedOn)]))
          .get();

  Future<Cycle?> getActiveCycle() =>
      (select(cycles)
        ..where((t) => t.endedOn.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.startedOn)])
        ..limit(1))
          .getSingleOrNull();

  Future<int> startCycle(DateTime startedOn) => into(cycles).insert(
      CyclesCompanion.insert(startedOn: _dayOnly(startedOn)));

  Future<bool> endCycle(int id, DateTime endedOn) =>
      (update(cycles)..where((t) => t.id.equals(id)))
          .write(CyclesCompanion(endedOn: Value(_dayOnly(endedOn))))
          .then((n) => n > 0);

  Future<int> deleteCycle(int id) =>
      (delete(cycles)..where((t) => t.id.equals(id))).go();

  // ── Daily logs ────────────────────────────────────────────────────────────

  Stream<List<DailyLog>> watchLogsForMonth(DateTime month) {
    final start = DateTime.utc(month.year, month.month, 1);
    final end   = DateTime.utc(month.year, month.month + 1, 0, 23, 59, 59);
    return (select(dailyLogs)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<DailyLog?> getLogForDate(DateTime date) {
    final d = _dayOnly(date);
    return (select(dailyLogs)..where((t) => t.date.equals(d)))
        .getSingleOrNull();
  }

  Future<void> upsertLog(DailyLogsCompanion log) =>
      into(dailyLogs).insertOnConflictUpdate(log);

  Future<int> deleteLog(int id) =>
      (delete(dailyLogs)..where((t) => t.id.equals(id))).go();

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)
          ..where((t) => t.settingKey.equals(key)))
        .getSingleOrNull();
    return row?.settingValue;
  }

  Future<void> setSetting(String key, String value) =>
      into(appSettings).insertOnConflictUpdate(AppSettingsCompanion(
          settingKey:   Value(key),
          settingValue: Value(value)));

  Future<int?> getIntSetting(String key, {int? fallback}) async {
    final v = await getSetting(key);
    return v != null ? int.tryParse(v) : fallback;
  }

  Future<void> setIntSetting(String key, int value) =>
      setSetting(key, value.toString());
}

// ── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Cycles, DailyLogs, AppSettings], daos: [AppDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() =>
      driftDatabase(name: 'imoon');
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Strips the time component, returning midnight UTC of the given date.
DateTime _dayOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
