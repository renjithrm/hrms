// lib/models/sync_summary.dart

/// What the sync pill in the header shows.
sealed class SyncSummary {
  const SyncSummary();
}

/// Everything recorded on this device is on the server.
class SyncAllSynced extends SyncSummary {
  /// Creates the summary.
  const SyncAllSynced();
}

/// The device is offline and nothing is waiting.
class SyncOffline extends SyncSummary {
  /// Creates the summary.
  const SyncOffline();
}

/// Events are saved on the device and waiting to be sent.
class SyncWaiting extends SyncSummary {
  /// Creates the summary.
  const SyncWaiting(this.count);

  /// Number of events waiting.
  final int count;
}

/// A sync is running now.
class SyncInProgress extends SyncSummary {
  /// Creates the summary.
  const SyncInProgress();
}

/// The server refused events the person hasn't dismissed yet.
class SyncNeedsAttention extends SyncSummary {
  /// Creates the summary.
  const SyncNeedsAttention(this.count);

  /// Number of rejected events.
  final int count;
}
