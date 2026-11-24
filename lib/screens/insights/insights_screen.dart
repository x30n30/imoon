import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imoon/providers/providers.dart';
import 'package:imoon/theme.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cyclesProvider);
    final stats       = ref.watch(cycleStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: cyclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (cycles) {
          if (cycles.isEmpty) {
            return const Center(
              child: Text('No data yet.\nLog a few cycles to see insights.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: IMoonColors.textMuted, height: 2)),
            );
          }

          // Build cycle length bar data
          final completed = cycles
              .where((c) => c.endedOn != null)
              .take(8)
              .toList()
              .reversed
              .toList();

          final barGroups = [
            for (int i = 0; i < completed.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: completed[i].endedOn!
                      .difference(completed[i].startedOn)
                      .inDays
                      .toDouble() + 1,
                  color: IMoonColors.period,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ]),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats cards
                if (stats != null) ...[
                  Row(children: [
                    _StatCard(label: 'Avg cycle',  value: '${stats.avgCycleLength}d', color: IMoonColors.secondary),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Avg period', value: '${stats.avgPeriodLength}d', color: IMoonColors.period),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Cycles logged', value: '${cycles.length}', color: IMoonColors.primary),
                  ]),
                  const SizedBox(height: 24),
                ],

                // Period length chart
                if (completed.isNotEmpty) ...[
                  Text('Period lengths (days)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 2,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: IMoonColors.border, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(
                                  color: IMoonColors.textMuted, fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barTouchData: BarTouchData(enabled: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Cycle list
                Text('Cycle history',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                ...cycles.take(12).map((c) {
                  final len = c.endedOn != null
                      ? '${c.endedOn!.difference(c.startedOn).inDays + 1}d period'
                      : 'ongoing';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.water_drop, color: IMoonColors.period, size: 18),
                    title: Text(
                      _fmt(c.startedOn),
                      style: const TextStyle(color: IMoonColors.textPrimary, fontSize: 14),
                    ),
                    trailing: Text(len,
                        style: const TextStyle(color: IMoonColors.textMuted, fontSize: 12)),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color:        IMoonColors.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: IMoonColors.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: IMoonColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
