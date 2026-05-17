import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _api = ApiService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(radius: 50, backgroundColor: Colors.blue, child: Text(user?['nombre']?.toString().substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(fontSize: 36, color: Colors.white))),
            const SizedBox(height: 16),
            Text(user?['nombre'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Chip(
              label: Text(user?['rol']?.toString().toUpperCase() ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
              backgroundColor: _roleColor(user?['rol'] ?? ''),
            ),
            const SizedBox(height: 24),
            _infoTile(Icons.person, 'Usuario', user?['username'] ?? ''),
            _infoTile(Icons.email, 'Email', user?['email'] ?? ''),
            _infoTile(Icons.badge, 'Rol', user?['rol'] ?? ''),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context, auth),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Color _roleColor(String rol) {
    switch (rol) {
      case 'admin': return Colors.red;
      case 'vendedor': return Colors.blue;
      case 'bodega': return Colors.orange;
      case 'repartidor': return Colors.teal;
      case 'cliente': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}