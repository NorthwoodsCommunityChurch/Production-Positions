# Production Positions

## Purpose
Two macOS apps for assigning production team members to numbered positions. Admin configures via SwiftUI app; team views assignments on a shared monitor via web browser.

- **Camera Positions** — camera operators + lens assignments
- **Vocalist Positions** — vocalists (no lenses)

## Architecture
Both apps share the same architecture:
- **SwiftUI admin app** — sidebar + position grid layout
- **NWListener HTTP server** — serves web display (Camera on port 8080, Vocalist on port 8081)
- **JSON file persistence** — `~/Library/Application Support/{AppName}/`
- **Planning Center integration** — pulls team members and weekends from PCO Services API

## Key Differences (Vocalist vs Camera)
- Vocalist has no Lens model, no LensTray views, no lens methods
- Vocalist uses `vocalists` JSON key (not `cameras`) in the web display
- Vocalist columns labeled "VOX 1" (not "CAM 1")
- Vocalist uses 2-pane layout (no bottom lens tray)
- Each app has its own bundle ID, Keychain entry, data directory, and Sparkle appcast

## Build
```bash
cd camera-positions && ./build.sh    # xcodegen → xcodebuild → sign → launch
cd vocalist-positions && ./build.sh
```

## Data Flow
1. Admin adds team members (manually or from PCO)
2. Admin drags names into position columns
3. Changes auto-publish → writes `published-display.json`
4. Web display polls `/api/config` → renders position cards
5. Images served from `/api/images/{filename}`

## Known Patterns
- `Color.accentColor` must be explicit in `.foregroundStyle()` (SwiftUI type inference issue)
- `lazy` doesn't work in `@Observable` classes — use init pattern instead
- OneDrive xattrs break code signing — `xattr -cr` in build.sh before signing
- Web resources embedded in app bundle via `path: Resources/Web, type: folder` in project.yml
- Camera Positions uses port 8080, Vocalist Positions uses port 8081 — both can run simultaneously

# currentDate
Today's date is 2026-02-19.
