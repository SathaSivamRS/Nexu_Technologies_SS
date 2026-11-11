enum FailureReason {
  customerAbsent('Customer absent'),
  wrongAddress('Wrong address'),
  refused('Refused'),
  accessProblem('Access problem'),
  other('Other');

  final String label;
  const FailureReason(this.label);

  static FailureReason fromString(String val) {
    for (final reason in FailureReason.values) {
      if (reason.label.toLowerCase() == val.toLowerCase() ||
          reason.name.toLowerCase() == val.toLowerCase()) {
        return reason;
      }
    }
    return FailureReason.other;
  }
}
