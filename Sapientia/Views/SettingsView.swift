import FamilyControls
import SwiftData
import SwiftUI

let AMZN_STORE_LINK = "https://amzn.to/4fbMuTM"
let TEMU_STORE_LINK =
  "https://www.temu.com/ca/nfc-sticker-with--blank-chip-operating-at-13-56mhz-is-a-rewritable-label-with-504--of-memory-compatible-with-nfc-enabled-smartphones-g-601102251435878.html"
let ALIEXPRESS_STORE_LINK = "https://www.aliexpress.com/item/1005010075431327.html"

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var requestAuthorizer: RequestAuthorizer
  @EnvironmentObject var strategyManager: StrategyManager

  @Query private var profiles: [BlockedProfiles]

  @State private var blockScreenPrayer = PrayerSettings.blockScreenPrayer
  @State private var calendarChoice = PrayerSettings.calendarChoice
  @State private var feastNoticeEnabled = PrayerSettings.feastNoticeEnabled

  @State private var showResetBlockingStateAlert = false
  @State private var showDebugView = false
  @State private var showSupportView = false

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
      ?? "1.0"
  }

  private var pairedItemCount: Int {
    profiles.reduce(0) { $0 + ($1.physicalUnblockItems?.count ?? 0) }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          SapientiaRadioRow(
            title: "Prayer of St. Benedict",
            subtitle: "The same words each time.",
            isSelected: blockScreenPrayer == .benedict
          ) {
            blockScreenPrayer = .benedict
            PrayerSettings.blockScreenPrayer = .benedict
          }
          SapientiaRadioRow(
            title: "Collect of the day",
            subtitle: "Follows the calendar below.",
            isSelected: blockScreenPrayer == .collect
          ) {
            blockScreenPrayer = .collect
            PrayerSettings.blockScreenPrayer = .collect
          }
        } header: {
          Text("What the block screen says")
        }

        Section {
          SapientiaSegmentedPicker(
            options: [LiturgicalCalendarChoice.ordinariate, .roman],
            label: { $0 == .ordinariate ? "Ordinariate" : "Roman" },
            selection: $calendarChoice,
            isDisabled: { $0 == .roman }
          )
          .listRowSeparator(.hidden)

          Toggle(isOn: $feastNoticeEnabled) {
            VStack(alignment: .leading, spacing: 2) {
              Text("Feast day notice")
              Text("Each morning at 6:00.")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .onChange(of: feastNoticeEnabled) { _, enabled in
            PrayerSettings.feastNoticeEnabled = enabled
            let scheduler = FeastNotificationScheduler()
            if enabled {
              scheduler.center.requestAuthorization { _ in
                scheduler.reschedule()
              }
            } else {
              scheduler.reschedule()
            }
          }
        } header: {
          Text("Calendar")
        } footer: {
          Text("The Roman calendar is coming soon.")
        }

        Section("Sessions") {
          HStack {
            Text("Emergency unblocks")
            Spacer()
            Text("\(strategyManager.getRemainingEmergencyUnblocks()) left")
              .foregroundStyle(.secondary)
          }
          HStack {
            Text("Paired tags & codes")
            Spacer()
            Text("\(pairedItemCount)")
              .foregroundStyle(.secondary)
          }
          HStack {
            Text("Screen Time permission")
            Spacer()
            Text(
              requestAuthorizer.getAuthorizationStatus() == .approved
                ? "Granted" : "Not granted"
            )
            .font(.sapientiaBody(13))
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(
              requestAuthorizer.getAuthorizationStatus() == .approved
                ? SapientiaTheme.accent100 : SapientiaTheme.neutral200
            )
            .foregroundColor(
              requestAuthorizer.getAuthorizationStatus() == .approved
                ? SapientiaTheme.accent800 : SapientiaTheme.neutral700)
          }
        }

        AppIconPicker(selectionColor: themeManager.themeColor)

        Section("Support") {
          Button {
            showSupportView = true
          } label: {
            HStack {
              Text("Support Sapientia")
                .foregroundColor(.primary)
              Spacer()
              Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
            }
          }
        }

        Section("Help") {
          HStack {
            Text("Debug Mode")
              .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
              .foregroundColor(.secondary)
              .font(.caption)
          }
          .contentShape(Rectangle())
          .onTapGesture {
            showDebugView = true
          }

          Link(destination: URL(string: "https://www.sapientia.app/blocking-native-apps.html")!) {
            HStack {
              Text("Blocking Native Apps")
                .foregroundColor(.primary)
              Spacer()
              Image(systemName: "arrow.up.right.square")
                .foregroundColor(.secondary)
            }
          }

          if !strategyManager.isBlocking {
            Button {
              showResetBlockingStateAlert = true
            } label: {
              Text("Reset Blocking State")
                .foregroundColor(SapientiaTheme.accent700)
            }
          }
        }

        Section("About") {
          HStack {
            Text("Version")
              .foregroundStyle(.primary)
            Spacer()
            Text("v\(appVersion)")
              .foregroundStyle(.secondary)
          }

          HStack {
            Text("Made in")
              .foregroundStyle(.primary)
            Spacer()
            Text("Calgary AB 🇨🇦")
              .foregroundStyle(.secondary)
          }
        }

        Section("Buy NFC Tags") {
          Link(destination: URL(string: AMZN_STORE_LINK)!) {
            HStack {
              Text("Amazon")
                .foregroundColor(.primary)
              Spacer()
              Image(systemName: "arrow.up.right.square")
                .foregroundColor(.secondary)
            }
          }
          Link(destination: URL(string: TEMU_STORE_LINK)!) {
            HStack {
              Text("Temu")
                .foregroundColor(.primary)
              Spacer()
              Image(systemName: "arrow.up.right.square")
                .foregroundColor(.secondary)
            }
          }

          Link(destination: URL(string: ALIEXPRESS_STORE_LINK)!) {
            HStack {
              Text("AliExpress")
                .foregroundColor(.primary)
              Spacer()
              Image(systemName: "arrow.up.right.square")
                .foregroundColor(.secondary)
            }
          }
        }

        Section {
          BlueprintCard {
            Text(
              "Blocking runs on Apple's Screen Time API. Sapientia cannot see which apps you set aside, and no prayer text leaves the device."
            )
            .font(.sapientiaBody(13))
            .lineSpacing(4)
            .foregroundColor(SapientiaTheme.text.opacity(0.62))
          }
          .listRowInsets(EdgeInsets())
          .listRowBackground(Color.clear)
        }

      }
      .navigationTitle("Settings")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Done") { dismiss() }
            .accessibilityLabel("Close")
        }
      }
      .alert("Reset Blocking State", isPresented: $showResetBlockingStateAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Reset", role: .destructive) {
          strategyManager.resetBlockingState(context: context)
        }
      } message: {
        Text(
          "This will clear all app restrictions and remove any ghost schedules. Only use this if you're locked out and no profile is active."
        )
      }
      .sheet(isPresented: $showDebugView) {
        DebugView()
      }
      .sheet(isPresented: $showSupportView) {
        SupportView()
      }
    }
  }
}

#Preview {
  SettingsView()
    .environmentObject(ThemeManager.shared)
    .environmentObject(RequestAuthorizer())
    .environmentObject(StrategyManager.shared)
    .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
