import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:imoon/providers/providers.dart';
import 'package:imoon/theme.dart';
import 'package:imoon/logic/cycle_calculator.dart';
import 'package:imoon/screens/log/log_bottom_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay  = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final stats      = ref.watch(cycleStatsProvider);
    final cyclesAsync = ref.watch(cyclesProvider);
    final logMap     = ref.watch(logMapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: cyclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (cycles) => Column(
          children: [
            TableCalendar(
              firstDay:   DateTime.utc(2020, 1, 1),
              lastDay:    DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (d) =>
                  _selectedDay != null && isSameDay(d, _selectedDay),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay  = focused;
                });
              },
              onPageChanged: (focused) {
                setState(() => _focusedDay = focused);
                ref.read(focusedMonthProvider.notifier).state = focused;
              },
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle:    TextStyle(color: IMoonColors.textPrimary),
                weekendTextStyle:    TextStyle(color: IMoonColors.textPrimary),
                selectedTextStyle:   TextStyle(color: IMoonColors.bg, fontWeight: FontWeight.w700),
                todayTextStyle:      TextStyle(color: IMoonColors.primary, fontWeight: FontWeight.w700),
                selectedDecoration:  BoxDecoration(color: IMoonColors.primary, shape: BoxShape.circle),
                todayDecoration:     BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(BorderSide(color: IMoonColors.primary, width: 1.5)),
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered:       true,
                titleTextStyle: TextStyle(color: IMoonColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                leftChevronIcon:  Icon(Icons.chevron_left,  color: IMoonColors.textMuted),
                rightChevronIcon: Icon(Icons.chevron_right, color: IMoonColors.textMuted),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: IMoonColors.textMuted, fontSize: 12),
                weekendStyle: TextStyle(color: IMoonColors.textMuted, fontSize: 12),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (ctx, day, _) =>
                    _buildDay(ctx, day, cycles, stats, logMap, false),
                outsideBuilder: (ctx, day, _) =>
                    _buildDay(ctx, day, cycles, stats, logMap, true),
              ),
            ),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Legend(color: IMoonColors.period,    label: 'Period'),
                  _Legend(color: IMoonColors.predicted, label: 'Expected'),
                  _Legend(color: IMoonColors.fertile,   label: 'Fertile'),
                  _Legend(color: IMoonColors.ovulation, label: 'Ovulation'),
                ],
              ),
            ),

            const Divider(),

            // Selected day info
            if (_selectedDay != null)
              Expanded(
                child: _DayDetail(
                  date:   _selectedDay!,
                  logMap: logMap,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showLogSheet(context, date: _selectedDay),
        child: const Icon(Icons.edit_note_rounded),
      ),
    );
  }

  Widget? _buildDay(
    BuildContext ctx,
    DateTime day,
    List<Cycle> cycles,
    CycleStats? stats,
    Map<String, DailyLog> logMap,
    bool outside,
  ) {
    if (stats == null) return null;
    final type = CycleCalculator.dayType(day, cycles, stats);
    if (type == DayType.none && !outside) return null;

    final color = switch (type) {
      DayType.period    => IMoonColors.period,
      DayType.predicted => IMoonColors.predicted,
      DayType.fertile   => IMoonColors.fertile,
      DayType.ovulation => IMoonColors.ovulation,
      DayType.none      => Colors.transparent,
    };

    final hasLog = logMap.containsKey(_dateKey(day));

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:        color.withOpacity(type == DayType.none ? 0 : 0.25),
        shape:        BoxShape.circle,
        border:       type != DayType.none
            ? Border.all(color: color.withOpacity(0.6), width: 1)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color:      outside ? IMoonColors.textDim
                  : type != DayType.none ? color : IMoonColors.textPrimary,
              fontSize:   13,
              fontWeight: type != DayType.none ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (hasLog)
            Positioned(
              bottom: 3,
              child: Container(
                width: 4, height: 4,
                decoration: const BoxDecoration(
                  color: IMoonColors.secondary, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: IMoonColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _DayDetail extends StatelessWidget {
  final DateTime date;
  final Map<String, DailyLog> logMap;

  const _DayDetail({required this.date, required this.logMap});

  @override
  Widget build(BuildContext context) {
    final log = logMap[_dateKey(date)];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: log == null
          ? Center(
              child: Text('No log for this day',
                  style: Theme.of(context).textTheme.bodyMedium))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.flow != 'none')
                  _chip('💧 ${log.flow[0].toUpperCase()}${log.flow.substring(1)} flow', IMoonColors.period),
                // Could expand to show moods/symptoms chips here
              ],
            ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
