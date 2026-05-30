# Nightingale Phase 4 API Documentation

## Library Publishing Endpoints

### GET /users/{username}/library

Returns the user's library as an ActivityPub `OrderedCollection`.

**Authentication:** Optional (HTTP Signature). Required for followers-only libraries.

**Response:**
```json
{
  "@context": "https://www.w3.org/ns/activitystreams",
  "id": "http://node.example/users/node/library",
  "type": "OrderedCollection",
  "totalItems": 42,
  "first": "http://node.example/users/node/library?page=1"
}
```

**Privacy:**
- `private`: Returns 403 Forbidden
- `followersOnly`: Returns 403 if requester is not a follower
- `public`: Returns collection to all requesters

### GET /users/{username}/library?page={n}

Returns a page of `Audio` objects from the library.

**Response:**
```json
{
  "@context": "https://www.w3.org/ns/activitystreams",
  "id": "http://node.example/users/node/library?page=1",
  "type": "OrderedCollectionPage",
  "partOf": "http://node.example/users/node/library",
  "orderedItems": [
    {
      "@context": "https://www.w3.org/ns/activitystreams",
      "id": "http://node.example/users/node/tracks/1",
      "type": "Audio",
      "name": "Song Title",
      "artist": "Artist Name",
      "album": "Album Name",
      "duration": 180,
      "url": {
        "type": "Link",
        "href": "http://node.example/stream/1",
        "mediaType": "audio/mpeg"
      },
      "icon": {
        "type": "Image",
        "url": "http://node.example/artwork/1.jpg"
      }
    }
  ],
  "next": "http://node.example/users/node/library?page=2"
}
```

## Audio Streaming Endpoints

### GET /stream/{track-id}

Streams an audio file with HTTP range request support.

**Authentication:** Optional for public streams. Required (HTTP Signature) for followers-only streams.

**Headers:**
- `Range: bytes=start-end` (optional, for seeking)
- `Signature: keyId="...",algorithm="ed25519",...` (required for followers-only)
- `Date: ...` (required with Signature)

**Responses:**
- `200 OK` — Full file
- `206 Partial Content` — Range response
- `403 Forbidden` — Private library, not a follower, or invalid signature
- `404 Not Found` — Track or file not found

**Range Response:**
```
HTTP/1.1 206 Partial Content
Content-Type: audio/mpeg
Content-Length: 1048576
Content-Range: bytes 0-1048575/5242880
Accept-Ranges: bytes

[audio bytes]
```

## Activity Types

### Listen Activity

Published when a user plays a track (if sharing is enabled).

```json
{
  "@context": "https://www.w3.org/ns/activitystreams",
  "id": "http://node.example/users/node/listen/1234567890",
  "type": "Listen",
  "actor": "http://node.example/users/node",
  "object": {
    "type": "Audio",
    "id": "http://node.example/users/node/tracks/1",
    "name": "Song Title",
    "artist": "Artist Name"
  },
  "published": "2024-01-01T00:00:00Z"
}
```

## Authentication

All stream requests support HTTP Signature authentication (RFC 9421 draft).

### Signing Requests

Outgoing requests must include:
- `Date` header (RFC 7231 format)
- `Digest` header for POST/PUT bodies
- `Signature` header with:
  - `keyId`: Actor URL + `#main-key`
  - `algorithm`: `ed25519`
  - `headers`: `(request-target) host date digest`
  - `signature`: Base64-encoded Ed25519 signature

### Verifying Requests

The server:
1. Checks the `Date` header is within a 30-second window
2. Fetches the actor's public key from the `keyId`
3. Reconstructs the signing string
4. Verifies the Ed25519 signature
5. Checks replay protection (nonce tracking)

### Privacy Enforcement

| Sharing Scope | Anonymous | Authenticated (Follower) | Authenticated (Non-Follower) |
|--------------|-----------|-------------------------|------------------------------|
| Private | 403 | 403 | 403 |
| Followers-Only | 403 | 200 (if follower) | 403 |
| Public | 200 | 200 | 200 |

## Chromaprint Integration

### FFI Build Steps

1. Install chromaprint development libraries:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install libchromaprint-dev
   
   # macOS
   brew install chromaprint
   
   # Android (cross-compile)
   # See: https://github.com/acoustid/chromaprint
   ```

2. The app attempts to load:
   - Android/Linux: `libchromaprint.so`
   - macOS/iOS: `libchromaprint.1.dylib`
   - Windows: `chromaprint.dll`

3. If chromaprint is not available, the app falls back to a perceptual hash comparison.

### Fingerprint Comparison

When chromaprint is available:
- Uses actual chromaprint bit-error rate comparison
- More accurate for detecting same audio with different metadata

When chromaprint is unavailable:
- Falls back to byte-level comparison of placeholder fingerprints
- Still supports merge/undo with full provenance tracking

## Relay Streaming

### Stream Forward Request

When direct connection to a host fails, the app can request a relay forward:

```
POST /stream-forward
Content-Type: application/json

{
  "targetActorUrl": "http://actor.example/users/node",
  "trackId": "123"
}
```

**Response:**
```json
{
  "streamUrl": "http://relay.example/forward/abc123"
}
```

The relay preserves HTTP Signature headers when forwarding the request to the target node.
