import Darwin
import SwiftUI

@main
struct SapientiaMacApp: App {
  @NSApplicationDelegateAdaptor(SapientiaMacAppDelegate.self) private var appDelegate

  @StateObject private var controller: SapientiaMacController
  @StateObject private var filterManager: SapientiaFilterManager
  @StateObject private var onboardingController: SapientiaOnboardingWindowController
  @StateObject private var updaterController: SapientiaUpdaterController

  init() {
    let filterManager = SapientiaFilterManager()
    let onboardingController = SapientiaOnboardingWindowController(filterManager: filterManager)
    _filterManager = StateObject(wrappedValue: filterManager)
    _controller = StateObject(wrappedValue: SapientiaMacController(filterManager: filterManager))
    _onboardingController = StateObject(wrappedValue: onboardingController)
    _updaterController = StateObject(wrappedValue: SapientiaUpdaterController())
    appDelegate.configure(
      filterManager: filterManager,
      onboardingController: onboardingController
    )

    #if DEBUG
      if CommandLine.arguments.contains("--reset-network-extension") {
        Task { @MainActor in
          filterManager.resetForDevelopment { result in
            switch result {
            case .success(let requiresRestart):
              if requiresRestart {
                print("Sapientia reset is pending. Restart this Mac to finish removing the extension.")
              } else {
                print(
                  "Sapientia filter configuration was removed and the system extension was deactivated."
                )
              }
              exit(EXIT_SUCCESS)
            case .failure(let error):
              fputs("Unable to reset Sapientia: \(error.localizedDescription)\n", stderr)
              exit(EXIT_FAILURE)
            }
          }
        }
      }
    #endif
  }

  var body: some Scene {
    MenuBarExtra {
      MenuBarContentView()
        .environmentObject(controller)
        .environmentObject(filterManager)
        .environmentObject(onboardingController)
        .environmentObject(updaterController)
    } label: {
      Label("Sapientia", systemImage: menuBarSystemImage)
    }
    .menuBarExtraStyle(.window)
  }

  private var menuBarSystemImage: String {
    switch filterManager.status {
    case .approvalRequired, .disabled, .failed, .notConfigured, .requiresRestart:
      return "exclamationmark.triangle.fill"
    case .enabled:
      return controller.isBlocking ? "hourglass.circle.fill" : "hourglass"
    case .installing, .unknown:
      return "hourglass"
    }
  }
}
