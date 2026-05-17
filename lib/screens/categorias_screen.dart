import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});
  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _api = ApiService();
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
      _filtered = _categorias.where((c) => (c['nombre'] ?? '').toLowerCase().contains(q) || (c['descripcion'] ?? '').toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/categorias/');
      setState(() { _categorias = res.data; _filtered = res.data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showForm([Map? cat]) {
    final isEdit = cat != null;
    final nombreCtrl = TextEditingController(text: cat?['nombre'] ?? '');
    final descCtrl = TextEditingController(text: cat?['descripcion'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Editar Categoría' : 'Nueva Categoría'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 8),
              TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  if (isEdit) await _api.put('/categorias/${cat['id']}', data: {'nombre': nombreCtrl.text, 'descripcion': descCtrl.text});
                  else await _api.post('/categorias/', data: {'nombre': nombreCtrl.text, 'descripcion': descCtrl.text});
                  if (mounted) { Navigator.pop(context); _load(); }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(isEdit ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(), child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(controller: _searchCtrl, decoration: InputDecoration(
              hintText: 'Buscar categoría...', prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.grey[100],
            )),
          ),
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.category, size: 64, color: Colors.grey), SizedBox(height: 8), Text('Sin categorías', style: TextStyle(color: Colors.grey))])))
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final c = _filtered[i];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.category)),
                              title: Text(c['nombre'] ?? ''),
                              subtitle: Text(c['descripcion'] ?? ''),
                              trailing: IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showForm(c)),
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