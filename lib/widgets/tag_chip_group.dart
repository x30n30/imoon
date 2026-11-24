import 'package:flutter/material.dart';
import 'package:imoon/theme.dart';

const kMoodTags = [
  'Happy', 'Calm', 'Sad', 'Anxious', 'Irritable',
  'Energetic', 'Tired', 'Emotional', 'Focused', 'Sensitive',
];

const kSymptomTags = [
  'Cramps', 'Headache', 'Bloating', 'Backache', 'Nausea',
  'Spotting', 'Breast tenderness', 'Acne', 'Fatigue', 'Insomnia',
  'Mood swings', 'Food cravings',
];

class TagChipGroup extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final Color? activeColor;

  const TagChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final ac = activeColor ?? IMoonColors.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((tag) {
        final isOn = selected.contains(tag);
        return GestureDetector(
          onTap: () {
            final next = List<String>.from(selected);
            if (isOn) {
              next.remove(tag);
            } else {
              next.add(tag);
            }
            onChanged(next);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color:        isOn ? ac.withOpacity(0.18) : IMoonColors.surfaceVar,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOn ? ac : IMoonColors.border,
                width: isOn ? 1.5 : 1,
              ),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize:   12,
                fontWeight: isOn ? FontWeight.w600 : FontWeight.w400,
                color:      isOn ? ac : IMoonColors.textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
