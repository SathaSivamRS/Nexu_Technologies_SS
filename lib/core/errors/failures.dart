abstract class AppFailure {
  final String message;
  const AppFailure(this.message);

  @override
  String toString() => message;
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class WorkflowFailure extends AppFailure {
  const WorkflowFailure(super.message);
}

class StorageFailure extends AppFailure {
  const StorageFailure(super.message);
}

class SyncFailure extends AppFailure {
  const SyncFailure(super.message);
}
