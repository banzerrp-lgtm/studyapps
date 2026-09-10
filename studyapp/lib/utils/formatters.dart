import 'package:flutter/material.dart';

String formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

int timeToMinutes(TimeOfDay time) {
  return time.hour * 60 + time.minute;
}

Color priorityColor(String priority) {
  switch (priority) {
    case 'Alta':
      return Colors.red;
    case 'Media':
      return Colors.orange;
    case 'Baja':
      return Colors.green;
    default:
      return Colors.blue;
  }
}