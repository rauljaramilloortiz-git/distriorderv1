import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});
  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _api = ApiService();
  List _productos = [];
  List _categorias = [];
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
      _filtered = _productos.where((p) =>
        (p['nombre'] ?? '').toLowerCase().contains(q) ||
        (p['sku'] ?? '').toLowerCase().contains(q)
      ).toList();
    });
  }

  Future<void> _load() async {
    try {
      final prods = await _api.get('/productos/');
      final cats = await _api.get('/categorias/');
      setState(() { _productos = prods.data; _categorias = cats.data; _filtered = prods.data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _catName(int? id) {
    if (id == null) return 'Sin categoría';
    final c = _categorias.where((c) => c['id'] == id).firstOrNull;
    return c?['nombre'] ?? 'Cat #$id';
  }

  void _showForm([Map? prod]) {
    final isEdit = prod != null;
    final nombreCtrl = TextEditingController(text: prod?['nombre'] ?? '');
    final descCtrl = TextEditingController(text: prod?['descripcion'] ?? '');
    final precioCtrl = TextEditingController(text: prod?['precio']?.toString() ?? '');
    final skuCtrl = TextEditingController(text: prod?['sku'] ?? '');
    int? selectedCat = prod?['categoria_id'];
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(isEdit ? 'Editar Producto' : 'Nuevo Producto'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 8),
                  TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 2),
                  const SizedBox(height: 8),
                  TextFormField(controller: precioCtrl, decoration: const InputDecoration(labelText: 'Precio'), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
                  const SizedBox(height: 8),
                  TextFormField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: selectedCat,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Sin categoría')),
                      ..._categorias.map((c) => DropdownMenuItem<int?>(value: c['id'] as int, child: Text(c['nombre']))),
                    ],
                    onChanged: (v) => setDialog(() => selectedCat = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final data = {'nombre': nombreCtrl.text, 'descripcion': descCtrl.text, 'precio': double.parse(precioCtrl.text), 'sku': skuCtrl.text, 'categoria_id': selectedCat};
                  try {
                    if (isEdit) await _api.put('/productos/${prod['id']}', data: data);
                    else await _api.post('/productos/', data: data);
                    if (mounted) { Navigator.pop(ctx); _load(); }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Text(isEdit ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(), child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(controller: _searchCtrl, decoration: InputDecoration(
              hintText: 'Buscar por nombre o SKU...', prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.grey[100],
            )),
          ),
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2, size: 64, color: Colors.grey), SizedBox(height: 8), Text('Sin productos', style: TextStyle(color: Colors.grey))])))
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.inventory_2)),
                              title: Text(p['nombre'] ?? ''),
                              subtitle: Text('\$${p['precio']} | ${_catName(p['categoria_id'])} | SKU: ${p['sku'] ?? 'N/A'}'),
                              trailing: IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showForm(p)),
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