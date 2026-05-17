import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});
  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final _api = ApiService();
  List _pedidos = [];
  List _clientes = [];
  List _productos = [];
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
      _filtered = _pedidos.where((p) {
        final matchQ = q.isEmpty || '#${p['id']}'.contains(q) || _clienteName(p['cliente_id']).toLowerCase().contains(q);
        final matchE = _filterEstado == 'todos' || p['estado'] == _filterEstado;
        return matchQ && matchE;
      }).toList();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r1 = await _api.get('/pedidos/');
      final r2 = await _api.get('/clientes/');
      final r3 = await _api.get('/productos/');
      setState(() { _pedidos = r1.data; _clientes = r2.data; _productos = r3.data; _filtered = r1.data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showApiError(context, e);
    }
  }

  String _clienteName(int? id) {
    if (id == null) return 'N/A';
    final c = _clientes.where((c) => c['id'] == id).firstOrNull;
    return c?['razon_social'] ?? '#$id';
  }

  List<String> _nextStates(String estado) {
    switch (estado) {
      case 'pendiente': return ['confirmado', 'cancelado'];
      case 'confirmado': return ['en_preparacion', 'cancelado'];
      case 'en_preparacion': return ['en_ruta', 'cancelado'];
      case 'en_ruta': return ['entregado', 'cancelado'];
      default: return [];
    }
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'pendiente': return Colors.orange;
      case 'confirmado': return Colors.blue;
      case 'en_preparacion': return Colors.purple;
      case 'en_ruta': return Colors.teal;
      case 'entregado': return Colors.green;
      case 'cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _estadoLabel(String estado) => estado.replaceAll('_', ' ').toUpperCase();

  void _showDetail(Map p) {
    final next = _nextStates(p['estado'] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pedido #${p['id']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Chip(label: Text(_estadoLabel(p['estado'] ?? ''), style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: _estadoColor(p['estado'] ?? '')),
              ],
            ),
            const Divider(),
            _detailRow('Cliente', _clienteName(p['cliente_id'])),
            _detailRow('Total', '\$${p['total']}'),
            _detailRow('Fecha', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(p['created_at'] ?? DateTime.now().toString()))),
            if (p['observaciones'] != null && p['observaciones'].toString().isNotEmpty)
              _detailRow('Observaciones', p['observaciones'].toString()),
            if (p['repartidor_id'] != null)
              _detailRow('Repartidor', '#${p['repartidor_id']}'),
            if (next.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Actualizar estado:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: next.map((s) => ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _cambiarEstado(p['id'], s);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _estadoColor(s),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_estadoLabel(s)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cambiarEstado(int pedidoId, String nuevoEstado) async {
    try {
      await _api.put('/pedidos/$pedidoId', data: {'estado': nuevoEstado});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pedido #${pedidoId} → ${_estadoLabel(nuevoEstado)}'), backgroundColor: Colors.green));
      _load();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 13)), const SizedBox(width: 8), Expanded(child: Text(value, style: const TextStyle(fontSize: 14)))],
    ),
  );

  void _showCreateForm() {
    int? selectedCliente;
    final detalles = <Map>[];
    final obsCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) {
          return AlertDialog(
            title: const Text('Nuevo Pedido'),
            content: SizedBox(
              width: MediaQuery.of(ctx).size.width * 0.7,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int?>(
                        value: selectedCliente,
                        decoration: const InputDecoration(labelText: 'Cliente *'),
                        items: _clientes.map((c) => DropdownMenuItem<int?>(value: c['id'] as int, child: Text(c['razon_social'] ?? ''))).toList(),
                        onChanged: (v) => setDialog(() => selectedCliente = v),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Detalles:', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (detalles.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Sin productos', style: TextStyle(color: Colors.grey)))
                      else ...detalles.asMap().entries.map((e) {
                        final det = e.value;
                        final prod = _productos.where((p) => p['id'] == det['producto_id']).firstOrNull;
                        return ListTile(
                          dense: true,
                          title: Text(prod?['nombre'] ?? 'Producto #${det['producto_id']}'),
                          subtitle: Text('Cant: ${det['cantidad']}'),
                          trailing: IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () => setDialog(() => detalles.removeAt(e.key))),
                        );
                      }),
                      OutlinedButton.icon(onPressed: () => _addDetalle(ctx, (d) => setDialog(() => detalles.add(d))), icon: const Icon(Icons.add), label: const Text('Agregar producto')),
                      const SizedBox(height: 8),
                      TextFormField(controller: obsCtrl, decoration: const InputDecoration(labelText: 'Observaciones'), maxLines: 2),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (detalles.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Agrega al menos un producto')));
                      return;
                    }
                    try {
                      await _api.post('/pedidos/', data: {'cliente_id': selectedCliente, 'observaciones': obsCtrl.text, 'detalles': detalles});
                      if (mounted) { Navigator.pop(ctx); _load(); }
                    } catch (e) {
                      if (mounted) showApiError(context, e);
                    }
                  }
                },
                child: const Text('Crear'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addDetalle(BuildContext ctx, Function(Map) onAdd) {
    int? prodId;
    int qty = 1;
    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setD) => AlertDialog(
          title: const Text('Agregar producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int?>(
                value: prodId,
                decoration: const InputDecoration(labelText: 'Producto'),
                items: _productos.map((p) => DropdownMenuItem<int?>(value: p['id'] as int, child: Text('${p['nombre']} - \$${p['precio']}'))).toList(),
                onChanged: (v) => setD(() => prodId = v),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Cantidad:'),
                IconButton(icon: const Icon(Icons.remove), onPressed: qty > 1 ? () => setD(() => qty--) : null),
                Text('$qty'),
                IconButton(icon: const Icon(Icons.add), onPressed: () => setD(() => qty++)),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Cancelar')),
            ElevatedButton(onPressed: prodId != null ? () { onAdd({'producto_id': prodId, 'cantidad': qty}); Navigator.pop(ctx2); } : null, child: const Text('Agregar')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: _showCreateForm, child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(child: TextField(controller: _searchCtrl, decoration: InputDecoration(
                hintText: 'Buscar pedido...', prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true, fillColor: Colors.grey[100],
              ))),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                initialValue: _filterEstado,
                onSelected: (v) { setState(() => _filterEstado = v); _applyFilter(); },
                itemBuilder: (_) => ['todos', 'pendiente', 'confirmado', 'en_preparacion', 'en_ruta', 'entregado', 'cancelado']
                    .map((e) => PopupMenuItem(value: e, child: Text(e == 'todos' ? 'Todos' : _estadoLabel(e)))).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [const Icon(Icons.filter_list, size: 20), const SizedBox(width: 4), Text(_filterEstado == 'todos' ? 'Filtro' : _estadoLabel(_filterEstado), style: const TextStyle(fontSize: 13))]),
                ),
              ),
            ]),
          ),
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shopping_cart, size: 64, color: Colors.grey), SizedBox(height: 8), Text('Sin pedidos', style: TextStyle(color: Colors.grey))])))
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: InkWell(
                                onTap: () => _showDetail(p),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(children: [
                                    CircleAvatar(backgroundColor: _estadoColor(p['estado'] ?? ''), radius: 20, child: Text('#${p['id']}', style: const TextStyle(color: Colors.white, fontSize: 11))),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('#${p['id']} - ${_clienteName(p['cliente_id'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('\$${p['total']} | ${DateFormat('MMM dd').format(DateTime.parse(p['created_at'] ?? DateTime.now().toString()))}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ])),
                                    Chip(label: Text(_estadoLabel(p['estado'] ?? ''), style: const TextStyle(fontSize: 8, color: Colors.white)), backgroundColor: _estadoColor(p['estado'] ?? '')),
                                  ]),
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