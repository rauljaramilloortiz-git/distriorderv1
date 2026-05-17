import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../config/api_constants.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _user;
  String? _token;
  bool _loading = false;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  bool get isLoggedIn => _token != null;

  Future<bool> login(String username, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.post('/auth/login', data: {'username': username, 'password': password});
      _token = res.data['access_token'];
      await _api.saveToken(_token!);
      await _loadUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadUser() async {
    final res = await _api.get('/auth/me');
    _user = res.data;
  }

  Future<void> logout() async {
    await _api.clearToken();
    _token = null;
    _user = null;
    notifyListeners();
  }

  bool get isAdmin => _user?['rol'] == Roles.admin;
  bool get isVendedor => _user?['rol'] == Roles.vendedor;
  bool get isBodega => _user?['rol'] == Roles.bodega;
  bool get isRepartidor => _user?['rol'] == Roles.repartidor;
  bool get isCliente => _user?['rol'] == Roles.cliente;
}