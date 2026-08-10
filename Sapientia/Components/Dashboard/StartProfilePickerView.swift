import SwiftUI
import UIKit

/// The start-a-rule picker (presented from Home). Blueprint radio rows and a
/// primary CTA — no rounded cards, glass, or racing-flag pill.
struct StartProfilePickerView: View {
  @Environment(\.dismiss) private var dismiss

  let profiles: [BlockedProfiles]
  let isBlocking: Bool
  let activeSessionProfileId: UUID?
  let startingProfileId: UUID?
  let onGoTapped: (BlockedProfiles) -> Void

  @State private var selectedProfileId: UUID?

  init(
    profiles: [BlockedProfiles],
    isBlocking: Bool,
    activeSessionProfileId: UUID?,
    startingProfileId: UUID? = nil,
    onGoTapped: @escaping (BlockedProfiles) -> Void
  ) {
    self.profiles = profiles
    self.isBlocking = isBlocking
    self.activeSessionProfileId = activeSessionProfileId
    self.startingProfileId = startingProfileId
    self.onGoTapped = onGoTapped
    _selectedProfileId = State(
      initialValue: profiles.first(where: { $0.id == startingProfileId })?.id ?? profiles.first?.id)
  }

  private var selectedProfile: BlockedProfiles? {
    guard let selectedProfileId else { return nil }
    return profiles.first(where: { $0.id == selectedProfileId })
  }

  private var canGo: Bool { selectedProfile != nil && !isBlocking }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Start a rule").sapientiaKicker()
        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.top, SapientiaTheme.space6)
      .padding(.bottom, SapientiaTheme.space3)

      Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
        .padding(.horizontal, 16)

      if profiles.isEmpty {
        Text("Create a rule before starting a session.")
          .font(.sapientiaBody(15))
          .foregroundColor(SapientiaTheme.text.opacity(0.55))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
      } else {
        ScrollView(showsIndicators: false) {
          VStack(alignment: .leading, spacing: 0) {
            if isBlocking { activeSessionNotice }
            ForEach(profiles) { profile in
              SapientiaRadioRow(
                title: profile.name,
                subtitle: meta(for: profile),
                isSelected: profile.id == selectedProfileId
              ) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selectedProfileId = profile.id
              }
              Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
            }
          }
          .padding(.horizontal, 16)
          .padding(.top, SapientiaTheme.space4)
        }
      }

      Button("Go") { goTapped() }
        .buttonStyle(BlueprintPrimaryButtonStyle())
        .disabled(!canGo)
        .padding(.horizontal, 16)
        .padding(.top, SapientiaTheme.space3)
        .padding(.bottom, SapientiaTheme.space6)
    }
    .background(SapientiaTheme.background.ignoresSafeArea())
    .onChange(of: profiles) { _, newProfiles in
      if selectedProfile == nil { selectedProfileId = newProfiles.first?.id }
    }
    .onChange(of: startingProfileId) { _, newValue in
      if let newValue, profiles.contains(where: { $0.id == newValue }) {
        selectedProfileId = newValue
      }
    }
  }

  private var activeSessionNotice: some View {
    BlueprintCard {
      Text("A rule is already active. Stop it before starting another.")
        .font(.sapientiaBody(13))
        .foregroundColor(SapientiaTheme.text.opacity(0.62))
    }
    .padding(.bottom, SapientiaTheme.space4)
  }

  private func meta(for profile: BlockedProfiles) -> String {
    RuleRowMeta.metaString(
      appCount: profile.selectedActivity.applicationTokens.count,
      categoryCount: profile.selectedActivity.categoryTokens.count,
      strategyId: profile.blockingStrategyId,
      isStrict: profile.enableStrictMode,
      scheduleText: nil
    )
  }

  private func goTapped() {
    guard let selectedProfile, !isBlocking else { return }
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    onGoTapped(selectedProfile)
    dismiss()
  }
}

#Preview {
  StartProfilePickerView(
    profiles: [BlockedProfiles(name: "Deep Work"), BlockedProfiles(name: "Great Silence")],
    isBlocking: false,
    activeSessionProfileId: nil,
    onGoTapped: { _ in }
  )
}
