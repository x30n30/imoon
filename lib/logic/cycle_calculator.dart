import 'package:imoon/data/database.dart';
import 'package:imoon/theme.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const int kDefaultCycleLength  = 28;
const int kDefaultPeriodLength = 5;
const int kHistoryCount        = 6; // cycles to average over

// ── Stats model ───────────────────────────────────────────────────────────────

class CycleStats {
  final int    cycleDay;         // current day in cycle (1-based)
  final int    avgCycleLength;
  final int    avgPeriodLength;
  final DateTime? nextPeriodDate;
  final DateTime? ovulationDate;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;
  final CyclePhaseUI phase;
  final bool   periodActive;     // a cycle is currently open
  final int?   daysUntilNext;    // null if unknown

  const CycleStats({
    required this.cycleDay,
    required this.avgCycleLength,
    required this.avgPeriodLength,
    required this.nextPeriodDate,
    required this.ovulationDate,
    required this.fertileStart,
    required this.fertileEnd,
    required this.phase,
    required this.periodActive,
    required this.daysUntilNext,
  });
}

// ── Calculator ────────────────────────────────────────────────────────────────

class CycleCalculator {
  /// Average cycle length from the last [kHistoryCount] completed cycles.
  static int avgCycleLength(List<Cycle> cycles) {
    if (cycles.length < 2) return kDefaultCycleLength;
    final lengths = <int>[];
    for (int i = 0; i < cycles.length - 1 && i < kHistoryCount; i++) {
      final diff =
          _dayOnly(cycles[i].startedOn).difference(_dayOnly(cycles[i + 1].startedOn)).inDays;
      if (diff >= 15 && diff <= 60) lengths.add(diff);
    }
    if (lengths.isEmpty) return kDefaultCycleLength;
    return (lengths.reduce((a, b) => a + b) / lengths.length).round();
  }

  /// Average period length from completed cycles.
  static int avgPeriodLength(List<Cycle> cycles) {
    final done = cycles.where((c) => c.endedOn != null).take(kHistoryCount).toList();
    if (done.isEmpty) return kDefaultPeriodLength;
    final lengths = done
        .map((c) => _dayOnly(c.endedOn!).difference(_dayOnly(c.startedOn)).inDays + 1)
        .where((d) => d >= 1 && d <= 14)
        .toList();
    if (lengths.isEmpty) return kDefaultPeriodLength;
    return (lengths.reduce((a, b) => a + b) / lengths.length).round();
  }

  /// Predict the start date of the next period based on the last cycle start.
  static DateTime? nextPeriod(List<Cycle> cycles, int cycleLen) {
    if (cycles.isEmpty) return null;
    return _dayOnly(cycles.first.startedOn).add(Duration(days: cycleLen));
  }

  /// Estimated ovulation day for a given cycle start.
  static DateTime ovulation(DateTime cycleStart, int cycleLen) =>
      _dayOnly(cycleStart).add(Duration(days: cycleLen - 14));

  /// Fertile window: ovulation-2 → ovulation+1 (inclusive).
  static (DateTime, DateTime) fertileWindow(DateTime cycleStart, int cycleLen) {
    final ov = ovulation(cycleStart, cycleLen);
    return (ov.subtract(const Duration(days: 2)), ov.add(const Duration(days: 1)));
  }

  /// Determine which phase of the cycle [today] falls in.
  static CyclePhaseUI phase(
      DateTime lastStart, int cycleLen, int periodLen, DateTime today) {
    final day = _dayOnly(today).difference(_dayOnly(lastStart)).inDays + 1;
    final ovDay = cycleLen - 14;
    if (day < 1) return CyclePhaseUI.unknown;
    if (day <= periodLen)        return CyclePhaseUI.menstrual;
    if (day < ovDay - 2)         return CyclePhaseUI.follicular;
    if (day <= ovDay + 1)        return CyclePhaseUI.ovulation;
    return CyclePhaseUI.luteal;
  }

  /// Full stats calculation — the main entry point for the UI.
  static CycleStats calculate(List<Cycle> cycles, DateTime today) {
    final cycleLen  = avgCycleLength(cycles);
    final periodLen = avgPeriodLength(cycles);
    final todayD    = _dayOnly(today);

    if (cycles.isEmpty) {
      return CycleStats(
        cycleDay: 0, avgCycleLength: cycleLen, avgPeriodLength: periodLen,
        nextPeriodDate: null, ovulationDate: null,
        fertileStart: null, fertileEnd: null,
        phase: CyclePhaseUI.unknown, periodActive: false, daysUntilNext: null,
      );
    }

    final lastStart    = _dayOnly(cycles.first.startedOn);
    final periodActive = cycles.first.endedOn == null;
    final cycleDay     = todayD.difference(lastStart).inDays + 1;
    final p            = phase(lastStart, cycleLen, periodLen, today);
    final nextP        = nextPeriod(cycles, cycleLen);
    final ov           = ovulation(lastStart, cycleLen);
    final (fs, fe)     = fertileWindow(lastStart, cycleLen);
    final daysUntil    = nextP != null ? nextP.difference(todayD).inDays : null;

    return CycleStats(
      cycleDay:       cycleDay,
      avgCycleLength: cycleLen,
      avgPeriodLength: periodLen,
      nextPeriodDate: nextP,
      ovulationDate:  ov,
      fertileStart:   fs,
      fertileEnd:     fe,
      phase:          p,
      periodActive:   periodActive,
      daysUntilNext:  daysUntil,
    );
  }

  // ── Calendar helpers ───────────────────────────────────────────────────────

  /// Returns the type of a given [day] based on cycles and predictions.
  static DayType dayType(DateTime day, List<Cycle> cycles, CycleStats stats) {
    final d = _dayOnly(day);

    // Check actual recorded period days
    for (final c in cycles) {
      final s = _dayOnly(c.startedOn);
      final e = c.endedOn != null ? _dayOnly(c.endedOn!) : null;
      if (d.isAtSameMomentAs(s) || (d.isAfter(s) && e != null && !d.isAfter(e))) {
        return DayType.period;
      }
      // Open cycle (period in progress)
      if (e == null && (d.isAtSameMomentAs(s) || d.isAfter(s))) {
        return DayType.period;
      }
    }

    // Predicted next period window
    if (stats.nextPeriodDate != null) {
      final np = stats.nextPeriodDate!;
      if (!d.isBefore(np) && d.isBefore(np.add(Duration(days: stats.avgPeriodLength)))) {
        return DayType.predicted;
      }
    }

    // Fertile window (current cycle)
    if (stats.fertileStart != null && stats.fertileEnd != null) {
      if (!d.isBefore(stats.fertileStart!) && !d.isAfter(stats.fertileEnd!)) {
        return DayType.fertile;
      }
    }

    // Ovulation
    if (stats.ovulationDate != null && d.isAtSameMomentAs(stats.ovulationDate!)) {
      return DayType.ovulation;
    }

    return DayType.none;
  }
}

enum DayType { period, fertile, ovulation, predicted, none }

// ── Internal helpers ──────────────────────────────────────────────────────────

DateTime _dayOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
