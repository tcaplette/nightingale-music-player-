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
import 'package:nightingale/features/federation/discovery/mastodon_bridge_service.dart';
import 'package:nightingale/features/federation/discovery/mastodon_oauth_service.dart';
import 'package:nightingale/features/federation/discovery/peer_discovery_service.dart';
import 'package:nightingale/features/federation/discovery/peer_exchange_service.dart';
import 'package:nightingale/features/federation/moderation/moderation_repository.dart';
import 'package:nightingale/features/federation/moderation/rate_limiter.dart';
import 'package:nightingale/features/federation/deduplication/acoustic_fingerprint_service.dart';
import 'package:nightingale/features/federation/library/remote_library_fetcher.dart';
import 'package:nightingale/features/federation/publishing/library_publisher.dart';
import 'package:nightingale/features/federation/publishing/listen_activity_publisher.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_service.dart';
import 'package:nightingale/features/federation/stun/stun_address_resolver.dart';
import 'package:nightingale/core/repositories/activity_repository.dart';
import 'package:nightingale/core/repositories/social_repository.dart';
import 'package:nightingale/features/federation/social/social_subscribing_service.dart';
import 'package:nightingale/features/federation/streaming/audio_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/chunk_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/chunk_manifest.dart';
import 'package:nightingale/features/federation/streaming/seeding_power_policy.dart';
import 'package:nightingale/features/federation/streaming/stream_resolver.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/library/library_repository_impl.dart';
import 'package:nightingale/features/library/services/album_metadata_fetch_service.dart';
import 'package:nightingale/features/node_identity/local_address_resolver.dart';
import 'package:nightingale/features/node_identity/migration_service.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';
import 'package:nightingale/features/node_identity/node_identity_repository_impl.dart';
import 'package:nightingale/features/recommendations/data/cold_start_settings_repository.dart';
import 'package:nightingale/features/settings/data/settings_repository.dart';
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

// Node base URL — legacy fallback; actor URLs are now built from resolved LAN IP.
const _kNodeBaseUrl = String.fromEnvironment(
  'NODE_BASE_URL',
  defaultValue: 'http://localhost',
);

// Stable federation server port (default 7777).
const _kFederationPort = int.fromEnvironment(
  'FEDERATION_PORT',
  defaultValue: 7777,
);

