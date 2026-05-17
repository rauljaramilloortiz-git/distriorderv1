class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String loginUrl = '$baseUrl/auth/login';
  static const String registerUrl = '$baseUrl/auth/register';
  static const String meUrl = '$baseUrl/auth/me';
}

class Roles {
  static const String admin = 'admin';
  static const String vendedor = 'vendedor';
  static const String bodega = 'bodega';
  static const String repartidor = 'repartidor';
  static const String cliente = 'cliente';
}