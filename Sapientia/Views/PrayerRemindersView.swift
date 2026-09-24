import SwiftUI
import UserNotifications

/// Screen 29 — when the hours are announced, and how they behave.
struct PrayerRemindersView: View {
  var center: UserNotificationCentering = SystemNotificationCenter()
  var editor: RemindersEditor = RemindersEditor()

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  @State private var rows: [PrayerReminderRow] = PrayerRemindersModel.rows()
  @State private var remindsOnSundays = LittleHoursSettings.remindsOnSundays
  @State private var remindsDuringSession = LittleHoursSettings.remindsDuringSession
  @State private var authorization: UNAuthorizationStatus = .authorized
  @State private var hourBeingTimed: LittleHour?

  @State private var collectEnabled = CollectReminderSettings.isEnabled
  @State private var collectDays = CollectReminderSettings.whichDays
  @State private var collectTimes = CollectReminderSettings.times
  @State private var eveningEnabled = CollectReminderSettings.eveningBeforeEnabled
  @State private var eveningMinutes = CollectReminderSettings.eveningBeforeMinutes
  @State private var collectSlotBeingTimed: CollectTimeSlot?

  var body: some View {
    BlueprintStage(
      title: "Reminders",
      leadingLabel: "Back",
      leadingAction: { dismiss() }
    ) {
      VStack(alignment: .leading, spacing: SapientiaTheme.space6) {
        Text(
          "A notice names the hour when it comes. Nothing repeats, nothing nags — one notice per hour, dismissed by praying it or by the day ending."
        )
        .font(.sapientiaBody(15))
        .lineSpacing(4)
        .foregroundColor(SapientiaTheme.text.opacity(0.62))
        .fixedSize(horizontal: false, vertical: true)

        if PrayerRemindersModel.showsSettingsLink(for: authorization) {
          settingsLink
        }

        hoursSection
        collectSection
        conductSection
        previewCard
      }
    }
    .onAppear(perform: refresh)
    .sheet(item: $hourBeingTimed) { hour in
      ReminderTimePicker(initialMinutes: LittleHoursSettings.minutes(for: hour)) { minutes in
        editor.setTime(minutes, for: hour)
        rows = PrayerRemindersModel.rows()
      }
    }
    .sheet(item: $collectSlotBeingTimed) { slot in
      ReminderTimePicker(initialMinutes: minutes(for: slot)) { minutes in
        switch slot {
        case .time(let index): editor.setCollectTime(minutes, at: index)
        case .evening: editor.setEveningMinutes(minutes)
        }
        refreshCollect()
      }
    }
  }

  // MARK: - Sections

  private var settingsLink: some View {
    Button {
      if let url = URL(string: UIApplication.openSettingsURLString) {
        openURL(url)
      }
    } label: {
      HStack(alignment: .firstTextBaseline, spacing: SapientiaTheme.space2) {
        Text(PrayerRemindersModel.settingsNotice)
          .font(.sapientiaBody(14))
          .multilineTextAlignment(.leading)
        Text("Open")
          .font(.sapientiaHeading(13))
          .kerning(1.0)
          .textCase(.uppercase)
      }
      .foregroundColor(SapientiaTheme.accent700)
      .fixedSize(horizontal: false, vertical: true)
      .padding(SapientiaTheme.space3)
      .frame(maxWidth: .infinity, alignment: .leading)
      .border(SapientiaTheme.accent, width: 1)
    }
    .buttonStyle(.plain)
  }

