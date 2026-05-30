import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:nightingale/core/audio/playback_engine.dart';
import 'package:nightingale/core/config/env_config.dart';
import 'package:nightingale/core/crash_reporting/crash_reporter.dart';
import 'package:nightingale/core/crypto/crypto_service.dart';
import 'package:nightingale/core/crypto/platform_crypto_service.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/debug/debug_overlay_setup.dart';
import 'package:nightingale/core/debug/network_inspector.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/federation/http_signature_service.dart';
import 'package:nightingale/core/http_server/federation_router.dart';
import 'package:nightingale/core/http_server/federation_server.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/core/repositories/app_info_repository.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';
import 'package:nightingale/features/federation/delivery/relay_client.dart';
import 'package:nightingale/features/federation/moderation/moderation_repository.dart';
import 'package:nightingale/features/federation/moderation/rate_limiter.dart';
import 'package:nightingale/features/federation/deduplication/acoustic_fingerprint_service.dart';
import 'package:nightingale/features/federation/library/remote_library_fetcher.dart';
import 'package:nightingale/features/federation/publishing/library_publisher.dart';
import 'package:nightingale/features/federation/publishing/listen_activity_publisher.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_service.dart';
import 'package:nightingale/core/repositories/activity_repository.dart';
import 'package:nightingale/core/repositories/social_repository.dart';
import 'package:nightingale/features/federation/social/social_subscribing_service.dart';
import 'package:nightingale/features/federation/streaming/audio_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/stream_resolver.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/library/library_repository_impl.dart';
import 'package:nightingale/features/node_identity/migration_service.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';
import 'package:nightingale/features/node_identity/node_identity_repository_impl.dart';
import 'package:nightingale/features/recommendations/data/cold_start_settings_repository.dart';
import 'package:nightingale/features/recommendations/data/global_trending_relay_service.dart';
import 'package:nightingale/features/recommendations/data/network_signal_ingester.dart';
import 'package:nightingale/features/recommendations/data/node_discovery_service.dart';
import 'package:nightingale/features/recommendations/data/playback_signal_capturer.dart';
import 'package:nightingale/features/recommendations/data/signal_repository.dart';
import 'package:nightingale/features/recommendations/data/encrypted_signal_store.dart';
import 'package:nightingale/features/recommendations/data/taste_profile_key_store.dart';
import 'package:nightingale/features/recommendations/domain/cold_start_repository.dart';
import 'package:nightingale/features/social/activity_repository_impl.dart';
import 'package:nightingale/core/resilience/activity_queue_service.dart';
import 'package:nightingale/core/resilience/database_integrity_service.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';
import 'package:nightingale/features/social/social_repository_impl.dart';

final GetIt _sl = GetIt.instance;

T sl<T extends Object>() => _sl<T>();

// Relay base URL — empty means relay is not configured.
// Override via environment variable or build config in production.
const _kRelayBaseUrl = String.fromEnvironment('RELAY_BASE_URL', defaultValue: '');

// Node base URL — used to construct actor and endpoint URLs.
const _kNodeBaseUrl = String.fromEnvironment(
  'NODE_BASE_URL',
  defaultValue: 'http://localhost',
);

