import 'package:flutter/material.dart';

import '../models/schedule_item.dart';
import '../services/database_service.dart';
import '../utils/id_generator.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<ScheduleItem> _schedule = [];
  bool _loading = true;

  List<ScheduleItem> get schedule => List.unmodifiable(_schedule);
  bool get loading => _loading;

  Future<void> load() async {
    _schedule = await _db.loadSchedule();
    _loading = false;
    notifyListeners();
  }

  Future<void> addItem({
    required String day,
    required String subject,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    final item = ScheduleItem(
      id: generateId(),
      day: day,
      subject: subject,
      startTime: startTime,
      endTime: endTime,
    );

    _schedule.add(item);
    notifyListeners();

    await _db.upsertScheduleItem(item);
  }

  Future<void> deleteItem(ScheduleItem item) async {
    _schedule.removeWhere((element) => element.id == item.id);
    notifyListeners();

    await _db.deleteScheduleItem(item.id);
  }
}