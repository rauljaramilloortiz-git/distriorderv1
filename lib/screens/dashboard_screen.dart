import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _stats;
  List _pedidosMes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _api.get('/dashboard/stats');
      final p = await _api.get('/dashboard/pedidos-mes');
      setState(() { _stats = s.data; _pedidosMes = [p.data]; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen General', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _statCard('Clientes Totales', '${_stats?['total_clientes'] ?? 0}', Icons.people, Colors.blue),
                        _statCard('Pedidos Totales', '${_stats?['total_pedidos'] ?? 0}', Icons.shopping_cart, Colors.green),
                        _statCard('Pendientes', '${_stats?['pedidos_pendientes'] ?? 0}', Icons.pending_actions, Colors.orange),
                        _statCard('Stock Bajo', '${_stats?['productos_bajos_stock'] ?? 0}', Icons.warning, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Este Mes', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (_pedidosMes.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.blue, size: 40),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pedidos: ${_pedidosMes.first['cantidad'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text('Total: \$${NumberFormat('#,##0.00').format(_pedidosMes.first['total'] ?? 0)}', style: const TextStyle(fontSize: 14, color: Colors.green)),
                                  Text('Fecha: ${DateFormat('MMMM yyyy').format(DateTime.now())}', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Card(
                        child: Padding(padding: EdgeInsets.all(16), child: Text('Sin datos este mes')),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}