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
        conductSection
        previewCard
      }
    }
    .onAppear(perform: refresh)
    .sheet(item: $hourBeingTimed) { hour in
      HourTimePicker(hour: hour) { minutes in
        editor.setTime(minutes, for: hour)
        rows = PrayerRemindersModel.rows()
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

  private func refresh() {
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

/// A squared time picker for one hour.
private struct HourTimePicker: View {
  let hour: LittleHour
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
      let minutes = LittleHoursSettings.minutes(for: hour)
      var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
      components.hour = minutes / 60
      components.minute = minutes % 60
      time = Calendar.current.date(from: components) ?? Date()
    }
  }
}

#Preview {
  PrayerRemindersView()
}
