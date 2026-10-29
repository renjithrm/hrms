// lib/ui/views/leave/components/leave_filter_chips.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../../constants/app_colors.dart';
import '../../../../models/leave_filter.dart';
import '../../../tools/app_text_style.dart';
import '../leave_viewmodel.dart';

/// All, Pending, Approved, Rejected as compact chips on one row. The row
/// scrolls sideways only if large text makes it wider than the screen.
class LeaveFilterChips extends ViewModelWidget<LeaveViewModel> {
  /// Creates the chips.
  const LeaveFilterChips({super.key});

  @override
  Widget build(BuildContext context, LeaveViewModel viewModel) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, filter) in LeaveFilter.values.indexed) ...[
            if (index > 0) const SizedBox(width: 6),
            _FilterChip(
              label: viewModel.filterLabelOf(filter),
              isSelected: viewModel.filter == filter,
              onSelected: () => viewModel.selectFilter(filter),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      // No checkmark: the filled colour shows the selection and the chip
      // stays narrow.
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      labelStyle: AppTextStyle.chip.copyWith(
        fontSize: 12,
        color: isSelected ? Palette.onBrand : Palette.ink,
      ),
      selectedColor: Palette.brand,
      backgroundColor: Palette.surface,
      side: BorderSide(color: isSelected ? Palette.brand : Palette.line),
      shape: const StadiumBorder(),
    );
  }
}
