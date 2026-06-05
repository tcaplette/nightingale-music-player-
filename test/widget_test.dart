import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nightingale/core/config/env_config.dart';
import 'package:nightingale/core/crash_reporting/crash_reporter.dart';
import 'package:nightingale/core/crypto/platform_crypto_service.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/debug/network_inspector.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/federation/nightingale_actor_validator.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/core/repositories/activity_repository.dart';
import 'package:nightingale/core/repositories/app_info_repository.dart';
import 'package:nightingale/core/repositories/social_repository.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';
import 'package:nightingale/features/federation/moderation/moderation_repository.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_service.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/library/library_repository_impl.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';
import 'package:nightingale/features/node_identity/node_identity_repository_impl.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';
import 'package:nightingale/features/social/activity_repository_impl.dart';
import 'package:nightingale/features/social/social_repository_impl.dart';
import 'package:nightingale/app.dart';

final GetIt _sl = GetIt.instance;
AppDatabase? _testDb;

Future<void> _setupTestServiceLocator() async {
  if (_sl.isRegistered<CrashReporter>()) return;

  FlutterSecureStorage.setMockInitialValues({});

  _sl.registerSingleton<CrashReporter>(const NullCrashReporter());
  _sl.registerSingleton<NetworkInspector>(const NetworkInspector());
  _sl.registerSingleton<AppInfoRepository>(
    PackageInfoAppInfoRepository(AppConfig.instance),
  );
  _sl.registerSingleton<SecureStorageService>(
    FlutterSecureStorageService(),
  );

  // Use in-memory database — no path_provider needed
  _testDb = AppDatabase(NativeDatabase.memory());
  _sl.registerSingleton<AppDatabase>(_testDb!);
  _sl.registerSingleton<LibraryRepository>(LibraryRepositoryImpl(db: _testDb!));

  // Crypto & identity (required by router redirect)
  final crypto = PlatformCryptoService();
  await crypto.generateKeyPair();
  _sl.registerSingleton<NodeIdentityRepository>(
    NodeIdentityRepositoryImpl(
      db: _testDb!,
      crypto: crypto,
    ),
  );

  // Minimal federation infrastructure required by providers
  final moderation = ModerationRepository(db: _testDb!);
  final sig = HttpSignatureService(
    crypto: crypto,
    keyId: 'http://localhost/users/node#main-key',
  );
  final delivery = ActivityDeliveryService(
    db: _testDb!,
    sigService: sig,
    moderation: moderation,
  );
  final actorResolver = ActorResolver(db: _testDb!);
  _sl.registerSingleton<ModerationRepository>(moderation);
  _sl.registerSingleton<HttpSignatureService>(sig);
  _sl.registerSingleton<ActivityDeliveryService>(delivery);
  _sl.registerSingleton<ActorResolver>(actorResolver);
  _sl.registerSingleton<NodeReachabilityService>(NodeReachabilityService());

  // Phase 5 social repositories
  _sl.registerSingleton<NightingaleActorValidator>(const NightingaleActorValidator());
  _sl.registerSingleton<SocialRepository>(
    SocialRepositoryImpl(
      db: _testDb!,
      delivery: delivery,
      actorResolver: actorResolver,
      identityRepo: _sl<NodeIdentityRepository>(),
      moderation: moderation,
      validator: _sl<NightingaleActorValidator>(),
    ),
  );
  _sl.registerSingleton<ActivityRepository>(
    ActivityRepositoryImpl(
      db: _testDb!,
      delivery: delivery,
      identityRepo: _sl<NodeIdentityRepository>(),
      nodeBaseUrl: 'http://localhost',
    ),
  );

  AppLogger.initialize(_sl<CrashReporter>());
}

void main() {
  setUpAll(() async {
    AppConfig.initialize(Environment.dev);
    await _setupTestServiceLocator();
  });

  tearDownAll(() async {
    await _testDb?.close();
    await _sl.reset();
  });

  testWidgets('NightingaleApp smoke test — renders without exception', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const NightingaleApp());
      await tester.pump();
      // Drain pending async operations (Drift queries, provider loads).
      await Future.delayed(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('Library'), findsWidgets);
      // Replace the full app with an empty widget so Riverpod/Drift
      // stream subscriptions are cancelled before test cleanup, then
      // pump once more to let the zero-duration Drift timers fire.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
