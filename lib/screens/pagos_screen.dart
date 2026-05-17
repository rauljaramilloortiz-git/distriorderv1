import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});
  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  final _api = ApiService();
  List _pagos = [];
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
      _filtered = _pagos.where((p) =>
        'pedido #${p['pedido_id']}'.contains(q) ||
        (p['metodo'] ?? '').toLowerCase().contains(q) ||
        (p['referencia'] ?? '').toLowerCase().contains(q)
      ).toList();
    });
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/pagos/');
      setState(() { _pagos = res.data; _filtered = res.data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(controller: _searchCtrl, decoration: InputDecoration(
              hintText: 'Buscar por pedido o referencia...', prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.grey[100],
            )),
          ),
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
                  ? const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.payment, size: 64, color: Colors.grey), SizedBox(height: 8), Text('Sin pagos registrados', style: TextStyle(color: Colors.grey))])))
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.payment)),
                                title: Text('Pedido #${p['pedido_id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('\$${p['monto']} — ${p['metodo']} | Ref: ${p['referencia'] ?? 'N/A'}'),
                                trailing: Text(p['fecha_pago']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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