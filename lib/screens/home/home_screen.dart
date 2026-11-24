import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:imoon/providers/providers.dart';
import 'package:imoon/theme.dart';
import 'package:imoon/widgets/moon_dial.dart';
import 'package:imoon/screens/log/log_bottom_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(cycleStatsProvider);
    final cyclesAsync = ref.watch(cyclesProvider);
    final actions = ref.read(cycleActionsProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('iMoon 🌙',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: IMoonColors.primary, fontSize: 22)),
                      Text(
                        DateFormat('EEEE, d MMMM').format(DateTime.now()),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: IMoonColors.textMuted),
                    tooltip: 'Log today',
                    onPressed: () => showLogSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Moon dial
              if (stats != null) ...[
                Center(
                  child: MoonDial(
                    cycleDay:     stats.cycleDay.clamp(1, stats.avgCycleLength),
                    cycleLength:  stats.avgCycleLength,
                    phase:        stats.phase,
                    periodActive: stats.periodActive,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color:        phaseDimColor(stats.phase),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${phaseEmoji(stats.phase)} ${phaseLabel(stats.phase)} phase',
                      style: TextStyle(
                        color: phaseColor(stats.phase),
                        fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Text(
                      '🌑\nNo cycle data yet.\nTap "Period started" to begin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: IMoonColors.textMuted, height: 2),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Info cards row
              if (stats != null) ...[
                Row(children: [
                  _InfoCard(
                    icon:  Icons.calendar_today_outlined,
                    label: stats.daysUntilNext != null
                        ? (stats.daysUntilNext! <= 0
                            ? 'Period expected'
                            : '${stats.daysUntilNext}d until period')
                        : 'Next period',
                    sub: stats.nextPeriodDate != null
                        ? DateFormat('d MMM').format(stats.nextPeriodDate!)
                        : '—',
                    color: IMoonColors.period,
                  ),
                  const SizedBox(width: 10),
                  _InfoCard(
                    icon:  Icons.spa_outlined,
                    label: 'Ovulation',
                    sub: stats.ovulationDate != null
                        ? DateFormat('d MMM').format(stats.ovulationDate!)
                        : '—',
                    color: IMoonColors.ovulation,
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _InfoCard(
                    icon:  Icons.loop_rounded,
                    label: 'Avg cycle',
                    sub:   '${stats.avgCycleLength} days',
                    color: IMoonColors.secondary,
                  ),
                  const SizedBox(width: 10),
                  _InfoCard(
                    icon:  Icons.water_drop_outlined,
                    label: 'Avg period',
                    sub:   '${stats.avgPeriodLength} days',
                    color: IMoonColors.primary,
                  ),
                ]),
                const SizedBox(height: 24),
              ],

              // Period action button
              cyclesAsync.when(
                loading: () => const SizedBox.shrink(),
                error:   (_, __) => const SizedBox.shrink(),
                data: (cycles) {
                  final active = cycles.isNotEmpty && cycles.first.endedOn == null;
                  if (active) {
                    return Column(children: [
                      _ActionButton(
                        label: 'Period ended today',
                        icon:  Icons.stop_circle_outlined,
                        color: IMoonColors.period,
                        onTap: () async {
                          await actions.endPeriod(cycles.first.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Period marked as ended'),
                              backgroundColor: IMoonColors.surface,
                            ));
                          }
                        },
                      ),
                    ]);
                  }
                  return _ActionButton(
                    label: 'Period started today',
                    icon:  Icons.play_circle_outlined,
                    color: IMoonColors.period,
                    onTap: () async {
                      await actions.startPeriod();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Period started — stay strong 💕'),
                          backgroundColor: IMoonColors.surface,
                        ));
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 12),
              _ActionButton(
                label: 'Log how you feel',
                icon:  Icons.edit_note_rounded,
                color: IMoonColors.secondary,
                outline: true,
                onTap: () => showLogSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  const _InfoCard({required this.icon, required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        IMoonColors.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: IMoonColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: IMoonColors.textMuted, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                  Text(sub,
                      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outline;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label, required this.icon,
    required this.color, required this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color:        outline ? Colors.transparent : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: color.withOpacity(outline ? 0.6 : 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
