class Constant {
  final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://10.0.2.2:7145/api',
  );
}