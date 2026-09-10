import 'package:flutter/material.dart';

import 'grades_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'quiz_builder_screen.dart';
import 'schedule_screen.dart';
import 'subjects_screen.dart';
import 'tasks_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  int _quizOriginIndex = 0;

  final titles = const [
    'Inicio',
    'Horario',
    'Tareas',
    'Quiz',
    'Calificaciones',
    'Materias',
  ];

  void _openQuizBuilder() {
    _quizOriginIndex = selectedIndex;
    setState(() {
      selectedIndex = 3;
    });

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const QuizBuilderScreen()))
        .then((_) {
          if (!mounted) return;
          setState(() {
            selectedIndex = _quizOriginIndex;
          });
        });
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen(key: ValueKey('home'));
      case 1:
        return const ScheduleScreen(key: ValueKey('schedule'));
      case 2:
        return const TasksScreen(key: ValueKey('tasks'));
      case 3:
        return const SizedBox.shrink();
      case 4:
        return const GradesScreen(key: ValueKey('grades'));
      case 5:
        return const SubjectsScreen(key: ValueKey('subjects'));
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _getScreen(selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 3) {
            _openQuizBuilder();
            return;
          }

          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Horario',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tareas',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Calificaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Materias',
          ),
        ],
      ),
    );
  }
}
