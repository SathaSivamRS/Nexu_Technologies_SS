import '../../../../core/enums/sync_status.dart';

class SyncAction {
  final String id;
  final String stopId;
  final String actionType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int sequenceNumber;
  final SyncStatus status;
  final int retryCount;
  final DateTime? nextRetryTime;
  final String? lastError;

  const SyncAction({
    required this.id,
    required this.stopId,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    required this.sequenceNumber,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.nextRetryTime,
    this.lastError,
  });

  SyncAction copyWith({
    String? id,
    String? stopId,
    String? actionType,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? sequenceNumber,
    SyncStatus? status,
    int? retryCount,
    DateTime? nextRetryTime,
    bool clearNextRetryTime = false,
    String? lastError,
    bool clearLastError = false,
  }) {
    return SyncAction(
      id: id ?? this.id,
      stopId: stopId ?? this.stopId,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      nextRetryTime: clearNextRetryTime
          ? null
          : (nextRetryTime ?? this.nextRetryTime),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stopId': stopId,
        'actionType': actionType,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'sequenceNumber': sequenceNumber,
        'status': status.name,
        'retryCount': retryCount,
        'nextRetryTime': nextRetryTime?.toIso8601String(),
        'lastError': lastError,
      };

  factory SyncAction.fromJson(Map<String, dynamic> json) => SyncAction(
        id: json['id'] as String,
        stopId: json['stopId'] as String,
        actionType: json['actionType'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        sequenceNumber: json['sequenceNumber'] as int,
        status: SyncStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SyncStatus.pending,
        ),
        retryCount: json['retryCount'] as int? ?? 0,
        nextRetryTime: json['nextRetryTime'] != null
            ? DateTime.parse(json['nextRetryTime'] as String)
            : null,
        lastError: json['lastError'] as String?,
      );
}
