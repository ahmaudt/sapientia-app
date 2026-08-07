
repo: ahmaudt/sapientia-app
branch: main
path: Foqos

## Last sync

date: 2026-08-07T00:00:00Z

### Updated in this project

- Read the foqos profile, strategy and shield-configuration model to ground the new iOS screens.
- Added six redesigned screens (onboarding, home, session setup, tag/code scan, block screen, settings).
- Block screen now carries the Prayer of St. Benedict, with a Collect-of-the-day option.
- Home screen adds the Ordinariate feast day and its Collect.

## Screen map

| Screen | Repo files |
| --- | --- |
| Onboarding | Foqos/Views/IntroView.swift, Foqos/Components/Intro |
| Home — today | Foqos/Views/HomeView.swift, Foqos/Models/BlockedProfiles.swift |
| Session setup | Foqos/Views/BlockedProfileView.swift, Foqos/Models/Strategies |
| Tag & code | Foqos/Utils/NFCScannerUtil.swift, Foqos/Utils/PhysicalReader.swift |
| Block screen | FoqosShieldConfig/ShieldConfigurationExtension.swift, FoqosShieldAction/ShieldActionExtension.swift |
| Settings | Foqos/Views/SettingsView.swift, Foqos/Views/EmergencyView.swift |