Future<void> setupServiceLocator() async {
  developer.log('DI: start', name: 'nightingale.di');
  _sl.registerSingleton<CrashReporter>(const NullCrashReporter());
  _sl.registerSingleton<SecureStorageService>(FlutterSecureStorageService());
  _sl.registerSingleton<NetworkInspector>(const NetworkInspector());
  _sl.registerSingleton<AppInfoRepository>(
    PackageInfoAppInfoRepository(AppConfig.instance),
  );
  developer.log('DI: basics registered', name: 'nightingale.di');

  // Database (unencrypted for music catalog; federation tables added in Phase 3 migration)
  final db = AppDatabase();
  _sl.registerSingleton<AppDatabase>(db);
  developer.log('DI: database registered', name: 'nightingale.di');

  // Phase 7 — DB integrity check on every startup (read-only; no schema change needed)
  final dbIntegrity = DatabaseIntegrityService(db: db);
  _sl.registerSingleton<DatabaseIntegrityService>(dbIntegrity);
  final integrityResult = await dbIntegrity.checkAndRepair();
  if (integrityResult == IntegrityCheckResult.unrecoverable) {
    // Signal to the app layer that a user-prompted rescan is required.
    // The app reads this flag from the service locator during first render.
    AppLogger.error('DB unrecoverable at startup — rescan required', tag: 'di');
  }
  developer.log('DI: integrity check = $integrityResult', name: 'nightingale.di');

  // Library
  _sl.registerSingleton<LibraryRepository>(
    LibraryRepositoryImpl(db: db),
  );
  developer.log('DI: library repo registered', name: 'nightingale.di');

  // Playback engine (async init — creates AudioPlayer, configures AudioSession)
  developer.log('DI: creating PlaybackEngine...', name: 'nightingale.di');
  final engine = await PlaybackEngine.create();
  developer.log('DI: PlaybackEngine created', name: 'nightingale.di');
  _sl.registerSingleton<PlaybackEngine>(engine);

  // ── Phase 3: Federation ──────────────────────────────────────────────────

  // Crypto — private key in secure enclave
  final crypto = PlatformCryptoService();
  _sl.registerSingleton<CryptoService>(crypto);

  // Node identity
  _sl.registerSingleton<NodeIdentityRepository>(
    NodeIdentityRepositoryImpl(
      db: db,
      crypto: crypto,
      baseUrl: _kNodeBaseUrl,
    ),
  );

  // Moderation
  _sl.registerSingleton<ModerationRepository>(ModerationRepository(db: db));
  _sl.registerSingleton<RateLimiter>(RateLimiter());

  // Actor resolver (cache-backed)
  _sl.registerSingleton<ActorResolver>(ActorResolver(db: db));

  // HTTP Signature service — keyId determined after identity is ready
  // (lazy: keyId is read from the identity repo on first use)
  _sl.registerLazySingleton<HttpSignatureService>(() {
    final identityRepo = _sl<NodeIdentityRepository>();
    // keyId is constructed synchronously using the actor URL pattern
    // The actual actor URL is fetched asynchronously on first sign/verify.
    return HttpSignatureService(
      crypto: crypto,
      keyId: '$_kNodeBaseUrl/users/node#main-key',
    );
  });

  // Relay client
  _sl.registerSingleton<RelayClient>(
    RelayClient(
      relayBaseUrl: _kRelayBaseUrl,
      sigService: _sl<HttpSignatureService>(),
    ),
  );

  // Activity delivery
  _sl.registerSingleton<ActivityDeliveryService>(
    ActivityDeliveryService(
      db: db,
      sigService: _sl<HttpSignatureService>(),
      relayClient: _sl<RelayClient>(),
      moderation: _sl<ModerationRepository>(),
    ),
  );

  // Migration service
  _sl.registerSingleton<MigrationService>(
    MigrationService(
      db: db,
      crypto: crypto,
      identityRepo: _sl<NodeIdentityRepository>(),
      delivery: _sl<ActivityDeliveryService>(),
    ),
  );

  // ── Phase 5: Social Layer ────────────────────────────────────────────────

  _sl.registerSingleton<SocialRepository>(
    SocialRepositoryImpl(
      db: db,
      delivery: _sl<ActivityDeliveryService>(),
      actorResolver: _sl<ActorResolver>(),
      identityRepo: _sl<NodeIdentityRepository>(),
      moderation: _sl<ModerationRepository>(),
    ),
  );

  _sl.registerSingleton<ActivityRepository>(
    ActivityRepositoryImpl(
      db: db,
      delivery: _sl<ActivityDeliveryService>(),
      identityRepo: _sl<NodeIdentityRepository>(),
      nodeBaseUrl: _kNodeBaseUrl,
    ),
  );

  // ── Phase 4: Library Federation ──────────────────────────────────────────

  // Library publisher
  _sl.registerSingleton<LibraryPublisher>(
    LibraryPublisher(
      libraryRepo: _sl<LibraryRepository>(),
      identityRepo: _sl<NodeIdentityRepository>(),
      db: db,
    ),
  );

  // Social subscribing
  _sl.registerSingleton<SocialSubscribingService>(
    SocialSubscribingService(
      db: db,
      actorResolver: _sl<ActorResolver>(),
      delivery: _sl<ActivityDeliveryService>(),
      identityRepo: _sl<NodeIdentityRepository>(),
    ),
  );

  // Node reachability
  _sl.registerSingleton<NodeReachabilityService>(NodeReachabilityService());

  // Audio cache manager (registered before StreamResolver so it can be injected)
  _sl.registerSingleton<AudioCacheManager>(AudioCacheManager(db: db));

  // Stream resolver
  _sl.registerSingleton<StreamResolver>(
    StreamResolver(
      actorResolver: _sl<ActorResolver>(),
      relayClient: _sl<RelayClient>(),
      reachability: _sl<NodeReachabilityService>(),
      cacheManager: _sl<AudioCacheManager>(),
    ),
  );

  // Remote library fetcher
  _sl.registerSingleton<RemoteLibraryFetcher>(
    RemoteLibraryFetcher(
      actorResolver: _sl<ActorResolver>(),
      sigService: _sl<HttpSignatureService>(),
      social: _sl<SocialSubscribingService>(),
    ),
  );

  // Acoustic fingerprint service
  _sl.registerSingleton<AcousticFingerprintService>(
    AcousticFingerprintService(db: db),
  );

  // Listen activity publisher
  _sl.registerSingleton<ListenActivityPublisher>(
    ListenActivityPublisher(
      identityRepo: _sl<NodeIdentityRepository>(),
      delivery: _sl<ActivityDeliveryService>(),
      social: _sl<SocialSubscribingService>(),
    ),
  );

  // Embedded federation HTTP server
  developer.log('DI: creating FederationServer...', name: 'nightingale.di');
  final server = FederationServer();
  _sl.registerSingleton<FederationServer>(server);
  // Start server on launch; errors are non-fatal
  try {
    developer.log('DI: starting FederationServer...', name: 'nightingale.di');
    await server.start(router: buildFederationRouter());
    developer.log('DI: FederationServer started on port ${server.currentPort}', name: 'nightingale.di');
    AppLogger.info(
      'FederationServer started on port ${server.currentPort}',
      tag: 'di',
    );
  } catch (e) {
    developer.log('DI: FederationServer failed: $e', name: 'nightingale.di');
    AppLogger.error('FederationServer failed to start: $e', tag: 'di');
  }

  // Startup delivery sweep — re-enqueue stale pending/retrying activities
  final delivery = _sl<ActivityDeliveryService>();
  delivery.sweepPendingOnStartup().ignore();

  AppLogger.initialize(_sl<CrashReporter>());

  // ── Phase 6: Recommendations ─────────────────────────────────────────────

  // Taste profile key — load or create AES-256 key from secure enclave
  final tasteKeyStore = TasteProfileKeyStore();
  await tasteKeyStore.loadOrCreate();
  _sl.registerSingleton<TasteProfileKeyStore>(tasteKeyStore);

  // Signal repository (encrypted at rest)
  _sl.registerSingleton<SignalRepository>(
    SignalRepository(
      dao: db.signalDao,
      encryptedStore: EncryptedSignalStore(tasteKeyStore),
    ),
  );

  // Playback signal capturer — hooks into engine for play/skip events
  final capturer = PlaybackSignalCapturer(
    engine: engine,
    signals: _sl<SignalRepository>(),
  );
  capturer.start();
  _sl.registerSingleton<PlaybackSignalCapturer>(capturer);

  // Network signal ingester — reads existing ActivityPub activities as signals
  _sl.registerSingleton<NetworkSignalIngester>(
    NetworkSignalIngester(
      db: db,
      social: _sl<SocialRepository>(),
      signals: _sl<SignalRepository>(),
    ),
  );

  // Cold-start services
  _sl.registerSingleton<ColdStartSettingsRepository>(
    ColdStartSettingsRepository(),
  );
  _sl.registerSingleton<NodeDiscoveryService>(
    NodeDiscoveryService(
      // Discovery endpoint URL can be set via build environment variable.
      discoveryEndpoint: const String.fromEnvironment(
        'DISCOVERY_ENDPOINT',
        defaultValue: '',
      ),
    ),
  );
  _sl.registerSingleton<GlobalTrendingRelayService>(
    GlobalTrendingRelayService(
      relayEndpoint: const String.fromEnvironment(
        'TRENDING_RELAY_ENDPOINT',
        defaultValue: '',
      ),
    ),
  );
  _sl.registerSingleton<ColdStartRepository>(
    ColdStartRepository(
      db: db,
      settings: _sl<ColdStartSettingsRepository>(),
      discovery: _sl<NodeDiscoveryService>(),
      relay: _sl<GlobalTrendingRelayService>(),
    ),
  );

  // Kick off initial network signal ingestion in the background
  _sl<NetworkSignalIngester>().ingest().ignore();

  // Phase 7 — offline activity queue
  _sl.registerSingleton<ActivityQueueService>(
    ActivityQueueService(
      db: db,
      sigService: _sl<HttpSignatureService>(),
    ),
  );

  // Register Phase 2 + Phase 3 debug overlay tabs (no-op in release builds)
  registerDebugOverlayTabs();

  AppLogger.info('Service locator initialized', tag: 'di');
}
