import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:imoon/providers/providers.dart';
import 'package:imoon/theme.dart';
import 'package:imoon/widgets/flow_selector.dart';
import 'package:imoon/widgets/tag_chip_group.dart';

/// Shows the daily log bottom sheet.
/// [date] defaults to today. Pass a specific date to log for another day.
Future<void> showLogSheet(BuildContext context, {DateTime? date}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LogSheet(date: date ?? DateTime.now()),
  );
}

class _LogSheet extends ConsumerStatefulWidget {
  final DateTime date;
  const _LogSheet({required this.date});

  @override
  ConsumerState<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends ConsumerState<_LogSheet> {
  String         _flow     = 'none';
  List<String>   _moods    = [];
  List<String>   _symptoms = [];
  final _notesCtrl = TextEditingController();
  bool           _loading  = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final log = await ref.read(dbProvider).appDao.getLogForDate(widget.date);
    if (log != null && mounted) {
      setState(() {
        _flow     = log.flow;
        _moods    = List<String>.from(jsonDecode(log.moods));
        _symptoms = List<String>.from(jsonDecode(log.symptoms));
        _notesCtrl.text = log.notes;
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    await ref.read(cycleActionsProvider).saveLog(
      date:     widget.date,
      flow:     _flow,
      moods:    _moods,
      symptoms: _symptoms,
      notes:    _notesCtrl.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, d MMMM').format(widget.date);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: IMoonColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: _loading
          ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: IMoonColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(dateLabel,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),

                  // Flow
                  _sectionLabel(context, '💧 Flow'),
                  const SizedBox(height: 10),
                  FlowSelector(
                    selected: _flow,
                    onSelect: (v) => setState(() => _flow = v),
                  ),
                  const SizedBox(height: 20),

                  // Mood
                  _sectionLabel(context, '🌙 Mood'),
                  const SizedBox(height: 10),
                  TagChipGroup(
                    options:   kMoodTags,
                    selected:  _moods,
                    onChanged: (v) => setState(() => _moods = v),
                    activeColor: IMoonColors.secondary,
                  ),
                  const SizedBox(height: 20),

                  // Symptoms
                  _sectionLabel(context, '✨ Symptoms'),
                  const SizedBox(height: 10),
                  TagChipGroup(
                    options:   kSymptomTags,
                    selected:  _symptoms,
                    onChanged: (v) => setState(() => _symptoms = v),
                    activeColor: IMoonColors.primary,
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  _sectionLabel(context, '📝 Notes'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: IMoonColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'How are you feeling today?',
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: IMoonColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
  );
}