// STUN server used for public address discovery.
const _kStunServer = String.fromEnvironment(
  'STUN_SERVER',
  defaultValue: 'stun.l.google.com:19302',
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

  // Database
  final db = AppDatabase();
  _sl.registerSingleton<AppDatabase>(db);
  developer.log('DI: database registered', name: 'nightingale.di');

  // Phase 7 — DB integrity check on every startup (read-only; no schema change needed)
  final dbIntegrity = DatabaseIntegrityService(db: db);
  _sl.registerSingleton<DatabaseIntegrityService>(dbIntegrity);
  final integrityResult = await dbIntegrity.checkAndRepair();
  if (integrityResult == IntegrityCheckResult.unrecoverable) {
    AppLogger.error('DB unrecoverable at startup — rescan required', tag: 'di');
  }
  developer.log('DI: integrity check = $integrityResult', name: 'nightingale.di');

  // Library
  _sl.registerSingleton<LibraryRepository>(
    LibraryRepositoryImpl(db: db),
  );
  developer.log('DI: library repo registered', name: 'nightingale.di');

  // Settings repository — registered early so PlaybackEngine can read its values
  final settingsRepo = SettingsRepository();
  _sl.registerSingleton<SettingsRepository>(settingsRepo);

  // Playback engine
  developer.log('DI: creating PlaybackEngine...', name: 'nightingale.di');
  final playbackSettings = await settingsRepo.loadPlaybackSettings();
  final engine = await PlaybackEngine.create(settings: playbackSettings);
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
    ),
  );

  // Address resolvers
  _sl.registerSingleton<LocalAddressResolver>(LocalAddressResolver());
  _sl.registerSingleton<StunAddressResolver>(
    StunAddressResolver(stunServer: _kStunServer),
  );

  // Moderation
  _sl.registerSingleton<ModerationRepository>(ModerationRepository(db: db));
  _sl.registerSingleton<RateLimiter>(RateLimiter());

  // Actor resolver (cache-backed)
  _sl.registerSingleton<ActorResolver>(ActorResolver(db: db));

  // HTTP Signature service — keyId is built from the node base URL at DI time.
  // Once identity is set up the actual actor URL is used. The keyId here acts
  // as a best-effort placeholder for pre-onboarding signing scenarios.
  _sl.registerLazySingleton<HttpSignatureService>(() {
    return HttpSignatureService(
      crypto: crypto,
      keyId: '$_kNodeBaseUrl/users/node#main-key',
    );
  });

  // Activity delivery (no relay — pure queue-and-retry)
  _sl.registerSingleton<ActivityDeliveryService>(
    ActivityDeliveryService(
      db: db,
      sigService: _sl<HttpSignatureService>(),
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
  final libraryPublisher = LibraryPublisher(
    libraryRepo: _sl<LibraryRepository>(),
    identityRepo: _sl<NodeIdentityRepository>(),
    db: db,
    settings: settingsRepo,
  );
  await libraryPublisher.init();
  _sl.registerSingleton<LibraryPublisher>(libraryPublisher);

  // Peer exchange — background actor cache expansion on follow
  _sl.registerSingleton<PeerExchangeService>(
    PeerExchangeService(actorResolver: _sl<ActorResolver>()),
  );

  // Mastodon bridge — social graph import
  _sl.registerSingleton<MastodonBridgeService>(
    MastodonBridgeService(actorResolver: _sl<ActorResolver>()),
  );

  // Mastodon OAuth — system browser sign-in and token management
  _sl.registerSingleton<MastodonOAuthService>(
    MastodonOAuthService(storage: _sl<SecureStorageService>()),
  );

  // Social subscribing
  _sl.registerSingleton<SocialSubscribingService>(
    SocialSubscribingService(
      db: db,
      actorResolver: _sl<ActorResolver>(),
      delivery: _sl<ActivityDeliveryService>(),
      identityRepo: _sl<NodeIdentityRepository>(),
      peerExchange: _sl<PeerExchangeService>(),
    ),
  );

  // Node reachability
  final reachability = NodeReachabilityService();
  _sl.registerSingleton<NodeReachabilityService>(reachability);

  // Peer discovery — username search across actor cache and social graph
  _sl.registerSingleton<PeerDiscoveryService>(
    PeerDiscoveryService(
      db: db,
      actorResolver: _sl<ActorResolver>(),
    ),
  );

  // Audio cache manager (legacy — kept during migration period)
  _sl.registerSingleton<AudioCacheManager>(AudioCacheManager(db: db));

  // Phase 8 — chunk-based cache infrastructure
  final manifestRepo = ChunkManifestRepository(db: db);
  _sl.registerSingleton<ChunkManifestRepository>(manifestRepo);

  final chunkCache = ChunkCacheManager(
    db: db,
    manifestRepository: manifestRepo,
  );
  _sl.registerSingleton<ChunkCacheManager>(chunkCache);

  // Seeding power policy — must be registered before stream resolver and
  // federation server so both can call canSeed().
  final seedingPolicy = SeedingPowerPolicy(settings: settingsRepo);
  _sl.registerSingleton<SeedingPowerPolicy>(seedingPolicy);

  // Stream resolver (chunk → direct → cache → unavailable)
  _sl.registerSingleton<StreamResolver>(
    StreamResolver(
      actorResolver: _sl<ActorResolver>(),
      reachability: _sl<NodeReachabilityService>(),
      cacheManager: _sl<AudioCacheManager>(),
      chunkCacheManager: chunkCache,
      manifestRepository: manifestRepo,
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
  final listenPublisher = ListenActivityPublisher(
    identityRepo: _sl<NodeIdentityRepository>(),
    delivery: _sl<ActivityDeliveryService>(),
    social: _sl<SocialSubscribingService>(),
    settings: settingsRepo,
  );
  await listenPublisher.init();
  _sl.registerSingleton<ListenActivityPublisher>(listenPublisher);

  // Embedded federation HTTP server
  developer.log('DI: creating FederationServer...', name: 'nightingale.di');
  final server = FederationServer(preferredPort: _kFederationPort);
  _sl.registerSingleton<FederationServer>(server);
  try {
    developer.log('DI: starting FederationServer...', name: 'nightingale.di');
    await server.start(router: buildFederationRouter());
    developer.log(
      'DI: FederationServer started on port ${server.currentPort}',
      name: 'nightingale.di',
    );
    AppLogger.info(
      'FederationServer started on port ${server.currentPort}',
      tag: 'di',
    );
  } catch (e) {
    developer.log('DI: FederationServer failed: $e', name: 'nightingale.di');
    AppLogger.error('FederationServer failed to start: $e', tag: 'di');
  }

  // mDNS advertiser — start after server is bound so port is known
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

  // Playback signal capturer
  final capturer = PlaybackSignalCapturer(
    engine: engine,
    signals: _sl<SignalRepository>(),
  );
  capturer.start();
  _sl.registerSingleton<PlaybackSignalCapturer>(capturer);

  // Network signal ingester
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

  _sl<NetworkSignalIngester>().ingest().ignore();

  // Phase 7 — offline activity queue
  _sl.registerSingleton<ActivityQueueService>(
    ActivityQueueService(
      db: db,
      sigService: _sl<HttpSignatureService>(),
    ),
  );

  // Album batch metadata fetch
  _sl.registerSingleton<AlbumMetadataFetchService>(
    AlbumMetadataFetchService(db: db),
  );

  // Register debug overlay tabs
  registerDebugOverlayTabs();

  AppLogger.info('Service locator initialized', tag: 'di');
}
