enum SyncStatus {
  synced('Synced'),
  pending('Pending'),
  retrying('Retrying'),
  needsAttention('Needs attention');

  final String label;
  const SyncStatus(this.label);
}
