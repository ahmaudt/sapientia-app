import FamilyControls
import SwiftUI

// Rule-editor form sections (continued): physical unlocks, schedule,
// breaks, safeguards, and notifications.

struct BlockedProfileStrictUnlocksFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    BlockedProfilePhysicalUnblockSelector(
      physicalUnblockItems: $draft.physicalUnblockItems,
      disabled: disabled
    )
  }
}

struct BlockedProfileStrictUnlocksSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    BlueprintFormSection(title: "Paired tags & codes") {
      BlockedProfileStrictUnlocksFields(draft: draft, disabled: disabled)
    }
  }
}

struct BlockedProfileScheduleFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingSchedulePicker: Bool
  var disabled: Bool

  var body: some View {
    BlockedProfileScheduleSelector(
      schedule: draft.schedule,
      buttonAction: { showingSchedulePicker = true },
      disabled: disabled
    )
  }
}

struct BlockedProfileScheduleSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingSchedulePicker: Bool
  var disabled: Bool

  var body: some View {
    BlueprintFormSection(title: "Schedule") {
      BlockedProfileScheduleFields(
        draft: draft,
        showingSchedulePicker: $showingSchedulePicker,
        disabled: disabled
      )
    }
  }
}

struct BlockedProfileBreaksFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool
  var showsSeparators: Bool = false

  @ViewBuilder
  var body: some View {
    if draft.selectedStrategyAllowsTimedBreaks {
      CustomToggle(
        title: "Allow Timed Breaks",
        description:
          "Take a break during your session. The break will automatically end after the selected duration.",
        isOn: $draft.enableBreaks,
        isDisabled: disabled
      )

      if draft.enableBreaks {
        ProfileFieldDivider(isVisible: showsSeparators)

        breakDurationPicker

        ProfileFieldDivider(isVisible: showsSeparators)

        CustomToggle(
          title: "Allow Multiple Breaks",
          description: "Take multiple breaks until your total break duration is used.",
          isOn: $draft.allowMultipleBreaks,
          isDisabled: disabled
        )
      }
    } else {
      ProfileFieldNotice(
        title: "Breaks are off for Temporary Access",
        message:
          "This strategy already gives short opens for blocked apps and categories, so timed breaks are not needed for this profile."
      )
    }
  }

  private var breakDurationPicker: some View {
    Picker("Break Duration", selection: $draft.breakTimeInMinutes) {
      Text("5 minutes").tag(5)
      Text("10 minutes").tag(10)
      Text("15 minutes").tag(15)
      Text("30 minutes").tag(30)
    }
    .disabled(disabled)
  }
}

struct BlockedProfileBreaksSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    BlueprintFormSection(title: "Breaks") {
      BlockedProfileBreaksFields(draft: draft, disabled: disabled)
    }
  }
}

struct ProfileFieldNotice: View {
  let title: String
  let message: String

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundColor(SapientiaTheme.text)

      Text(message)
        .font(.caption)
        .foregroundColor(SapientiaTheme.text.opacity(0.55))
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 4)
  }
}

struct BlockedProfileStrictSafeguardsFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    CustomToggle(
      title: "Prevent App Deletion",
      description:
        "Stop apps from being deleted during sessions, including Sapientia.",
      isOn: $draft.enableStrictMode,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Prevent New App Installs",
      description:
        "Stop new apps from being installed during sessions.",
      isOn: $draft.enableBlockAppInstallation,
      isDisabled: disabled
    )
  }
}

struct BlockedProfileSessionSafeguardsFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    CustomToggle(
      title: "Require Sapientia to Stop",
      description:
        "Prevent this profile from being stopped by Shortcuts, NFC links, or QR links outside the app.",
      isOn: $draft.disableBackgroundStops,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Emergency Unblock",
      description:
        "Allow limited emergency unblocks during active sessions.",
      isOn: $draft.enableEmergencyUnblock,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Pray Before Unblocking",
      description:
        "The Collect of the day stands in front of the tag.",
      isOn: $draft.prayBeforeUnblocking,
      isDisabled: disabled
    )
  }
}

struct BlockedProfileStrictSafeguardsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    BlueprintFormSection(title: "Session Protection") {
      BlockedProfileStrictSafeguardsFields(draft: draft, disabled: disabled)
    }
  }
}

struct BlockedProfileSessionSafeguardsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    BlueprintFormSection(title: "Rigour") {
      BlockedProfileSessionSafeguardsFields(draft: draft, disabled: disabled)
    }
  }
}

struct BlockedProfileNotificationsFields: View {
  @EnvironmentObject private var strategyManager: StrategyManager
  @EnvironmentObject private var themeManager: ThemeManager

  @ObservedObject var draft: BlockedProfileDraft
  var profile: BlockedProfiles?
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    CustomToggle(
      title: "Live Activity",
      description:
        "Show session progress on the Lock Screen.",
      isOn: $draft.enableLiveActivity,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Reminder",
      description:
        "Remind you to start this profile when it ends.",
      isOn: $draft.enableReminder,
      isDisabled: disabled
    )

    if draft.enableReminder {
      ProfileFieldDivider(isVisible: showsSeparators)

      HStack {
        Text("Reminder time")
        Spacer()
        TextField(
          "",
          value: $draft.reminderTimeInMinutes,
          format: .number
        )
        .keyboardType(.numberPad)
        .multilineTextAlignment(.trailing)
        .frame(width: 50)
        .disabled(disabled)
        .font(.subheadline)
        .foregroundColor(SapientiaTheme.text.opacity(0.55))

        Text("minutes")
          .font(.subheadline)
          .foregroundColor(SapientiaTheme.text.opacity(0.55))
      }
      .listRowSeparator(.visible)

      ProfileFieldDivider(isVisible: showsSeparators)

      VStack(alignment: .leading) {
        Text("Reminder message")
        TextField(
          "Reminder message",
          text: $draft.customReminderMessage,
          prompt: Text(strategyManager.defaultReminderMessage(forProfile: profile)),
          axis: .vertical
        )
        .foregroundColor(SapientiaTheme.text.opacity(0.55))
        .lineLimit(...3)
        .onChange(of: draft.customReminderMessage) { _, newValue in
          if newValue.count > 178 {
            draft.customReminderMessage = String(newValue.prefix(178))
          }
        }
        .disabled(disabled)
      }
    }

    if !disabled {
      Button {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      } label: {
        Text("Manage notification settings")
          .foregroundColor(SapientiaTheme.accent700)
          .font(.caption)
      }
    }
  }
}

struct BlockedProfileNotificationsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var profile: BlockedProfiles?
  var disabled: Bool

  var body: some View {
    BlueprintFormSection(title: "Notifications") {
      BlockedProfileNotificationsFields(
        draft: draft,
        profile: profile,
        disabled: disabled
      )
    }
  }
}

