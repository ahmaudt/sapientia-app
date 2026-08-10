import SwiftUI

/// The user's chosen interface appearance. Replaces the old fixed
/// `.preferredColorScheme(.light)` pin: content screens now follow this
/// setting, while the rite (onboarding, scan, prayer) keeps its own steel
/// ground in every mode.
enum AppearanceSetting: String, CaseIterable, Identifiable {
  case light
  case dark
  case system

  var id: String { rawValue }

  /// Uppercase segment label, matching the Settings mock.
  var label: String {
    switch self {
    case .light: "Light"
    case .dark: "Dark"
    case .system: "System"
    }
  }

  /// The scheme to force at the app root. `nil` lets the device decide.
  var colorScheme: ColorScheme? {
    switch self {
    case .light: .light
    case .dark: .dark
    case .system: nil
    }
  }

  /// UserDefaults key shared by the app root and the Settings control.
  static let storageKey = "sapientiaAppearance"

  /// Read the stored choice, defaulting to `.system`.
  static var current: AppearanceSetting {
    UserDefaults.standard.string(forKey: storageKey)
      .flatMap(AppearanceSetting.init(rawValue:)) ?? .system
  }
}
