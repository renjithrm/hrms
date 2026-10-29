// lib/ui/bottom_sheets/sync_queue/sync_queue_sheet.dart

import '../../widgets/common/sheet_surface.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../models/attendance_event.dart';
import '../../../models/sync_state.dart';
import '../../theme/app_motion.dart';
import '../../tools/app_text_style.dart';
import '../../tools/ui_helpers.dart';
import '../../widgets/common/status_tone.dart';
import 'sync_queue_sheet_model.dart';

/// Screen G: a timeline of attendance taken on this phone and its sync
/// state, with "Sync now" and a way to clear entries the server refused.
class SyncQueueSheet extends StackedView<SyncQueueSheetModel> {
  /// Creates the sheet.
  const SyncQueueSheet({
    super.key,
    required this.completer,
    required this.request,
  });

  /// Closes the sheet with a response.
  final Function(SheetResponse response)? completer;

  /// Unused; the sheet reads the queue from `SyncService`.
  final SheetRequest request;

  @override
  Widget builder(
    BuildContext context,
    SyncQueueSheetModel viewModel,
    Widget? child,
  ) {
    return SheetSurface(
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Palette.line,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
                Gap.v16,
                const Text(AppStrings.syncSheetTitle,
                    style: AppTextStyle.heading),
                Gap.v4,
                Semantics(
                  liveRegion: true,
                  child: Text(viewModel.subtitle, style: AppTextStyle.caption),
                ),
                Gap.v12,
                Flexible(
                  child: _Timeline(
                    rows: viewModel.rows,
                    itemBuilder: (event) => _Row(event: event),
                  ),
                ),
                if (viewModel.rows.isNotEmpty) ...[
                  Gap.v8,
                  const Text(AppStrings.syncSheetHint,
                      style: AppTextStyle.caption),
                ],
                Gap.v16,
                FilledButton.icon(
                  onPressed: viewModel.canSyncNow ? viewModel.syncNow : null,
                  icon: const Icon(Icons.sync_rounded),
                  label: Text(viewModel.syncButtonLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  SyncQueueSheetModel viewModelBuilder(BuildContext context) =>
      SyncQueueSheetModel();
}

/// Keeps an [AnimatedList] in step with the rows it is given, so a
/// dismissed entry collapses instead of vanishing. Holds only animation
/// state.
class _Timeline extends StatefulWidget {
  const _Timeline({required this.rows, required this.itemBuilder});

  final List<AttendanceEvent> rows;
  final Widget Function(AttendanceEvent event) itemBuilder;

  @override
  State<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<_Timeline> {
  final _listKey = GlobalKey<AnimatedListState>();
  late List<AttendanceEvent> _shown = List.of(widget.rows);

  @override
  void didUpdateWidget(_Timeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    final list = _listKey.currentState;
    final next = widget.rows;
    final nextIds = {for (final e in next) e.eventId};
    // 300 ms collapse from the motion plan; instant with reduce motion.
    final duration = AppMotion.of(context).canLoop
        ? const Duration(milliseconds: 300)
        : Duration.zero;

    for (var i = _shown.length - 1; i >= 0; i--) {
      final removed = _shown[i];
      if (nextIds.contains(removed.eventId)) continue;
      _shown.removeAt(i);
      list?.removeItem(
        i,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: FadeTransition(
            opacity: animation,
            child: widget.itemBuilder(removed),
          ),
        ),
        duration: duration,
      );
    }
    final shownIds = {for (final e in _shown) e.eventId};
    for (var i = 0; i < next.length; i++) {
      if (shownIds.contains(next[i].eventId)) continue;
      _shown.insert(i, next[i]);
      list?.insertItem(i, duration: duration);
    }
    // Same entries, newer state (status, attempts).
    _shown = List.of(next);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      initialItemCount: _shown.length,
      itemBuilder: (context, index, animation) => SizeTransition(
        sizeFactor: animation,
        child: widget.itemBuilder(_shown[index]),
      ),
    );
  }
}

class _Row extends ViewModelWidget<SyncQueueSheetModel> {
  const _Row({required this.event});

  final AttendanceEvent event;

  @override
  Widget build(BuildContext context, SyncQueueSheetModel viewModel) {
    final isRejected = event.status == SyncState.rejected;
    return GestureDetector(
      onLongPress: () => viewModel.toggleReveal(event),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusNode(status: event.status),
            Gap.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(viewModel.titleOf(event),
                      style: AppTextStyle.bodyStrong),
                  Gap.v4,
                  AnimatedSwitcher(
                    duration: AppMotion.of(context).fast,
                    child: Text(
                      viewModel.statusOf(event),
                      key: ValueKey(viewModel.statusOf(event)),
                      style: AppTextStyle.caption.copyWith(
                        color: isRejected ? Palette.danger : null,
                      ),
                    ),
                  ),
                  if (viewModel.isRevealed(event)) ...[
                    Gap.v4,
                    SelectableText(
                      AppStrings.eventId(event.eventId),
                      style: AppTextStyle.caption,
                    ),
                  ],
                ],
              ),
            ),
            if (isRejected)
              TextButton(
                onPressed: () => viewModel.dismiss(event),
                child: const Text(AppStrings.dismiss),
              ),
          ],
        ),
      ),
    );
  }
}

/// Timeline node; changes through an [AnimatedSwitcher] as the entry moves
/// from waiting to sending to synced.
class _StatusNode extends StatelessWidget {
  const _StatusNode({required this.status});

  final SyncState status;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = switch (status) {
      SyncState.pending => (Icons.schedule_rounded, StatusTone.warning),
      SyncState.syncing => (Icons.sync_rounded, StatusTone.info),
      SyncState.synced => (Icons.check_rounded, StatusTone.success),
      SyncState.rejected => (Icons.close_rounded, StatusTone.danger),
    };
    return AnimatedSwitcher(
      duration: AppMotion.of(context).base,
      switchInCurve: AppMotion.emphasized,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Container(
        key: ValueKey(status),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: tone.background,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: tone.foreground),
      ),
    );
  }
}
