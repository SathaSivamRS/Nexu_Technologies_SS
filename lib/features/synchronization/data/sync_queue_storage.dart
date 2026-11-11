import 'dart:convert';
import 'package:hive/hive.dart';
import '../domain/entities/sync_action.dart';

abstract class SyncQueueStorage {
  List<SyncAction> getQueue();
  Future<void> enqueue(SyncAction action);
  Future<void> update(SyncAction action);
  Future<void> remove(String actionId);
  Future<void> clear();
  int getNextSequenceNumber(String stopId);
}

class SyncQueueStorageImpl implements SyncQueueStorage {
  final Box _box;

  SyncQueueStorageImpl(this._box);

  @override
  List<SyncAction> getQueue() {
    final list = <SyncAction>[];
    for (var i = 0; i < _box.length; i++) {
      final key = _box.keyAt(i);
      final raw = _box.get(key);
      if (raw != null) {
        try {
          final Map<String, dynamic> map = raw is String
              ? jsonDecode(raw)
              : Map<String, dynamic>.from(raw as Map);
          list.add(SyncAction.fromJson(map));
        } catch (_) {}
      }
    }
    // Sort by createdAt / sequenceNumber
    list.sort((a, b) {
      if (a.stopId == b.stopId) {
        return a.sequenceNumber.compareTo(b.sequenceNumber);
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  @override
  Future<void> enqueue(SyncAction action) async {
    await _box.put(action.id, jsonEncode(action.toJson()));
  }

  @override
  Future<void> update(SyncAction action) async {
    await _box.put(action.id, jsonEncode(action.toJson()));
  }

  @override
  Future<void> remove(String actionId) async {
    await _box.delete(actionId);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  @override
  int getNextSequenceNumber(String stopId) {
    final actions = getQueue().where((a) => a.stopId == stopId);
    if (actions.isEmpty) return 1;
    var maxSeq = 0;
    for (final a in actions) {
      if (a.sequenceNumber > maxSeq) {
        maxSeq = a.sequenceNumber;
      }
    }
    return maxSeq + 1;
  }
}
