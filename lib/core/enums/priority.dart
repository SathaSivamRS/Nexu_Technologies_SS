enum StopPriority {
  normal('Normal'),
  urgent('Urgent');

  final String label;
  const StopPriority(this.label);

  static StopPriority fromString(String val) {
    if (val.toLowerCase().trim() == 'urgent') {
      return StopPriority.urgent;
    }
    return StopPriority.normal;
  }
}
