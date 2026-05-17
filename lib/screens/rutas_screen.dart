import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RutasScreen extends StatefulWidget {
  const RutasScreen({super.key});
  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  final _api = ApiService();
  List _rutas = [];
  List _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _filterEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() => _applyFilter();

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _rutas.where((r) {
        final matchQ = q.isEmpty || '#${r['pedido_id']}'.contains(q);
        final matchE = _filterEstado == 'todos' || r['estado'] == _filterEstado;
        return matchQ && matchE;
      }).toList();
    });
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/rutas/');
      setState(() { _rutas = res.data; _filtered = res.data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'programada': return Colors.blue;
      case 'en_camino': return Colors.orange;
      case 'entregada': return Colors.green;
      case 'cancelada': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutas de Entrega'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(child: TextField(controller: _searchCtrl, decoration: InputDecoration(
                hintText: 'Buscar ruta...', prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true, fillColor: Colors.grey[100],
              ))),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                initialValue: _filterEstado,
                onSelected: (v) { setState(() => _filterEstado = v); _applyFilter(); },
                itemBuilder: (_) => ['todos', 'programada', 'en_camino', 'entregada', 'cancelada']
                    .map((e) => PopupMenuItem(value: e, child: Text(e == 'todos' ? 'Todos' : e.replaceAll('_', ' ').toUpperCase()))).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [const Icon(Icons.filter_list, size: 20), const SizedBox(width: 4), Text(_filterEstado == 'todos' ? 'Filtro' : _filterEstado.toUpperCase(), style: const TextStyle(fontSize: 13))]),
                ),
              ),
            ]),
          ),
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.local_shipping, size: 64, color: Colors.grey), SizedBox(height: 8), Text('Sin rutas', style: TextStyle(color: Colors.grey))])))
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final r = _filtered[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: _estadoColor(r['estado'] ?? ''), child: const Icon(Icons.local_shipping, color: Colors.white, size: 20)),
                                title: Text('Pedido #${r['pedido_id']}'),
                                subtitle: Text('Repartidor #${r['repartidor_id']} | ${r['fecha_salida']?.toString().substring(0, 16) ?? 'Sin fecha'}'),
                                trailing: Chip(
                                  label: Text(r['estado']?.toUpperCase() ?? '', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: _estadoColor(r['estado'] ?? ''),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}