import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

/// Shows a balance amount with GREEN (they owe worker/transporter - positive)
/// or RED/ORANGE (advance given / owes back - negative) color coding.
class BalanceChip extends StatelessWidget {
  final double balance;
  final double fontSize;
  const BalanceChip({super.key, required this.balance, this.fontSize = 15});

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;
    final color = isNegative ? AppColors.balanceRed : AppColors.balanceGreen;
    return Text(
      'Balance Due: ${Fmt.money(balance)}',
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: fontSize),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class SearchBarWidget extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchBarWidget({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
    );
  }
}

class DateFilterChips extends StatelessWidget {
  final DateRangeFilter selected;
  final ValueChanged<DateRangeFilter> onSelected;
  final List<DateRangeFilter> options;

  const DateFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.options = const [
      DateRangeFilter.today,
      DateRangeFilter.thisWeek,
      DateRangeFilter.thisMonth,
      DateRangeFilter.custom,
    ],
  });

  String _label(DateRangeFilter f) {
    switch (f) {
      case DateRangeFilter.today:
        return 'Today';
      case DateRangeFilter.thisWeek:
        return 'This Week';
      case DateRangeFilter.thisMonth:
        return 'This Month';
      case DateRangeFilter.thisQuarter:
        return 'Quarter';
      case DateRangeFilter.thisYear:
        return 'This Year';
      case DateRangeFilter.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((f) {
          final isSelected = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_label(f)),
              selected: isSelected,
              onSelected: (_) => onSelected(f),
              selectedColor: AppColors.primaryBlue,
              backgroundColor: AppColors.surfaceLight,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 13),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Wraps [DateFilterChips] and actually resolves a usable [DateRange],
/// including opening a real date-range picker when "Custom" is tapped.
/// Use this instead of DateFilterChips directly wherever a Custom option
/// is offered, so "Custom" isn't a dead button.
class DateFilterBar extends StatefulWidget {
  final List<DateRangeFilter> options;
  final DateRangeFilter initial;
  final ValueChanged<DateRange> onRangeChanged;

  const DateFilterBar({
    super.key,
    required this.onRangeChanged,
    this.initial = DateRangeFilter.thisMonth,
    this.options = const [
      DateRangeFilter.today,
      DateRangeFilter.thisWeek,
      DateRangeFilter.thisMonth,
      DateRangeFilter.custom,
    ],
  });

  @override
  State<DateFilterBar> createState() => _DateFilterBarState();
}

class _DateFilterBarState extends State<DateFilterBar> {
  late DateRangeFilter _filter = widget.initial;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  void _emit() {
    widget.onRangeChanged(DateRange.forFilter(_filter, customStart: _customStart, customEnd: _customEnd));
  }

  Future<void> _selectFilter(DateRangeFilter f) async {
    if (f == DateRangeFilter.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        initialDateRange: _customStart != null && _customEnd != null
            ? DateTimeRange(start: _customStart!, end: _customEnd!)
            : DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      );
      if (picked == null) return; // cancelled - keep previous filter as-is
      _customStart = picked.start;
      _customEnd = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
    }
    setState(() => _filter = f);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DateFilterChips(selected: _filter, options: widget.options, onSelected: _selectFilter),
        if (_filter == DateRangeFilter.custom && _customStart != null && _customEnd != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${Fmt.date(_customStart!)} - ${Fmt.date(_customEnd!)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
