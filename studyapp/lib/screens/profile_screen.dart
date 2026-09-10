import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 15),
          CircleAvatar(radius: 45, child: Icon(Icons.person, size: 48)),
          SizedBox(height: 15),
          Center(child: Text('Estudiante', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold))),
          SizedBox(height: 5),
          Center(child: Text('6.º de Secundaria')),
          SizedBox(height: 30),
          _ProfileItem(icon: Icons.school_outlined, title: 'Curso', value: '6.º de Secundaria'),
          _ProfileItem(icon: Icons.storage_outlined, title: 'Almacenamiento', value: 'Local (SQLite)'),
          _ProfileItem(icon: Icons.cloud_done_outlined, title: 'Sincronización', value: 'Próximamente'),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileItem({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 15),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}