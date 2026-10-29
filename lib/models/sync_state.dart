// lib/models/sync_state.dart

/// Where a locally recorded attendance event is in its trip to the server.
enum SyncState {
  /// Saved on the device, not yet accepted by the server.
  pending('PENDING'),

  /// A request for this event is in flight.
  syncing('SYNCING'),

  /// The server has the event.
  synced('SYNCED'),

  /// The server refused the event; it will not be retried.
  rejected('REJECTED');

  const SyncState(this.wireValue);

  /// Value stored in the database.
  final String wireValue;

  /// Parses [wireValue].
  static SyncState fromWire(String value) => values.firstWhere(
        (state) => state.wireValue == value,
        orElse: () => throw FormatException('Unknown sync state', value),
      );
}
