import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imoon/providers/providers.dart';
import 'package:imoon/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final cyclesAsync = ref.watch(cyclesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Notifications ───────────────────────────────────────────────
          _SectionHeader('Notifications'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Period reminders',
                          style: TextStyle(color: IMoonColors.textPrimary, fontSize: 14)),
                      Switch(
                        value:    settings.remindersEnabled,
                        onChanged: settings.setRemindersEnabled,
                        activeColor: IMoonColors.primary,
                      ),
                    ],
                  ),
                  if (settings.remindersEnabled) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Days before',
                            style: TextStyle(color: IMoonColors.textMuted, fontSize: 13)),
                        DropdownButton<int>(
                          value: settings.reminderDaysBefore,
                          dropdownColor: IMoonColors.surfaceVar,
                          style: const TextStyle(color: IMoonColors.textPrimary, fontSize: 13),
                          underline: const SizedBox.shrink(),
                          items: [1, 2, 3, 5].map((d) =>
                              DropdownMenuItem(value: d, child: Text('$d day${d > 1 ? 's' : ''}'))
                          ).toList(),
                          onChanged: (v) {
                            if (v != null) settings.setReminderDays(v);
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Data ────────────────────────────────────────────────────────
          _SectionHeader('Data'),
          Card(
            child: cyclesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (cycles) => Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.loop, color: IMoonColors.secondary, size: 20),
                    title: const Text('Cycles recorded',
                        style: TextStyle(color: IMoonColors.textPrimary, fontSize: 14)),
                    trailing: Text('${cycles.length}',
                        style: const TextStyle(color: IMoonColors.textMuted, fontSize: 14)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: IMoonColors.bad, size: 20),
                    title: const Text('Clear all data',
                        style: TextStyle(color: IMoonColors.bad, fontSize: 14)),
                    onTap: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── About ────────────────────────────────────────────────────────
          _SectionHeader('About'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('🌙 ', style: TextStyle(fontSize: 20)),
                    Text('iMoon',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: IMoonColors.primary)),
                  ]),
                  const SizedBox(height: 6),
                  const Text('v1.0.0',
                      style: TextStyle(color: IMoonColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  const Text(
                    'Period tracker — local-first, your data stays on your device.',
                    style: TextStyle(color: IMoonColors.textMuted, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: IMoonColors.surface,
        title: const Text('Clear all data?',
            style: TextStyle(color: IMoonColors.textPrimary)),
        content: const Text(
          'This will permanently delete all cycles and logs.',
          style: TextStyle(color: IMoonColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: IMoonColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: IMoonColors.bad)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final cycles = await ref.read(dbProvider).appDao.getAllCycles();
      for (final c in cycles) {
        await ref.read(dbProvider).appDao.deleteCycle(c.id);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: IMoonColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
  );
}
