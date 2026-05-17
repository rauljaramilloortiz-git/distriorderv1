import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final String route;
  final List<String> allowedRoles;
  const MenuItem(this.title, this.icon, this.route, this.allowedRoles);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<MenuItem> _items = const [
    MenuItem('Dashboard', Icons.dashboard, '/dashboard', ['admin', 'vendedor']),
    MenuItem('Clientes', Icons.people, '/clientes', ['admin', 'vendedor']),
    MenuItem('Productos', Icons.inventory_2, '/productos', ['admin', 'vendedor', 'bodega']),
    MenuItem('Categorías', Icons.category, '/categorias', ['admin', 'bodega']),
    MenuItem('Inventario', Icons.warehouse, '/inventario', ['admin', 'bodega', 'vendedor']),
    MenuItem('Pedidos', Icons.shopping_cart, '/pedidos', ['admin', 'vendedor', 'cliente']),
    MenuItem('Facturas', Icons.receipt_long, '/facturas', ['admin', 'vendedor']),
    MenuItem('Pagos', Icons.payment, '/pagos', ['admin', 'vendedor']),
    MenuItem('Rutas', Icons.local_shipping, '/rutas', ['admin', 'repartidor']),
    MenuItem('Reportes', Icons.bar_chart, '/reportes', ['admin', 'vendedor']),
    MenuItem('Usuarios', Icons.admin_panel_settings, '/usuarios', ['admin']),
    MenuItem('Mi Perfil', Icons.account_circle, '/perfil', ['admin', 'vendedor', 'bodega', 'repartidor', 'cliente']),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final rol = user?['rol'] ?? '';
    final visible = _items.where((i) => i.allowedRoles.contains(rol)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, ${user?['nombre'] ?? ''}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _showLogoutDialog(context, auth)),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1),
        itemCount: visible.length,
        itemBuilder: (_, i) {
          final item = visible[i];
          return Card(
            elevation: 3,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, item.route),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 48, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(rol.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
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