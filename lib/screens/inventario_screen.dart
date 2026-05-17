import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});
  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _api = ApiService();
  List _inventario = [];
  List _productos = [];
  List _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

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

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _inventario.where((inv) {
        final name = _prodName(inv['producto_id']).toLowerCase();
        return name.contains(q) || 'producto #${inv['producto_id']}'.contains(q);
      }).toList();
    });
  }

  Future<void> _load() async {
    try {
      final r1 = await _api.get('/inventario/');
      final r2 = await _api.get('/productos/');
      setState(() { _inventario = r1.data; _productos = r2.data; _filtered = r1.data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _prodName(int id) {
    final p = _productos.where((p) => p['id'] == id).firstOrNull;
    return p?['nombre'] ?? 'Producto #$id';
  }

  void _showEdit(Map inv) {
    final qtyCtrl = TextEditingController(text: inv['cantidad'].toString());
    final minCtrl = TextEditingController(text: inv['stock_minimo'].toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar ${_prodName(inv['producto_id'])}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Cantidad actual'), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 8),
              TextFormField(controller: minCtrl, decoration: const InputDecoration(labelText: 'Stock mínimo'), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _api.put('/inventario/${inv['producto_id']}', data: {'cantidad': int.parse(qtyCtrl.text), 'stock_minimo': int.parse(minCtrl.text)});
                  if (mounted) { Navigator.pop(context); _load(); }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(controller: _searchCtrl, decoration: InputDecoration(
              hintText: 'Buscar producto...', prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.grey[100],
            )),
          ),
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.warehouse, size: 64, color: Colors.grey), SizedBox(height: 8), Text('Sin inventario', style: TextStyle(color: Colors.grey))])))
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final inv = _filtered[i];
                            final bajo = (inv['cantidad'] as int) <= (inv['stock_minimo'] as int);
                            return ListTile(
                              leading: Icon(bajo ? Icons.warning : Icons.inventory, color: bajo ? Colors.red : Colors.blue),
                              title: Text(_prodName(inv['producto_id'])),
                              subtitle: Text('Stock: ${inv['cantidad']} | Mínimo: ${inv['stock_minimo']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (bajo) const Chip(label: Text('BAJO', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.red),
                                  IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showEdit(inv)),
                                ],
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