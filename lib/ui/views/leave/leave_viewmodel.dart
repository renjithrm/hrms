// lib/ui/views/leave/leave_viewmodel.dart

import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.bottomsheets.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../constants/app_strings.dart';
import '../../../extensions/error_message_extension.dart';
import '../../../models/leave_balance.dart';
import '../../../models/leave_filter.dart';
import '../../../models/leave_request.dart';
import '../../../models/leave_status.dart';
import '../../../models/sync_summary.dart';
import '../../../services/clock_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/leave_service.dart';
import '../../../services/logger_service.dart';
import '../../../services/sync_service.dart';

/// Screen I: leave balances, requests with a status filter, and the way in
/// to apply. Works from the cache offline; applying needs a connection.
class LeaveViewModel extends ReactiveViewModel {
  final _leaveService = locator<LeaveService>();
  final _connectivityService = locator<ConnectivityService>();
  final _syncService = locator<SyncService>();
  final _navigationService = locator<NavigationService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _clock = locator<ClockService>();
  final _logger = locator<LoggerService>();

  final _badge = DateFormat('d MMM');
  final _day = DateFormat('d');
  final _stamp = DateFormat('d MMM, HH:mm');

  LeaveFilter _filter = LeaveFilter.all;

  @override
  List<ListenableServiceMixin> get listenableServices => [
        _leaveService,
        _connectivityService,
        _syncService,
      ];

  /// Shows the cache, then refreshes from the server.
  Future<void> init() async {
    try {
      await _leaveService.loadCached();
    } catch (e, stackTrace) {
      _logger.error('Leave cache', e, stackTrace);
    }
    await refresh();
  }

  /// Downloads balances and requests. Used by init and pull-to-refresh.
  Future<void> refresh() async {
    clearErrors();
    setBusy(true);
    try {
      await _leaveService.refresh();
    } catch (e, stackTrace) {
      _logger.error('Leave refresh', e, stackTrace);
      setError(e);
    } finally {
      setBusy(false);
    }
  }

  // Screen state

  /// Whether leave data has ever been downloaded.
  bool get hasCache => _leaveService.hasCache;

  /// First load with nothing cached.
  bool get showLoading => isBusy && !hasCache;

  /// Nothing cached and the download failed.
  bool get showFullError => hasError && !hasCache;

  /// Message for the full error state.
  String get errorMessage {
    final Object? error = modelError;
    return error?.userMessage ?? AppStrings.unexpectedError;
  }

  /// Banner over cached data that may be old, or null.
  String? get bannerMessage {
    final updated = _leaveService.lastUpdated;
    if (updated == null) return null;
    final stamp = _stamp.format(_clock.toCompany(updated));
    if (!_connectivityService.isOnline) return AppStrings.offlineBanner(stamp);
    if (hasError) return AppStrings.refreshFailedBanner(stamp);
    return null;
  }

  /// Whether the banner reports a failure rather than being offline.
  bool get isBannerAnError => hasError && _connectivityService.isOnline;

  /// What the sync pill shows.
  SyncSummary get syncSummary => _syncService.summary;

  /// Opens the sync queue sheet from the pill.
  Future<void> openSyncQueue() async {
    await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.syncQueue,
      isScrollControlled: true,
    );
  }

  // Balances

  /// Balance per leave type.
  List<LeaveBalance> get balances => _leaveService.balances;

  /// "2 days on hold in pending requests", or null when none are.
  String? onHoldOf(LeaveBalance balance) =>
      balance.onHold > 0 ? AppStrings.leaveOnHold(balance.onHold) : null;

  // Filter and list

  /// The selected filter.
  LeaveFilter get filter => _filter;

  /// Shows only requests matching [filter].
  void selectFilter(LeaveFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  /// Chip label, with a count for pending ("Pending 1").
  String filterLabelOf(LeaveFilter filter) {
    final label = switch (filter) {
      LeaveFilter.all => AppStrings.filterAll,
      LeaveFilter.pending => AppStrings.leavePending,
      LeaveFilter.approved => AppStrings.leaveApproved,
      LeaveFilter.rejected => AppStrings.leaveRejected,
    };
    if (filter != LeaveFilter.pending) return label;
    final count = _countOf(LeaveStatus.pending);
    return count == 0 ? label : AppStrings.filterWithCount(label, count);
  }

  int _countOf(LeaveStatus status) =>
      _leaveService.requests.where((r) => r.status == status).length;

  /// Requests matching the filter, newest start date first.
  List<LeaveRequest> get requests {
    final status = _filter.status;
    final all = _leaveService.requests;
    return status == null ? all : all.where((r) => r.status == status).toList();
  }

  /// No requests at all, or none for the filter.
  bool get showEmptyList => !showLoading && !showFullError && requests.isEmpty;

  /// Title of the empty list.
  String get emptyTitle => _filter == LeaveFilter.all
      ? AppStrings.leaveEmptyTitle
      : AppStrings.leaveFilterEmpty(filterLabelOf(_filter));

  /// "5 Nov", the start date.
  String badgeOf(LeaveRequest request) => _badge.format(request.startDate);

  /// "Casual · 5–6 Nov".
  String titleOf(LeaveRequest request) =>
      AppStrings.leaveRequestTitle(request.type.label, _range(request));

  /// "2 days · Family function", or the reviewer's note when rejected.
  String detailOf(LeaveRequest request) {
    final note = request.reviewerNote;
    if (request.status == LeaveStatus.rejected && note != null) return note;
    return AppStrings.leaveRequestDetail(
      AppStrings.leaveDays(request.days),
      request.reason,
    );
  }

  /// Status word for the chip.
  String statusOf(LeaveRequest request) => switch (request.status) {
        LeaveStatus.pending => AppStrings.leavePending,
        LeaveStatus.approved => AppStrings.leaveApproved,
        LeaveStatus.rejected => AppStrings.leaveRejected,
      };

  String _range(LeaveRequest request) {
    final start = request.startDate;
    final end = request.endDate;
    if (start == end) return _badge.format(start);
    if (start.month == end.month && start.year == end.year) {
      return '${_day.format(start)}–${_badge.format(end)}';
    }
    return '${_badge.format(start)} – ${_badge.format(end)}';
  }

  // Apply

  /// Applying needs the server, so it is only offered online.
  bool get canApply => _connectivityService.isOnline;

  /// "Apply for leave", or "Needs a connection" offline.
  String get applyLabel =>
      canApply ? AppStrings.applyForLeave : AppStrings.needsConnection;

  /// Opens the apply flow; refreshes when coming back.
  Future<void> applyForLeave() async {
    if (!canApply) return;
    await _navigationService.navigateToApplyLeaveView();
    await refresh();
  }
}
