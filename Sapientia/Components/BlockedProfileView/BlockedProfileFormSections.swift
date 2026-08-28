import FamilyControls
import SwiftUI

struct ProfileFieldDivider: View {
  var isVisible: Bool

  var body: some View {
    if isVisible {
      Divider()
    }
  }
}

struct BlockedProfileNameFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool
  var showsFieldLabels: Bool = true

  var body: some View {
    TextField(
      showsFieldLabels ? "Profile Name" : "",
      text: $draft.name,
      prompt: Text("Profile Name")
    )
    .textContentType(.none)
    .disabled(disabled)
  }
}

struct BlockedProfileNameSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    BlueprintFormSection(title: "Name") {
      BlockedProfileNameFields(draft: draft, disabled: disabled)
    }
  }
}

struct BlockedProfileStrategyFields: View {
  @EnvironmentObject private var themeManager: ThemeManager

  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingStrategyPicker: Bool
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    SapientiaSegmentedPicker(
      options: BlockedProfileDraft.StrategyFamily.allCases,
      label: { $0.rawValue },
      selection: Binding(
        get: { draft.strategyFamily },
        set: { draft.strategyFamily = $0 }
      )
    )
    .disabled(disabled)
    .listRowSeparator(.hidden)

    Button(action: { showingStrategyPicker = true }) {
      HStack {
        Text("Advanced strategies")
          .foregroundColor(SapientiaTheme.accent700)
        Spacer()
        Image(systemName: "chevron.right")
          .foregroundColor(SapientiaTheme.text.opacity(0.55))
      }
    }
    .disabled(disabled)

    if let selectedStrategy = draft.selectedStrategy {
      ProfileFieldDivider(isVisible: showsSeparators)

      StrategyRow(
        strategy: selectedStrategy,
        isSelected: false,
        onTap: {},
        accessoryStyle: .none
      )
      .allowsHitTesting(false)
    }
  }
}

struct BlockedProfileStrategySection: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingStrategyPicker: Bool
  var disabled: Bool

  var body: some View {
    BlueprintFormSection(
      title: "How it ends",
      footer: "The session opens and closes by touch, not by will."
    ) {
      BlockedProfileStrategyFields(
        draft: draft,
        showingStrategyPicker: $showingStrategyPicker,
        disabled: disabled
      )
    }
  }
}

struct BlockedProfileAppsFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingActivityPicker: Bool
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    BlockedProfileAppSelector(
      selection: draft.selectedActivity,
      buttonAction: { showingActivityPicker = true },
      allowMode: draft.enableAllowMode,
      disabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Allow Only Selected Apps",
      description:
        "Only selected apps stay available during sessions. Turning this on clears your blocked-app selection.",
      isOn: $draft.enableAllowMode,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Block Websites in Safari",
      description:
        "Also block selected websites in Safari. When off, Safari stays unrestricted.",
      isOn: $draft.enableSafariBlocking,
      isDisabled: disabled
    )
    .onChange(of: draft.enableAllowMode) { _, newValue in
      draft.selectedActivity = FamilyActivitySelection(includeEntireCategory: newValue)
    }
  }
}

struct BlockedProfileAppsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingActivityPicker: Bool
  var disabled: Bool

  var body: some View {
    BlueprintFormSection(
      title: draft.enableAllowMode ? "Set apart" : "Set aside",
      footer: "Chosen through Apple's Screen Time picker. Sapientia never sees which apps you named."
    ) {
      BlockedProfileAppsFields(
        draft: draft,
        showingActivityPicker: $showingActivityPicker,
        disabled: disabled
      )
    }
  }
}

struct BlockedProfileDomainsFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingDomainPicker: Bool
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    BlockedProfileDomainSelector(
      domains: draft.domains,
      buttonAction: { showingDomainPicker = true },
      allowMode: draft.enableAllowModeDomain,
      disabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Sync to Mac",
      description:
        "Sync blocked domains with the Sapientia for Mac app.",
      isOn: $draft.enableMacSync,
      isDisabled: disabled
    )
    .onChange(of: draft.enableMacSync) { _, newValue in
      if newValue {
        draft.enableAllowModeDomain = false
        draft.enableAdultContentBlocking = false
      }
    }

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Allow Only Selected Domains",
      description:
        "Only selected domains stay available during sessions.",
      isOn: $draft.enableAllowModeDomain,
      isDisabled: disabled || draft.enableMacSync,
      errorMessage: draft.enableMacSync ? "Allow-only mode isn't supported on Mac." : nil
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Block Adult Websites",
      description:
        "Use Apple's adult-content filter during sessions. Blocking any website turns this on too — "
        + "it is the setting that closes Safari's Private Browsing.",
      isOn: $draft.enableAdultContentBlocking,
      isDisabled: disabled || draft.enableMacSync,
      errorMessage: draft.enableMacSync ? "Adult website blocking isn't supported on Mac." : nil
    )
    .onChange(of: draft.enableAllowModeDomain) { _, newValue in
      if newValue {
        draft.enableAdultContentBlocking = false
      }
    }
    .onChange(of: draft.enableAdultContentBlocking) { _, newValue in
      if newValue {
        draft.enableAllowModeDomain = false
      }
    }
  }
}

struct BlockedProfileDomainsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingDomainPicker: Bool
  var disabled: Bool

  var body: some View {
    BlueprintFormSection(
      title: (draft.enableAllowModeDomain ? "Allowed" : "Blocked") + " Websites"
    ) {
      BlockedProfileDomainsFields(
        draft: draft,
        showingDomainPicker: $showingDomainPicker,
        disabled: disabled
      )
    }
  }
}
