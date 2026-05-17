import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FacturasScreen extends StatefulWidget {
  const FacturasScreen({super.key});
  @override
  State<FacturasScreen> createState() => _FacturasScreenState();
}

class _FacturasScreenState extends State<FacturasScreen> {
  final _api = ApiService();
  List _facturas = [];
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
      _filtered = _facturas.where((f) => (f['numero'] ?? '').toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/facturas/');
      setState(() { _facturas = res.data; _filtered = res.data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facturas'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(controller: _searchCtrl, decoration: InputDecoration(
              hintText: 'Buscar por número...', prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.grey[100],
            )),
          ),
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.receipt_long, size: 64, color: Colors.grey), SizedBox(height: 8), Text('Sin facturas', style: TextStyle(color: Colors.grey))])))
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final f = _filtered[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                                title: Text(f['numero'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Total: \$${f['total']} | Fecha: ${f['fecha_emision'] ?? 'N/A'}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Sub: \$${f['subtotal']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text('IVA: \$${f['impuesto']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
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