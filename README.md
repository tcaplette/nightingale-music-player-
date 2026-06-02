# nightingale

**A federated music player where every installation is a node on the network.**

Nightingale is an open-source Flutter app built on ActivityPub. You install it, it generates a federated identity, and your phone becomes a node — hosting your music library, publishing your listening activity, and discovering music from people you follow. No central server. No platform. Just the network.

---

## What it does

- **Local music player** — scans your device library, parses metadata, plays with gapless audio, lock screen controls, and audio focus handling
- **Federated identity** — each install generates an Ed25519 keypair stored in the device secure enclave. Your identity is yours, not a platform's
- **Embedded ActivityPub server** — the app runs an HTTP server serving your actor, inbox, outbox, followers, and WebFinger endpoint directly from your phone
- **Peer discovery** — mDNS on local networks, STUN-based address resolution across networks, social graph traversal for cold-start discovery
- **Social layer** — follow people, see what they're listening to, get notified when they share music
- **Mastodon bridge** — sign in with your Mastodon account to import your existing social graph on day one
- **Recommendations** — discovery feed built from real listening activity across your network, not algorithmic black boxes
- **Account portability** — identity migration between devices via QR code, modeled on Mastodon's `Move` activity

---

## Current status

Active development. The core player, federated identity, ActivityPub server, mDNS discovery, and social layer are built and working. Audio streaming between nodes is the next major milestone.

---

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Flutter / Dart |
| State management | Riverpod |
| Navigation | go_router |
| Audio | just_audio, just_audio_background |
| Local database | Drift (SQLite) |
| Federation server | shelf, shelf_router |
| Cryptography | Ed25519 via `cryptography`, flutter_secure_storage |
| Peer discovery | bonsoir (mDNS / NSD) |
| Library scanning | on_audio_query, metadata_god |

---

## Building

**Platform:** Android only at this time.

**Prerequisites:** Flutter SDK ≥ 3.11.4, Android SDK.

```sh
# Install dependencies
flutter pub get

# Run code generation (Riverpod, Drift)
dart run build_runner build --delete-conflicting-outputs

# Run on a connected device
flutter run
```

Release builds require `SENTRY_DSN` and `NODE_BASE_URL` passed via `--dart-define`. See [docs/release-build-vars.md](docs/release-build-vars.md).

---

## Contributing

Contributions are welcome. The project is in active early development. Open an issue before starting significant work so we can align on approach.

---

## License

GPL-3.0. See [LICENSE](LICENSE).

---

## Support

If you believe in a music ecosystem that isn't owned by a platform, consider supporting development — details coming soon.
