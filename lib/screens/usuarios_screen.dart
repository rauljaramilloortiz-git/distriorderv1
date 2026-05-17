import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final _api = ApiService();
  List _usuarios = [];
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
      _filtered = _usuarios.where((u) =>
        (u['nombre'] ?? '').toLowerCase().contains(q) ||
        (u['username'] ?? '').toLowerCase().contains(q) ||
        (u['email'] ?? '').toLowerCase().contains(q)
      ).toList();
    });
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/usuarios/');
      setState(() { _usuarios = res.data; _filtered = res.data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _roleColor(String rol) {
    switch (rol) {
      case 'admin': return Colors.red;
      case 'vendedor': return Colors.blue;
      case 'bodega': return Colors.orange;
      case 'repartidor': return Colors.teal;
      case 'cliente': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(controller: _searchCtrl, decoration: InputDecoration(
              hintText: 'Buscar usuario...', prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.grey[100],
            )),
          ),
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.people, size: 64, color: Colors.grey), SizedBox(height: 8), Text('Sin usuarios', style: TextStyle(color: Colors.grey))])))
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final u = _filtered[i];
                            return ListTile(
                              leading: CircleAvatar(backgroundColor: _roleColor(u['rol'] ?? '')),
                              title: Text(u['nombre'] ?? ''),
                              subtitle: Text('${u['username']} — ${u['email']}'),
                              trailing: Chip(
                                label: Text(u['rol']?.toUpperCase() ?? '', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                backgroundColor: _roleColor(u['rol'] ?? ''),
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