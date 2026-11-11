enum WorkflowStatus {
  pending('Pending'),
  arrived('Arrived'),
  delivered('Delivered'),
  failed('Failed'),
  returnedToHub('Returned to hub');

  final String label;
  const WorkflowStatus(this.label);

  static WorkflowStatus fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'arrived':
        return WorkflowStatus.arrived;
      case 'delivered':
        return WorkflowStatus.delivered;
      case 'failed':
        return WorkflowStatus.failed;
      case 'returned to hub':
      case 'returnedtohub':
        return WorkflowStatus.returnedToHub;
      case 'pending':
      default:
        return WorkflowStatus.pending;
    }
  }
}
