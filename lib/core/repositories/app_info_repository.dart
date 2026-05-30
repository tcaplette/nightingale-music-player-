import 'package:nightingale/core/config/env_config.dart';
import 'package:nightingale/core/repositories/base_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract interface class AppInfoRepository implements Repository {
  Future<String> getVersion();
  Future<String> getBuildNumber();
  Environment getEnvironment();
}

class PackageInfoAppInfoRepository implements AppInfoRepository {
  PackageInfoAppInfoRepository(this._config);

  final AppConfig _config;
  PackageInfo? _packageInfo;

  Future<PackageInfo> _info() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!;
  }

  @override
  Future<String> getVersion() async => (await _info()).version;

  @override
  Future<String> getBuildNumber() async => (await _info()).buildNumber;

  @override
  Environment getEnvironment() => _config.environment;
}
