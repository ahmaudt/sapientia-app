# Sapientia

**Lock your distractions. Unlock your recollection.**

Sapientia is an iOS app blocker with a Catholic, meditative heart. Restrict distracting apps behind the tap of an NFC tag or the scan of a QR code — and when you reach for a blocked app, be met not with a wall, but with prayer.

> *O GRACIOUS and holy Father, give us wisdom to perceive thee, diligence to seek thee, patience to wait for thee, eyes to behold thee, a heart to meditate upon thee, and a life to proclaim thee; through the power of the Spirit of Jesus Christ our Lord. Amen.*
> — Prayer of St. Benedict

An alternative to Brick, Opal, ScreenZen, Unpluq, and Blok — for those who want their screen-time discipline ordered toward what matters.

## Features

### Focus & Blocking

- **Physical unlocking** — block and unblock apps with an NFC tag or QR code, adding intentional friction between you and your distractions
- **Blocking profiles** — group apps and websites into profiles for work, rest, prayer, or family time
- **Strict mode** — prevent mid-session unblocking until you physically scan your tag
- **Live Activities & widgets** — see your active session at a glance from the Lock Screen and Home Screen
- **Session insights** — track your focus sessions over time

### Prayer & Recollection

- **Prayer of St. Benedict at the threshold** — attempting to open a restricted app presents the prayer above, turning a moment of temptation into a moment of recollection
- **The Daily Office** — Morning and Evening Prayer in the tradition of the [Ordinariate Daily Office](http://prayer.covert.org/)
- **The Holy Rosary** — pray the mysteries with guided structure
- **Catholic Ordinariate prayers** — a treasury of prayers from the Personal Ordinariates' Anglican patrimony
- **A modern, meditative interface** — clean, calm design in the spirit of apps like Hallow

## Requirements

- iOS 17+ (Screen Time / Family Controls capable device)
- An NFC tag (any writable NTAG works) or a printed QR code
- Xcode 16+ to build from source

## Building from Source

```bash
git clone git@github.com:ahmaudt/sapientia-app.git
cd sapientia-app

make build      # Build the iOS app
make test       # Run unit tests
make lint       # Check Swift formatting
make check      # Lint + build
```

Open `sapientia.xcodeproj` in Xcode and select the `sapientia` scheme to run on a device. App blocking requires the Family Controls entitlement, which must be provisioned for your team; blocking features require a physical device.

A companion macOS menu-bar app lives under `SapientiaMac` (`make mac-dev` to build, install, and launch locally).

## Project Layout

| Directory | Purpose |
|-----------|---------|
| `Sapientia/` | Main iOS app (views, models, blocking strategies, intents) |
| `SapientiaWidget/` | Home Screen / Lock Screen widgets and Live Activities |
| `SapientiaShieldConfig/`, `SapientiaShieldAction/` | Screen Time shield UI and actions shown over blocked apps |
| `SapientiaDeviceMonitor/` | Device activity monitoring extension |
| `SapientiaMac/`, `SapientiaFilter/` | macOS menu-bar app and network filter system extension |
| `SapientiaShared/` | Code shared across targets |

## Acknowledgements

Sapientia is based on [Foqos](https://github.com/awaseem/foqos) by Ali Waseem, an open-source NFC/QR app blocker released under the MIT License (see [LICENSE](LICENSE)). The Daily Office texts follow the tradition made available at [prayer.covert.org](http://prayer.covert.org/).

## License

MIT — see [LICENSE](LICENSE).
