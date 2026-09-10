class Task {
  String id;
  String title;
  String subject;
  DateTime date;
  String priority;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.subject,
    required this.date,
    required this.priority,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'date': date.toIso8601String(),
      'priority': priority,
      'completed': completed ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'].toString(),
      title: map['title'].toString(),
      subject: map['subject'].toString(),
      date: DateTime.parse(map['date'].toString()),
      priority: map['priority'].toString(),
      completed: map['completed'] == 1 || map['completed'] == true,
    );
  }
}