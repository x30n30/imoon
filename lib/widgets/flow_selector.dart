import 'package:flutter/material.dart';
import 'package:imoon/theme.dart';

const kFlowOptions = ['none', 'light', 'medium', 'heavy'];

class FlowSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const FlowSelector({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: kFlowOptions.map((f) => _FlowButton(
        flow:     f,
        selected: selected == f,
        onTap:    () => onSelect(f),
      )).toList(),
    );
  }
}

class _FlowButton extends StatelessWidget {
  final String flow;
  final bool selected;
  final VoidCallback onTap;

  const _FlowButton({required this.flow, required this.selected, required this.onTap});

  static const _icons = {
    'none':   Icons.water_drop_outlined,
    'light':  Icons.water_drop,
    'medium': Icons.opacity,
    'heavy':  Icons.bloodtype,
  };

  static const _labels = {
    'none':   'None',
    'light':  'Light',
    'medium': 'Medium',
    'heavy':  'Heavy',
  };

  static const _colors = {
    'none':   IMoonColors.textDim,
    'light':  Color(0xFFFFB3C6),
    'medium': IMoonColors.period,
    'heavy':  Color(0xFFE91E8C),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[flow]!;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.18) : IMoonColors.surfaceVar,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : IMoonColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icons[flow], color: selected ? color : IMoonColors.textMuted, size: 20),
              const SizedBox(height: 4),
              Text(
                _labels[flow]!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? color : IMoonColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
