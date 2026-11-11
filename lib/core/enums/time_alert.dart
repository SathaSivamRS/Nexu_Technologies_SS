enum TimeAlert {
  normal('Normal'),
  atRisk('At risk'),
  late('Late');

  final String label;
  const TimeAlert(this.label);
}