  private var hoursSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      SectionHeaderLabel(title: "The Little Hours")
      ForEach(rows, id: \.hour) { row in
        HStack(alignment: .center, spacing: SapientiaTheme.space3) {
          VStack(alignment: .leading, spacing: 2) {
            Text(row.title)
              .font(.sapientiaBody(17))
              .foregroundColor(SapientiaTheme.text)
            Text(row.caption)
              .font(.sapientiaBody(13))
              .foregroundColor(SapientiaTheme.text.opacity(0.55))
          }
          Spacer(minLength: SapientiaTheme.space3)

          Button {
            hourBeingTimed = row.hour
          } label: {
            Text(row.timeLabel)
              .font(.sapientiaHeading(20))
              .foregroundColor(SapientiaTheme.accent700)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Change the time for \(row.title)")

          Toggle(
            "",
            isOn: Binding(
              get: { row.isEnabled },
              set: { newValue in
                editor.setEnabled(newValue, for: row.hour)
                rows = PrayerRemindersModel.rows()
              })
          )
          .labelsHidden()
          .toggleStyle(BlueprintToggleStyle())
          .frame(width: 44)
        }
        .padding(.vertical, SapientiaTheme.space4)
        .overlay(alignment: .bottom) {
          Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
        }
      }
    }
  }

  private var collectSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      SectionHeaderLabel(title: "The Collect")
      CustomToggle(
        title: "Collect reminder",
        description: "The day's collect, naming its saint or feast.",
        isOn: Binding(
          get: { collectEnabled },
          set: { newValue in
            collectEnabled = newValue
            editor.setCollectEnabled(newValue)
          })
      )

      if collectEnabled {
        SapientiaSegmentedPicker(
          options: CollectReminderDays.allCases,
          label: PrayerRemindersModel.label(for:),
          selection: Binding(
            get: { collectDays },
            set: { newValue in
              collectDays = newValue
              editor.setCollectDays(newValue)
            })
        )
        .padding(.vertical, SapientiaTheme.space3)

        ForEach(Array(collectTimes.enumerated()), id: \.offset) { index, minutes in
          reminderTimeRow(
            title: collectTimes.count == 1 ? "Reminder" : "Reminder \(index + 1)",
            minutes: minutes,
            onTime: { collectSlotBeingTimed = .time(index: index) },
            onRemove: collectTimes.count > 1
              ? {
                editor.removeCollectTime(at: index)
                refreshCollect()
              } : nil)
        }

        if let next = PrayerRemindersModel.nextCollectTime(after: collectTimes) {
          Button {
            editor.addCollectTime(next)
            refreshCollect()
          } label: {
            Text("Add a time")
              .font(.sapientiaHeading(15))
              .kerning(1.2)
              .textCase(.uppercase)
              .foregroundColor(SapientiaTheme.accent700)
          }
          .buttonStyle(.plain)
          .padding(.vertical, SapientiaTheme.space4)
        }

        CustomToggle(
          title: "The evening before",
          description: "Names tomorrow's saint or feast.",
          isOn: Binding(
            get: { eveningEnabled },
            set: { newValue in
              eveningEnabled = newValue
              editor.setEveningBefore(newValue)
            }),
          showsDivider: !eveningEnabled
        )
        if eveningEnabled {
          reminderTimeRow(
            title: "Time",
            accessibilityName: "the evening before",
            minutes: eveningMinutes,
            onTime: { collectSlotBeingTimed = .evening },
            onRemove: nil)
        }

        Text(PrayerRemindersModel.collectHorizonCaption)
          .font(.sapientiaBody(13))
          .foregroundColor(SapientiaTheme.text.opacity(0.55))
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, SapientiaTheme.space3)
      }
    }
  }

  /// A ruled row with a time the user taps to change, in the Little Hours'
  /// row style, and an optional remove control.
  private func reminderTimeRow(
    title: String, accessibilityName: String? = nil, minutes: Int,
    onTime: @escaping () -> Void, onRemove: (() -> Void)?
  ) -> some View {
    HStack(alignment: .center, spacing: SapientiaTheme.space3) {
      Text(title)
        .font(.sapientiaBody(17))
        .foregroundColor(SapientiaTheme.text)
      Spacer(minLength: SapientiaTheme.space3)
      Button(action: onTime) {
        Text(LittleHoursRowModel.timeLabel(minutes))
          .font(.sapientiaHeading(20))
          .foregroundColor(SapientiaTheme.accent700)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Change the time for \(accessibilityName ?? title)")
      if let onRemove {
        Button(action: onRemove) {
          Image(systemName: "minus.circle")
            // 55% ink is 3.6:1 on paper: a control needs 3:1, 45% was 2.75.
            .foregroundColor(SapientiaTheme.text.opacity(0.55))
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove \(accessibilityName ?? title)")
      }
    }
    .padding(.vertical, SapientiaTheme.space4)
    .overlay(alignment: .bottom) {
      Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
    }
  }

  private var conductSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      SectionHeaderLabel(title: "Conduct")
      CustomToggle(
        title: "During a held session",
        description: "The notice still comes; the office is never blocked.",
        isOn: Binding(
          get: { remindsDuringSession },
          set: { newValue in
            remindsDuringSession = newValue
            editor.setRemindsDuringSession(newValue)
          })
      )
      CustomToggle(
        title: "On Sundays",
        description: "Quiet. Matins and Evensong belong to the parish.",
        isOn: Binding(
          get: { remindsOnSundays },
          set: { newValue in
            remindsOnSundays = newValue
            editor.setRemindsOnSundays(newValue)
          })
      )
    }
  }

  private var previewCard: some View {
    let preview = PrayerRemindersModel.previewNotice()
    return BlueprintCard(padding: 0) {
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text("The notice, as iOS shows it")
            .font(.sapientiaHeading(12))
            .kerning(1.2)
            .textCase(.uppercase)
            .foregroundColor(SapientiaTheme.text.opacity(0.55))
          Spacer()
          Text("System UI")
            .font(.sapientiaBody(11))
            .foregroundColor(SapientiaTheme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .border(SapientiaTheme.accent, width: 1)
        }
        .padding(.horizontal, SapientiaTheme.space4)
        .padding(.vertical, SapientiaTheme.space3)
        .overlay(alignment: .bottom) {
          Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
        }

        VStack(alignment: .leading, spacing: 2) {
          HStack(alignment: .firstTextBaseline) {
            Text(preview.title)
              .font(.sapientiaHeading(20))
              .foregroundColor(SapientiaTheme.text)
            Spacer()
            Text(preview.time)
              .font(.sapientiaBody(12))
              .foregroundColor(SapientiaTheme.text.opacity(0.45))
          }
          Text(preview.body)
            .font(.sapientiaBody(14))
            .foregroundColor(SapientiaTheme.text.opacity(0.62))
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, SapientiaTheme.space4)
        .padding(.vertical, SapientiaTheme.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SapientiaTheme.background)
        .border(SapientiaTheme.divider, width: 1)
        .padding(SapientiaTheme.space4)
        .background(HatchBackdrop())
      }
    }
  }

  // MARK: - Behavior

  private func refreshCollect() {
    collectEnabled = CollectReminderSettings.isEnabled
    collectDays = CollectReminderSettings.whichDays
    collectTimes = CollectReminderSettings.times
    eveningEnabled = CollectReminderSettings.eveningBeforeEnabled
    eveningMinutes = CollectReminderSettings.eveningBeforeMinutes
  }

  private func minutes(for slot: CollectTimeSlot) -> Int {
    switch slot {
    case .time(let index): return collectTimes.indices.contains(index) ? collectTimes[index] : 360
    case .evening: return eveningMinutes
    }
  }

  private func refresh() {
    refreshCollect()
    rows = PrayerRemindersModel.rows()
    remindsOnSundays = LittleHoursSettings.remindsOnSundays
    remindsDuringSession = LittleHoursSettings.remindsDuringSession
    center.authorizationStatus { status in
      DispatchQueue.main.async {
        authorization = status
        // Not asked yet: ask now, so enabling an hour actually delivers.
        if status == .notDetermined {
          center.requestAuthorization { _ in
            center.authorizationStatus { updated in
              DispatchQueue.main.async { authorization = updated }
            }
          }
        }
      }
    }
  }
}

