import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});
  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tab;
  List? _ventas;
  List? _topProds;
  List? _estados;
  Map? _resumen;
  bool _loading = true;

  // Filtros fechas
  DateTime? _desde;
  DateTime? _hasta;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{};
      if (_desde != null) params['desde'] = DateFormat('yyyy-MM-dd').format(_desde!);
      if (_hasta != null) params['hasta'] = DateFormat('yyyy-MM-dd').format(_hasta!);

      final r1 = _api.get('/reportes/ventas${params.isNotEmpty ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}' : ''}');
      final r2 = _api.get('/reportes/top-productos');
      final r3 = _api.get('/reportes/pedidos-por-estado');
      final r4 = _api.get('/reportes/resumen-mensual');
      final res = await Future.wait([r1, r2, r3, r4]);
      setState(() {
        _ventas = res[0].data['detalle'];
        _topProds = res[1].data;
        _estados = res[2].data;
        _resumen = res[3].data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showDateFilter() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Filtrar por fechas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(_desde != null ? DateFormat('yyyy-MM-dd').format(_desde!) : 'Desde'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _desde ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                if (d != null) setState(() => _desde = d);
              },
            ),
            ListTile(
              title: Text(_hasta != null ? DateFormat('yyyy-MM-dd').format(_hasta!) : 'Hasta'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _hasta ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                if (d != null) setState(() => _hasta = d);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () { setState(() { _desde = null; _hasta = null; }); Navigator.pop(context); _load(); }, child: const Text('Limpiar')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _load(); }, child: const Text('Aplicar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.date_range), onPressed: _showDateFilter)],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Ventas'), Tab(text: 'Top'), Tab(text: 'Estados'), Tab(text: 'Resumen')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tab,
                children: [_buildVentas(), _buildTop(), _buildEstados(), _buildResumen()],
              ),
            ),
    );
  }

  Widget _buildVentas() {
    if (_ventas == null || _ventas!.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bar_chart, size: 64, color: Colors.grey), SizedBox(height: 8), Text('Sin datos de ventas', style: TextStyle(color: Colors.grey))]));
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _ventas!.length,
      itemBuilder: (_, i) {
        final v = _ventas![i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('#${v['id']}')),
            title: Text('Pedido #${v['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Fecha: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(v['fecha']))}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${NumberFormat('#,##0.00').format(v['total'])}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Chip(label: Text(v['estado'].toString().toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.white)), backgroundColor: _colorEstado(v['estado'])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTop() {
    if (_topProds == null || _topProds!.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.leaderboard, size: 64, color: Colors.grey), SizedBox(height: 8), Text('Sin datos', style: TextStyle(color: Colors.grey))]));
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _topProds!.length,
      itemBuilder: (_, i) {
        final p = _topProds![i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: i < 3 ? [Colors.amber, Colors.grey, Colors.orange][i] : Colors.blue, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            title: Text(p['nombre'] ?? ''),
            subtitle: Text('Ventas: ${p['total_vendido']}'),
            trailing: Text('\$${NumberFormat('#,##0').format(p['ingresos'])}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        );
      },
    );
  }

  Widget _buildEstados() {
    if (_estados == null) return const Center(child: Text('Sin datos'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _estados!.length,
      itemBuilder: (_, i) {
        final e = _estados![i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(width: 12, height: 40, color: _colorEstado(e['estado'])),
              const SizedBox(width: 12),
              Expanded(child: Text(e['estado'].toString().replaceAll('_', ' ').toUpperCase())),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: _colorEstado(e['estado']).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text('${e['cantidad']}', style: TextStyle(fontWeight: FontWeight.bold, color: _colorEstado(e['estado']), fontSize: 18)),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildResumen() {
    if (_resumen == null) return const Center(child: Text('Sin datos'));
    final fmt = NumberFormat('#,##0.00');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mes actual', style: Theme.of(context).textTheme.titleMedium),
                const Divider(),
                _row('Pedidos', '${_resumen!['pedidos']}'),
                _row('Total ventas', '\$${fmt.format(_resumen!['total'])}'),
                _row('Facturado', '\$${fmt.format(_resumen!['facturado'])}'),
                _row('Cobrado', '\$${fmt.format(_resumen!['cobrado'])}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
    ),
  );

  Color _colorEstado(String e) {
    switch (e) {
      case 'pendiente': return Colors.orange;
      case 'confirmado': return Colors.blue;
      case 'en_preparacion': return Colors.purple;
      case 'en_ruta': return Colors.teal;
      case 'entregado': return Colors.green;
      case 'cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }
}