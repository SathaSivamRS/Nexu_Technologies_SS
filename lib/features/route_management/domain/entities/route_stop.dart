import '../../../../core/enums/failure_reason.dart';
import '../../../../core/enums/priority.dart';
import '../../../../core/enums/workflow_status.dart';

class DeliveryHistoryEntry {
  final DateTime timestamp;
  final WorkflowStatus status;
  final String? recipientName;
  final int? confirmedPackages;
  final FailureReason? failureReason;
  final String? failureNote;
  final String? note;

  const DeliveryHistoryEntry({
    required this.timestamp,
    required this.status,
    this.recipientName,
    this.confirmedPackages,
    this.failureReason,
    this.failureNote,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'recipientName': recipientName,
        'confirmedPackages': confirmedPackages,
        'failureReason': failureReason?.name,
        'failureNote': failureNote,
        'note': note,
      };

  factory DeliveryHistoryEntry.fromJson(Map<String, dynamic> json) =>
      DeliveryHistoryEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        status: WorkflowStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => WorkflowStatus.pending,
        ),
        recipientName: json['recipientName'] as String?,
        confirmedPackages: json['confirmedPackages'] as int?,
        failureReason: json['failureReason'] != null
            ? FailureReason.values.firstWhere(
                (e) => e.name == json['failureReason'],
                orElse: () => FailureReason.other,
              )
            : null,
        failureNote: json['failureNote'] as String?,
        note: json['note'] as String?,
      );
}

class RouteStop {
  final String id;
  final String customerName;
  final String address;
  final int expectedPackages;
  final String windowStart;
  final String windowEnd;
  final StopPriority priority;
  final WorkflowStatus status;
  final bool isRetry;
  final int failureCount;
  final DateTime? deliveryTimestamp;
  final String? recipientName;
  final int? confirmedPackages;
  final FailureReason? lastFailureReason;
  final String? lastFailureNote;
  final List<DeliveryHistoryEntry> history;
  final int? customOrder;

  const RouteStop({
    required this.id,
    required this.customerName,
    required this.address,
    required this.expectedPackages,
    required this.windowStart,
    required this.windowEnd,
    required this.priority,
    this.status = WorkflowStatus.pending,
    this.isRetry = false,
    this.failureCount = 0,
    this.deliveryTimestamp,
    this.recipientName,
    this.confirmedPackages,
    this.lastFailureReason,
    this.lastFailureNote,
    this.history = const [],
    this.customOrder,
  });

  RouteStop copyWith({
    String? id,
    String? customerName,
    String? address,
    int? expectedPackages,
    String? windowStart,
    String? windowEnd,
    StopPriority? priority,
    WorkflowStatus? status,
    bool? isRetry,
    int? failureCount,
    DateTime? deliveryTimestamp,
    bool clearDeliveryTimestamp = false,
    String? recipientName,
    bool clearRecipientName = false,
    int? confirmedPackages,
    bool clearConfirmedPackages = false,
    FailureReason? lastFailureReason,
    bool clearLastFailure = false,
    String? lastFailureNote,
    List<DeliveryHistoryEntry>? history,
    int? customOrder,
    bool clearCustomOrder = false,
  }) {
    return RouteStop(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      expectedPackages: expectedPackages ?? this.expectedPackages,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isRetry: isRetry ?? this.isRetry,
      failureCount: failureCount ?? this.failureCount,
      deliveryTimestamp: clearDeliveryTimestamp
          ? null
          : (deliveryTimestamp ?? this.deliveryTimestamp),
      recipientName:
          clearRecipientName ? null : (recipientName ?? this.recipientName),
      confirmedPackages: clearConfirmedPackages
          ? null
          : (confirmedPackages ?? this.confirmedPackages),
      lastFailureReason: clearLastFailure
          ? null
          : (lastFailureReason ?? this.lastFailureReason),
      lastFailureNote:
          clearLastFailure ? null : (lastFailureNote ?? this.lastFailureNote),
      history: history ?? this.history,
      customOrder:
          clearCustomOrder ? null : (customOrder ?? this.customOrder),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'address': address,
        'expectedPackages': expectedPackages,
        'windowStart': windowStart,
        'windowEnd': windowEnd,
        'priority': priority.label,
        'status': status.label,
        'isRetry': isRetry,
        'failureCount': failureCount,
        'deliveryTimestamp': deliveryTimestamp?.toIso8601String(),
        'recipientName': recipientName,
        'confirmedPackages': confirmedPackages,
        'lastFailureReason': lastFailureReason?.name,
        'lastFailureNote': lastFailureNote,
        'history': history.map((e) => e.toJson()).toList(),
        'customOrder': customOrder,
      };

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      address: json['address'] as String,
      expectedPackages: json['expectedPackages'] as int,
      windowStart: json['windowStart'] as String,
      windowEnd: json['windowEnd'] as String,
      priority: StopPriority.fromString(json['priority'] as String? ?? 'Normal'),
      status: WorkflowStatus.fromString(json['status'] as String? ?? 'Pending'),
      isRetry: json['isRetry'] as bool? ?? false,
      failureCount: json['failureCount'] as int? ?? 0,
      deliveryTimestamp: json['deliveryTimestamp'] != null
          ? DateTime.parse(json['deliveryTimestamp'] as String)
          : null,
      recipientName: json['recipientName'] as String?,
      confirmedPackages: json['confirmedPackages'] as int?,
      lastFailureReason: json['lastFailureReason'] != null
          ? FailureReason.values.firstWhere(
              (e) => e.name == json['lastFailureReason'],
              orElse: () => FailureReason.other,
            )
          : null,
      lastFailureNote: json['lastFailureNote'] as String?,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => DeliveryHistoryEntry.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      customOrder: json['customOrder'] as int?,
    );
  }
}
