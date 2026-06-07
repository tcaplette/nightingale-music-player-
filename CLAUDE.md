# Nightingale — Agent Rules

# Karparthy Rules:

# Project Architectural & Quality Guidelines

## 1. Goal-Driven Execution
* Define exact success criteria before generating code. 
* Do not make sweeping assumptions. If specifications are vague, ask the user for clarification.
* Write tests that reproduce the bug or edge case, and make them pass. 

## 2. Simplicity & Readability First
* No "AI slop." Do not generate over-engineered abstractions, bloated helpers, or unnecessary classes.
* Never leave empty `catch(e) {}` blocks. Always handle, log, or throw the error.
* Avoid redundant or obvious code comments (e.g., `// Set the variable x to 5`). Only comment "why" a complex business rule exists.

## 3. Surgical Changes
* Touch only what you must to fulfill the request. 
* Do not refactor unrelated code, and never change formatting in files you haven't explicitly modified.
* Do not delete dead code you notice unless it is requested. Mention it to the user.

## 4. Anti-Slop Code Patterns (Prohibited)
* **Duplication**: Do not create generic, duplicate utility functions if standard libraries suffice.
* **No "Not just X, but also Y" Code**: Avoid verbose, overly complicated structures when a straightforward implementation works.
* **Overuse of M-Dashes or Fluff**: Ensure your written code explanations are direct, using active voice.

## Debugging Rule

If an agent has been investigating a bug or error in code for more than 1 minute without identifying the root cause, it must **stop immediately** and write debugging code (print statements, logging, error handlers) to surface the actual error at runtime. Do not continue reading files or reasoning about the cause. Write the debugging code, tell the user to run the app, and wait for the output.

## Federation Architecture Rule

**Never assume peers are on a local network or behind NAT.** Nightingale is a production federated app. Devices run on public IPs (mobile LTE/5G assigns routable IPs directly). Any solution that requires local network access, LAN discovery, or NAT traversal is wrong and must not be built.

### How peers connect

Nightingale uses **Mastodon as the signaling layer** and **direct HTTP as the transport layer**:

1. **Identity** — each user's Mastodon actor (`@user@instance.social`) is their stable identity. This never changes even when the device IP changes.

2. **Address publishing** — on startup and on network change, the device runs STUN to discover its current public IP:port. This is written to the user's Mastodon profile as the custom field `x-nightingale-public-address` via the Mastodon API (`PATCH /api/v1/accounts/update_credentials`). Mastodon propagates this to all followers automatically. The Mastodon actor object IS the address record — there is no other discovery mechanism.

3. **Peer resolution** — when Device A wants to reach Device B, it fetches Device B's Mastodon actor (via `ActorResolver`), reads `x-nightingale-public-address` from the resolved `ApActor.nightingalePublicAddress` field, and connects directly to that IP:port. The `NodeReachabilityService` and all URL construction must use this field first, with `actor.id`-derived URLs as fallback only.

4. **Transport** — all `/library`, `/stream/<id>`, and `/chunks/<hash>` requests go directly to the peer's public IP:port. No relay. No proxy. No central server.

5. **Discovery** — `MastodonBridgeService` scans a user's Mastodon followers/following for the `x-nightingale-actor-url` custom field, which points to the peer's Nightingale actor URL. This is how users find each other.

### What agents must never do

- **Never suggest local IP addresses** as a way to connect two devices
- **Never build or suggest relay servers, proxies, or centralized streaming infrastructure** — this defeats the purpose of the app
- **Never treat Mastodon social follows as Nightingale music peers** — they are different things. Only actors with a cached entry in `remoteLibrariesTable` (i.e. a successful `/library` fetch) are confirmed Nightingale peers
- **Never assume CGNAT or NAT as the default scenario** — mobile devices on LTE/5G have public routable IPs
- **Never conflate social follows (`followsTable`) with music peers** — the recommendation engine must only use confirmed Nightingale peers (actors in `remoteLibrariesTable`)

### When something doesn't connect

If streaming or library fetching fails between two devices, the correct debugging order is:

1. Does the peer's Mastodon profile have `x-nightingale-public-address` set? (Check via Mastodon API or profile page)
2. Is `ApActor.nightingalePublicAddress` being parsed and used — not `actor.id`?
3. Is `MastodonProfileSyncService` triggering after STUN resolves?
4. Is the OAuth token scoped with `write:accounts`?

Do not jump to NAT, local network, or relay-based explanations.
