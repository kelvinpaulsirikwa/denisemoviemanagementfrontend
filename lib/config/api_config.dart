class ApiConfig {
  static const String domain='http://10.0.2.2:8006';
  static const String baseUrl = '$domain/api';
  static const String publicUrl = '$domain';
  static const String loginEndpoint = '$baseUrl/login';
  static const String categoriesEndpoint = '$baseUrl/categories';
  static const String studiosEndpoint = '$baseUrl/studios';
  static const String storageUrl = '$publicUrl/storage';
}
