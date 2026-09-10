import 'package:flutter/material.dart';

class ScheduleItem {
  String id;
  String day;
  String subject;
  TimeOfDay startTime;
  TimeOfDay endTime;

  ScheduleItem({
    required this.id,
    required this.day,
    required this.subject,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'subject': subject,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'].toString(),
      day: map['day'].toString(),
      subject: map['subject'].toString(),
      startTime: TimeOfDay(
        hour: (map['startHour'] as num).toInt(),
        minute: (map['startMinute'] as num).toInt(),
      ),
      endTime: TimeOfDay(
        hour: (map['endHour'] as num).toInt(),
        minute: (map['endMinute'] as num).toInt(),
      ),
    );
  }
}