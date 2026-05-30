enum Environment { dev, staging, prod }

class AppConfig {
  const AppConfig._({required this.environment, required this.appName});

  final Environment environment;
  final String appName;

  static AppConfig? _instance;

  static AppConfig get instance {
    assert(
      _instance != null,
      'AppConfig.initialize() must be called before accessing instance',
    );
    return _instance!;
  }

  static void initialize(Environment environment) {
    _instance = AppConfig._(
      environment: environment,
      appName: environment == Environment.prod
          ? 'Nightingale'
          : 'Nightingale (${environment.name})',
    );
  }

  bool get isDebug => environment == Environment.dev;
  bool get isProduction => environment == Environment.prod;
}
