# Production Positions

Assignment display apps for live production teams. Assign team members to numbered positions in the admin app — they view their assignments on a shared monitor via web browser.

This repo contains two apps:

- **Camera Positions** — assign camera operators to numbered camera positions with lens assignments
- **Vocalist Positions** — assign vocalists to numbered stage positions

<!-- TODO: Add screenshots -->
<!-- ![Camera Positions](docs/images/camera-screenshot.png) -->
<!-- ![Vocalist Positions](docs/images/vocalist-screenshot.png) -->

## Features

### Shared
- **Drag-and-drop assignments** — drag team members onto positions
- **Web display** — full-screen browser view shows position numbers, names, and photos
- **Planning Center integration** — pull team members and service schedules from PCO Services
- **Person photos** — assign photos that display on the web view
- **Position photos** — attach reference photos for each position
- **Multiple weekends** — manage assignments for upcoming services
- **Auto-publish** — changes publish instantly to the web display
- **Clock display** — web view shows the current time
- **Auto-updates** — built-in update checking via Sparkle

### Camera Positions Only
- **Lens management** — create a lens inventory with names and photos, drag lenses onto cameras
- **3-pane layout** — sidebar, camera grid, and lens tray

### Vocalist Positions Only
- **Simplified layout** — sidebar and vocalist grid (no lens tray)

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon Mac (aarch64)

## Installation

1. Download the latest `.zip` files from [Releases](https://github.com/NorthwoodsCommunityChurch/avl-production-positions/releases)
2. Extract the zip file(s) for the app(s) you need
3. Move the `.app` to your Applications folder
4. Open the app — macOS will block it the first time
5. Go to **System Settings > Privacy & Security** and click **Open Anyway**
6. The app will open normally from now on

## Usage

### Admin App

- **Left sidebar** — select weekends, manage team members, connect Planning Center
- **Center grid** — positions with drop zones for team members
- **Bottom tray** (Camera Positions only) — lens inventory

### Web Display

Once an app is running, open a browser on any device on the same network to:

```
http://<your-mac-ip>:8080
```

The web display auto-refreshes every 5 seconds.

### Quick Start

1. Launch the app
2. Positions are created by default (click + to add more)
3. Add team members manually or connect Planning Center
4. Drag team members onto positions
5. Open `http://localhost:8080` in a browser to see the display

## Configuration

### Planning Center Integration

1. Go to [Planning Center Developer](https://api.planningcenteronline.com/oauth/applications) and create a Personal Access Token
2. Click **Connect Planning Center** in the app sidebar
3. Enter your Application ID and Secret
4. Select your service type and team from the dropdowns
5. Upcoming services and team members will sync automatically

## Building from Source

### Prerequisites

- Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build

```bash
git clone https://github.com/NorthwoodsCommunityChurch/avl-production-positions.git
cd avl-production-positions

# Build Camera Positions
cd camera-positions && ./build.sh

# Build Vocalist Positions
cd ../vocalist-positions && ./build.sh
```

Each build script generates the Xcode project, builds a Release binary, bundles and signs the Sparkle framework, ad-hoc signs the app, and launches it.

## Project Structure

```
Production Positions/
├── camera-positions/
│   ├── build.sh
│   ├── project.yml
│   ├── CameraPositions/
│   │   ├── App/                    # Entry point, Sparkle
│   │   ├── Models/                 # CameraPosition, Lens, Assignment
│   │   ├── ViewModels/             # App state and business logic
│   │   ├── Views/                  # ContentView, CameraGrid, LensTray, Sidebar
│   │   ├── Services/               # Persistence, ImageStorage, Web server, PCO
│   │   └── Resources/              # Assets, Web display (HTML/CSS/JS)
│   └── icon-camera-positions.svg
├── vocalist-positions/
│   ├── build.sh
│   ├── project.yml
│   ├── VocalistPositions/
│   │   ├── App/                    # Entry point, Sparkle
│   │   ├── Models/                 # VocalistPosition, Assignment (no Lens)
│   │   ├── ViewModels/             # App state and business logic
│   │   ├── Views/                  # ContentView, VocalistGrid, Sidebar
│   │   ├── Services/               # Persistence, ImageStorage, Web server, PCO
│   │   └── Resources/              # Assets, Web display (HTML/CSS/JS)
│   └── icon-vocalist-positions.svg
├── LICENSE
├── CREDITS.md
└── SECURITY.md
```

## License

MIT License — see [LICENSE](LICENSE) for details.

## Credits

See [CREDITS.md](CREDITS.md) for third-party libraries, tools, and assets.
