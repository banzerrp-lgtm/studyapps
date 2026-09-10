import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/schedule_provider.dart';
import '../providers/subjects_provider.dart';
import '../utils/formatters.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final days = const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  String selectedDay = 'Lunes';

  Future<void> _addSchedule(BuildContext context) async {
    final scheduleProvider = context.read<ScheduleProvider>();
    final subjects = context.read<SubjectsProvider>().subjects;

    String day = selectedDay;
    String subject = subjects.isNotEmpty ? subjects.first : 'General';
    TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 9, minute: 0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva clase'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: day,
                      decoration: const InputDecoration(labelText: 'Día', border: OutlineInputBorder()),
                      items: days.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            day = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    if (subjects.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: subject,
                        decoration: const InputDecoration(labelText: 'Materia', border: OutlineInputBorder()),
                        items: subjects.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              subject = value;
                            });
                          }
                        },
                      )
                    else
                      const Text('Primero agrega materias.'),
                    const SizedBox(height: 15),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('Hora de inicio'),
                      subtitle: Text(formatTime(start)),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: start);
                        if (picked != null) {
                          setDialogState(() {
                            start = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time_filled),
                      title: const Text('Hora de finalización'),
                      subtitle: Text(formatTime(end)),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: end);
                        if (picked != null) {
                          setDialogState(() {
                            end = picked;
                          });
                        }
                      },
                    ),
                    if (timeToMinutes(end) <= timeToMinutes(start))
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'La hora final debe ser posterior a la inicial.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: subjects.isEmpty || timeToMinutes(end) <= timeToMinutes(start)
                      ? null
                      : () => Navigator.pop(context, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    await scheduleProvider.addItem(day: day, subject: subject, startTime: start, endTime: end);

    setState(() {
      selectedDay = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();

    final filtered = scheduleProvider.schedule.where((item) => item.day == selectedDay).toList()
      ..sort((a, b) => timeToMinutes(a.startTime) - timeToMinutes(b.startTime));

    return Stack(
      children: [
        Column(
          children: [
            SizedBox(
              height: 62,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(day),
                      selected: day == selectedDay,
                      onSelected: (_) {
                        setState(() {
                          selectedDay = day;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No tienes clases el $selectedDay.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Container(
                                width: 65,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    Text(formatTime(item.startTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 3),
                                    Text(
                                      formatTime(item.endTime),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${formatTime(item.startTime)} - ${formatTime(item.endTime)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => context.read<ScheduleProvider>().deleteItem(item),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _addSchedule(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva clase'),
          ),
        ),
      ],
    );
  }
}