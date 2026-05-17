import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_wrapper.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/clientes_screen.dart';
import 'screens/productos_screen.dart';
import 'screens/pedidos_screen.dart';
import 'screens/inventario_screen.dart';
import 'screens/categorias_screen.dart';
import 'screens/facturas_screen.dart';
import 'screens/pagos_screen.dart';
import 'screens/rutas_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/usuarios_screen.dart';
import 'screens/perfil_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'DistriOrder',
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (ctx) => const AuthWrapper(),
          '/': (ctx) => const AuthWrapper(),
          '/home': (ctx) => const HomeScreen(),
          '/dashboard': (ctx) => const DashboardScreen(),
          '/clientes': (ctx) => const ClientesScreen(),
          '/productos': (ctx) => const ProductosScreen(),
          '/pedidos': (ctx) => const PedidosScreen(),
          '/inventario': (ctx) => const InventarioScreen(),
          '/categorias': (ctx) => const CategoriasScreen(),
          '/facturas': (ctx) => const FacturasScreen(),
          '/pagos': (ctx) => const PagosScreen(),
          '/rutas': (ctx) => const RutasScreen(),
          '/usuarios': (ctx) => const UsuariosScreen(),
          '/perfil': (ctx) => const PerfilScreen(),
        },
      ),
    );
  }
}