## ADDED Requirements

### Requirement: HTTP Signature authentication for streams
Every audio stream request SHALL include an HTTP Signature in the `Authorization` header. The hosting node SHALL verify the signature before serving audio bytes.

#### Scenario: Valid signature
- **WHEN** a request arrives at `/stream/<track-id>` with a valid HTTP Signature
- **THEN** the hosting node serves the audio file

#### Scenario: Missing signature
- **WHEN** a request arrives at `/stream/<track-id>` without an HTTP Signature
- **THEN** the hosting node responds with HTTP 401 Unauthorized

#### Scenario: Invalid signature
- **WHEN** a request arrives at `/stream/<track-id>` with an invalid HTTP Signature
- **THEN** the hosting node responds with HTTP 403 Forbidden

### Requirement: Followers-only verification
For followers-only tracks, the hosting node SHALL verify that the requesting actor is in the followers collection before serving the stream.

#### Scenario: Follower request
- **WHEN** a verified follower requests a followers-only track
- **THEN** the hosting node serves the audio file

#### Scenario: Non-follower request
- **WHEN** a non-follower requests a followers-only track
- **THEN** the hosting node responds with HTTP 403 Forbidden

### Requirement: Stream endpoint structure
The stream endpoint SHALL be `GET /stream/<track-id>` and SHALL support range requests for seeking.

#### Scenario: Range request
- **WHEN** a request includes a `Range` header
- **THEN** the hosting node responds with the requested byte range and HTTP 206 Partial Content
