class AppConfig {
  const AppConfig._();

  static const appName = 'Serigraff';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
  static const requestTimeout = Duration(seconds: 20);
}
