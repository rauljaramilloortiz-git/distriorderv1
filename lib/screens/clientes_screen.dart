import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});
  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _api = ApiService();
  List _clientes = [];
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
      _filtered = _clientes.where((c) =>
        (c['razon_social'] ?? '').toLowerCase().contains(q) ||
        (c['nit'] ?? '').toLowerCase().contains(q) ||
        (c['telefono'] ?? '').toLowerCase().contains(q)
      ).toList();
    });
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/clientes/');
      setState(() { _clientes = res.data; _filtered = res.data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showForm([Map? client]) {
    final isEdit = client != null;
    final razonCtrl = TextEditingController(text: client?['razon_social'] ?? '');
    final nitCtrl = TextEditingController(text: client?['nit'] ?? '');
    final telefonoCtrl = TextEditingController(text: client?['telefono'] ?? '');
    final direccionCtrl = TextEditingController(text: client?['direccion'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Editar Cliente' : 'Nuevo Cliente'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: razonCtrl, decoration: const InputDecoration(labelText: 'Razón Social'), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
                const SizedBox(height: 8),
                TextFormField(controller: nitCtrl, decoration: const InputDecoration(labelText: 'NIT')),
                const SizedBox(height: 8),
                TextFormField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
                const SizedBox(height: 8),
                TextFormField(controller: direccionCtrl, decoration: const InputDecoration(labelText: 'Dirección'), maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final data = {'razon_social': razonCtrl.text, 'nit': nitCtrl.text, 'telefono': telefonoCtrl.text, 'direccion': direccionCtrl.text};
                try {
                  if (isEdit) await _api.put('/clientes/${client['id']}', data: data);
                  else await _api.post('/clientes/', data: data);
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
      appBar: AppBar(title: const Text('Clientes'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(), child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(controller: _searchCtrl, decoration: InputDecoration(
              hintText: 'Buscar...', prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.grey[100],
            )),
          ),
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search_off, size: 64, color: Colors.grey), SizedBox(height: 8), Text('Sin resultados', style: TextStyle(color: Colors.grey))])))
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final c = _filtered[i];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(c['razon_social'] ?? ''),
                              subtitle: Text('${c['nit'] ?? 'N/A'} | ${c['telefono'] ?? ''}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(c['activo'] == true ? Icons.check_circle : Icons.cancel, color: c['activo'] == true ? Colors.green : Colors.red),
                                  IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showForm(c)),
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