/// The diagonal hatch behind the notice preview, marking it as a depiction of
/// system UI rather than a control of ours.
private struct HatchBackdrop: View {
  var body: some View {
    Canvas { context, size in
      let spacing: CGFloat = 12
      var offset: CGFloat = -size.height
      let stroke = Color(SapientiaTheme.text).opacity(0.06)
      while offset < size.width {
        var path = Path()
        path.move(to: CGPoint(x: offset, y: size.height))
        path.addLine(to: CGPoint(x: offset + size.height, y: 0))
        context.stroke(path, with: .color(stroke), lineWidth: 1)
        offset += spacing
      }
    }
  }
}

/// Which collect reminder time a picker sheet is editing.
private enum CollectTimeSlot: Identifiable {
  case time(index: Int)
  case evening

  var id: String {
    switch self {
    case .time(let index): return "time-\(index)"
    case .evening: return "evening"
    }
  }
}

/// A squared time picker for one reminder time.
private struct ReminderTimePicker: View {
  let initialMinutes: Int
  let onPick: (Int) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var time: Date = Date()

  var body: some View {
    BlueprintStage(
      title: "Time",
      leadingLabel: "Cancel",
      leadingAction: { dismiss() },
      trailingLabel: "Done",
      trailingAction: {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        onPick((components.hour ?? 0) * 60 + (components.minute ?? 0))
        dismiss()
      }
    ) {
      DatePicker(
        "", selection: $time, displayedComponents: .hourAndMinute
      )
      .datePickerStyle(.wheel)
      .labelsHidden()
      .frame(maxWidth: .infinity)
    }
    .onAppear {
      var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
      components.hour = initialMinutes / 60
      components.minute = initialMinutes % 60
      time = Calendar.current.date(from: components) ?? Date()
    }
  }
}

#Preview {
  PrayerRemindersView()
}
