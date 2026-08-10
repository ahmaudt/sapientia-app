import FamilyControls
import SwiftData
import SwiftUI

let AMZN_STORE_LINK = "https://amzn.to/4fbMuTM"
let TEMU_STORE_LINK =
  "https://www.temu.com/ca/nfc-sticker-with--blank-chip-operating-at-13-56mhz-is-a-rewritable-label-with-504--of-memory-compatible-with-nfc-enabled-smartphones-g-601102251435878.html"
let ALIEXPRESS_STORE_LINK = "https://www.aliexpress.com/item/1005010075431327.html"

/// Settings on the blueprint form — prayer choice, calendar, sessions, app
/// icon, help, about, tags. Ruled sections on the paper ground; no `Form`.
struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var requestAuthorizer: RequestAuthorizer
  @EnvironmentObject var strategyManager: StrategyManager

  @Query private var profiles: [BlockedProfiles]

  @AppStorage(AppearanceSetting.storageKey) private var appearanceRaw =
    AppearanceSetting.system.rawValue

  @State private var blockScreenPrayer = PrayerSettings.blockScreenPrayer
  @State private var calendarChoice = PrayerSettings.calendarChoice
  @State private var feastNoticeEnabled = PrayerSettings.feastNoticeEnabled

  private var appearanceBinding: Binding<AppearanceSetting> {
    Binding(
      get: { AppearanceSetting(rawValue: appearanceRaw) ?? .system },
      set: { appearanceRaw = $0.rawValue }
    )
  }

  @State private var showResetBlockingStateAlert = false
  @State private var showDebugView = false
  @State private var showAcknowledgements = false

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
  }
  private var pairedItemCount: Int {
    profiles.reduce(0) { $0 + ($1.physicalUnblockItems?.count ?? 0) }
  }
  private var screenTimeGranted: Bool {
    requestAuthorizer.getAuthorizationStatus() == .approved
  }

  var body: some View {
    BlueprintStage(
      title: "Settings",
      leadingLabel: "Done",
      leadingAction: { dismiss() }
    ) {
      VStack(alignment: .leading, spacing: SapientiaTheme.space8) {
        appearanceSection
        prayerSection
        calendarSection
        sessionsSection
        AppIconPicker(selectionColor: SapientiaTheme.accent)
        helpSection
        aboutSection
        tagsSection
        privacyCard
      }
    }
    .alert("Reset Blocking State", isPresented: $showResetBlockingStateAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Reset", role: .destructive) {
        strategyManager.resetBlockingState(context: context)
      }
    } message: {
      Text(
        "This will clear all app restrictions and remove any ghost schedules. Only use this if you're locked out and no rule is active."
      )
    }
    .sheet(isPresented: $showDebugView) { DebugView() }
    .sheet(isPresented: $showAcknowledgements) { AcknowledgementsView() }
  }

  private var appearanceSection: some View {
    BlueprintFormSection(
      title: "Appearance",
      footer: "The prayer and the scan keep the steel ground in either setting."
    ) {
      SapientiaSegmentedPicker(
        options: AppearanceSetting.allCases,
        label: { $0.label },
        selection: appearanceBinding
      )
      .padding(.vertical, SapientiaTheme.space3)
    }
  }

  private var prayerSection: some View {
    BlueprintFormSection(title: "What the block screen says") {
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
    }
  }

  private var calendarSection: some View {
    BlueprintFormSection(title: "Calendar", footer: "The Roman calendar is coming soon.") {
      SapientiaSegmentedPicker(
        options: [LiturgicalCalendarChoice.ordinariate, .roman],
        label: { $0 == .ordinariate ? "Ordinariate" : "Roman" },
        selection: $calendarChoice,
        isDisabled: { $0 == .roman }
      )
      .padding(.vertical, SapientiaTheme.space3)

      CustomToggle(
        title: "Feast day notice",
        description: "Each morning at 6:00.",
        isOn: $feastNoticeEnabled
      )
      .onChange(of: feastNoticeEnabled) { _, enabled in
        PrayerSettings.feastNoticeEnabled = enabled
        let scheduler = FeastNotificationScheduler()
        if enabled {
          scheduler.center.requestAuthorization { _ in scheduler.reschedule() }
        } else {
          scheduler.reschedule()
        }
      }
    }
  }

  private var sessionsSection: some View {
    BlueprintFormSection(title: "Sessions") {
      BlueprintListRow(title: "Emergency unblocks") {
        BlueprintRowValue(value: "\(strategyManager.getRemainingEmergencyUnblocks()) left")
      }
      BlueprintListRow(title: "Paired tags & codes") {
        BlueprintRowValue(value: "\(pairedItemCount)")
      }
      BlueprintListRow(title: "Screen Time permission") {
        Text(screenTimeGranted ? "Granted" : "Not granted")
          .font(.sapientiaBody(13))
          .padding(.horizontal, 10)
          .padding(.vertical, 3)
          .background(screenTimeGranted ? SapientiaTheme.accent100 : SapientiaTheme.neutral200)
          .foregroundColor(screenTimeGranted ? SapientiaTheme.accent800 : SapientiaTheme.neutral700)
      }
    }
  }

  private var helpSection: some View {
    BlueprintFormSection(title: "Help") {
      BlueprintListRow(title: "Debug mode", onTap: { showDebugView = true }) {
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(SapientiaTheme.text.opacity(0.4))
      }
      Link(destination: URL(string: "https://www.sapientia.app/blocking-native-apps.html")!) {
        BlueprintListRow(title: "Blocking native apps") {
          Image(systemName: "arrow.up.right")
            .font(.caption)
            .foregroundColor(SapientiaTheme.text.opacity(0.4))
        }
      }
      .buttonStyle(.plain)
      if !strategyManager.isBlocking {
        Button("Reset blocking state") { showResetBlockingStateAlert = true }
          .font(.sapientiaBody(15))
          .foregroundColor(SapientiaTheme.accent700)
          .padding(.vertical, SapientiaTheme.space4)
      }
    }
  }

  private var aboutSection: some View {
    BlueprintFormSection(title: "About") {
      BlueprintListRow(title: "Version") { BlueprintRowValue(value: "v\(appVersion)") }
      BlueprintListRow(title: "Made in") { BlueprintRowValue(value: "Calgary AB 🇨🇦") }
      BlueprintListRow(title: "Acknowledgements", onTap: { showAcknowledgements = true }) {
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(SapientiaTheme.text.opacity(0.4))
      }
    }
  }

  private var tagsSection: some View {
    BlueprintFormSection(title: "Buy NFC tags") {
      storeLink("Amazon", AMZN_STORE_LINK)
      storeLink("Temu", TEMU_STORE_LINK)
      storeLink("AliExpress", ALIEXPRESS_STORE_LINK)
    }
  }

  private func storeLink(_ name: String, _ url: String) -> some View {
    Link(destination: URL(string: url)!) {
      BlueprintListRow(title: name) {
        Image(systemName: "arrow.up.right")
          .font(.caption)
          .foregroundColor(SapientiaTheme.text.opacity(0.4))
      }
    }
    .buttonStyle(.plain)
  }

  private var privacyCard: some View {
    BlueprintCard {
      Text(
        "Blocking runs on Apple's Screen Time API. Sapientia cannot see which apps you set aside, and no prayer text leaves the device."
      )
      .font(.sapientiaBody(13))
      .lineSpacing(4)
      .foregroundColor(SapientiaTheme.text.opacity(0.62))
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
