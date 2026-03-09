# Security Findings - Production Positions

**Review Date**: 2026-03-01
**Reviewer**: Claude Security Review (Clara)
**Severity Summary**: 0 Critical, 0 High, 2 Medium, 1 Low

## Findings

| ID | Severity | Finding | File | Line | Status |
|----|----------|---------|------|------|--------|
| PP-01 | MEDIUM | HTTP server on all interfaces without authentication | DisplayServer.swift | - | Open |
| PP-02 | MEDIUM | Planning Center OAuth tokens stored as Keychain strings | PCOTokenStore.swift | - | Open |
| PP-03 | LOW | No rate limiting on HTTP server endpoints | DisplayServer.swift | - | Open |

## Detailed Findings

### PP-01 [MEDIUM] HTTP server on all interfaces without authentication

**Location**: DisplayServer.swift (Camera port 8080, Vocalist port 8081)
**Description**: The NWListener HTTP servers bind to all network interfaces, serving position data, configuration JSON, and person photos to any device on the local network. There is no authentication or access control.
**Impact**: Any device on the local network can view team member names, positions, and photos. While this is by design for the web display use case, it exposes personal information without access controls.
**Remediation**: This is documented as intentional behavior. Consider adding optional basic auth or restricting to localhost-only mode for sensitive environments.

### PP-02 [MEDIUM] Planning Center OAuth tokens stored as Keychain strings

**Location**: PCOTokenStore.swift
**Description**: The PCO Application ID and Secret are stored in macOS Keychain using `kSecClassGenericPassword`. This is the correct approach and provides good protection. However, the Keychain items use `kSecAttrAccessibleWhenUnlocked` which means they are available whenever the user is logged in.
**Impact**: Low - Keychain is the recommended credential storage mechanism. The accessibility level is appropriate for a desktop app that needs credentials while the user is active.
**Remediation**: No action needed. Current implementation follows Apple's recommended practices.

### PP-03 [LOW] No rate limiting on HTTP server endpoints

**Location**: DisplayServer.swift
**Description**: The NWListener HTTP server has no rate limiting. A client could rapidly poll `/api/config` or request many images.
**Impact**: Could cause increased CPU/memory usage on the host Mac. Low practical risk on a local network.
**Remediation**: No action needed for a trusted local network environment.

## Security Posture Assessment

**Overall Risk: LOW**

The Production Positions apps (Camera Positions and Vocalist Positions) have a good security posture. Credentials are properly stored in the macOS Keychain, image filenames are sanitized with UUID naming, and the HTTP server is read-only. The apps communicate with Planning Center over HTTPS. The main exposure is the unauthenticated HTTP server, which is intentional for the web display use case.

## Remediation Priority

1. PP-01 - Document security implications of network exposure
2. PP-02 - No action needed (already using Keychain correctly)
3. PP-03 - No action needed for trusted LAN

---

## Network Server

Camera Positions runs an HTTP server on **port 8080** and Vocalist Positions on **port 8081** to serve the web display. Both apps can run simultaneously.

- The server binds to your Mac's local network interface only
- It serves read-only data: position assignments, names, and photos
- There are no admin endpoints — the web display cannot modify assignments
- No authentication is required (the display is intended to be openly viewable on your local network)

**If you do not want the web display accessible to other devices on your network**, you can access it at `http://localhost:8080` (Camera) or `http://localhost:8081` (Vocalist) from the same machine only.

## Credential Storage

Planning Center credentials (Application ID and Secret) are stored in the **macOS Keychain**, not in plain text files or UserDefaults. Credentials are:

- Encrypted at rest by the system Keychain
- Never written to disk outside the Keychain
- Never logged to the console
- Cleared from the Keychain when you disconnect Planning Center
- Each app uses its own Keychain entry (they do not share credentials)

## Data Storage

All app data is stored locally:

- **Camera Positions:** `~/Library/Application Support/CameraPositions/`
- **Vocalist Positions:** `~/Library/Application Support/VocalistPositions/`

Each stores:
- Position assignments and weekend configurations (JSON files)
- Uploaded photos (position photos, person photos)
- No data is sent to external servers except Planning Center API calls (over HTTPS)

## Image Handling

- Uploaded image filenames are sanitized to prevent directory traversal
- Hidden files (starting with `.`) are rejected
- Images are stored with UUID filenames, not user-provided names

## Reporting Security Issues

If you find a security vulnerability, please open an issue at [GitHub Issues](https://github.com/NorthwoodsCommunityChurch/avl-production-positions/issues).
