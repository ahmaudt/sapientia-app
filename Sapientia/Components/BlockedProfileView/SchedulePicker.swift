import SwiftUI

struct SchedulePicker: View {
  @EnvironmentObject var themeManager: ThemeManager

  @Binding var schedule: BlockedProfileSchedule
  @Binding var isPresented: Bool

  private let hours12: [Int] = Array(1...12)
  private let minutes: [Int] = Array(stride(from: 0, through: 55, by: 5))

  @State private var startDisplayHour: Int = 9
  @State private var startMinute: Int = 0
  @State private var startIsPM: Bool = false
  @State private var endDisplayHour: Int = 10
  @State private var endMinute: Int = 0
  @State private var endIsPM: Bool = false
  @State private var selectedDays: [Weekday] = []
  @State private var showStartPicker: Bool = false
  @State private var showEndPicker: Bool = false

  private let minimumDurationMinutes: Int = 60

  private var startTotalMinutes: Int {
    hour12To24(startDisplayHour, isPM: startIsPM) * 60 + startMinute
  }
  private var endTotalMinutes: Int { hour12To24(endDisplayHour, isPM: endIsPM) * 60 + endMinute }

  private var durationMinutes: Int {
    // If end is before start, it's a cross-day schedule
    if endTotalMinutes <= startTotalMinutes {
      // Duration spans to next day: (minutes until midnight) + (minutes from midnight to end)
      return (24 * 60 - startTotalMinutes) + endTotalMinutes
    }
    return endTotalMinutes - startTotalMinutes
  }

  private var isValid: Bool {
    !selectedDays.isEmpty && durationMinutes >= minimumDurationMinutes
  }

  private var validationMessage: String? {
    guard !isValid else { return nil }

    if selectedDays.isEmpty {
      return ""
    }

    return "Schedule must be at least 1 hour long."
  }

  private var draftSchedule: BlockedProfileSchedule {
    BlockedProfileSchedule(
      days: selectedDays,
      startHour: hour12To24(startDisplayHour, isPM: startIsPM),
      startMinute: startMinute,
      endHour: hour12To24(endDisplayHour, isPM: endIsPM),
      endMinute: endMinute
    )
  }

  private var nextStartMessage: String? {
    draftSchedule.nextStartMessage()
  }

  var body: some View {
    BlueprintStage(
      title: "Schedule",
      leadingLabel: "Cancel",
      leadingAction: { isPresented = false },
      trailingLabel: "Done",
      trailingAction: {
        applySelection()
        isPresented = false
      }
    ) {
      VStack(alignment: .leading, spacing: SapientiaTheme.space6) {
        VStack(alignment: .leading, spacing: 2) {
          Text("Run on a schedule")
            .font(.sapientiaHeading(20))
            .foregroundColor(SapientiaTheme.text)
          Text("The rule begins and ends without you.")
            .font(.sapientiaBody(13))
            .foregroundColor(SapientiaTheme.text.opacity(0.55))
        }

        BlueprintFormSection(title: "Days") { daysStrip }

        BlueprintListRow(
          title: "From",
          onTap: selectedDays.isEmpty ? nil : toggleStartPicker
        ) {
          BlueprintRowValue(
            value: formattedTimeString(
              hour: startDisplayHour, minute: startMinute, isPM: startIsPM))
        }
        if showStartPicker {
          timePickers(hour: $startDisplayHour, minute: $startMinute, isPM: $startIsPM)
        }

        BlueprintListRow(
          title: "Until",
          onTap: selectedDays.isEmpty ? nil : toggleEndPicker
        ) {
          BlueprintRowValue(
            value: formattedTimeString(
              hour: endDisplayHour, minute: endMinute, isPM: endIsPM))
        }
        if showEndPicker {
          timePickers(hour: $endDisplayHour, minute: $endMinute, isPM: $endIsPM)
        }

        if let validationMessage, !validationMessage.isEmpty {
          Text(validationMessage)
            .font(.sapientiaBody(13))
            .foregroundColor(SapientiaTheme.accent700)
        }

        if let message = nextStartMessage {
          BlueprintFormSection(title: "This week", footer: message) {
            SwiftUI.EmptyView()
          }
        }

        Button("Remove schedule") {
          resetToDefault()
          applySelection()
          isPresented = false
        }
        .font(.sapientiaBody(15))
        .foregroundColor(SapientiaTheme.accent700)
        .padding(.top, SapientiaTheme.space2)
      }
    }
    .onAppear(perform: loadFromBinding)
  }

  private var daysStrip: some View {
    HStack(spacing: 1) {
      ForEach(Weekday.allCases, id: \.rawValue) { day in
        let isSelected = selectedDays.contains(day)
        Button {
          if isSelected {
            selectedDays.removeAll { $0 == day }
          } else {
            selectedDays.append(day)
          }
          if selectedDays.isEmpty {
            showStartPicker = false
            showEndPicker = false
          }
        } label: {
          Text(shortLabel(for: day))
            .font(.sapientiaHeading(15))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(isSelected ? SapientiaTheme.accent : SapientiaTheme.background)
            .foregroundColor(isSelected ? SapientiaTheme.paper : SapientiaTheme.text)
            .contentShape(Rectangle())
            .accessibilityLabel(day.name)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
        .buttonStyle(.plain)
      }
    }
    .background(SapientiaTheme.divider)
    .border(SapientiaTheme.divider, width: 1)
    .padding(.top, SapientiaTheme.space2)
  }

  @ViewBuilder
  private func timePickers(hour: Binding<Int>, minute: Binding<Int>, isPM: Binding<Bool>)
    -> some View
  {
    HStack {
      Picker("Hour", selection: hour) {
        ForEach(hours12, id: \.self) { h in
          Text(String(format: "%02d", h)).tag(h)
        }
      }
      .labelsHidden()
      .pickerStyle(.wheel)
      .frame(maxWidth: .infinity)

      Text(":")
        .font(.headline)
        .foregroundColor(SapientiaTheme.text.opacity(0.55))

      Picker("Minute", selection: minute) {
        ForEach(minutes, id: \.self) { m in
          Text(String(format: "%02d", m)).tag(m)
        }
      }
      .labelsHidden()
      .pickerStyle(.wheel)
      .frame(maxWidth: .infinity)

      Picker("AM/PM", selection: isPM) {
        Text("AM").tag(false)
        Text("PM").tag(true)
      }
      .labelsHidden()
      .pickerStyle(.wheel)
      .frame(maxWidth: .infinity)
    }
    .font(.title3)
  }

  private func loadFromBinding() {
    // Days
    selectedDays = schedule.days

    // Start time
    setDisplay(from24Hour: schedule.startHour, forStart: true)
    startMinute = roundedToFive(schedule.startMinute)

    // End time
    setDisplay(from24Hour: schedule.endHour, forStart: false)
    endMinute = roundedToFive(schedule.endMinute)
  }

  private func applySelection() {
    schedule.days = selectedDays.sorted { $0.rawValue < $1.rawValue }

    schedule.startHour = hour12To24(startDisplayHour, isPM: startIsPM)
    schedule.startMinute = startMinute
    schedule.endHour = hour12To24(endDisplayHour, isPM: endIsPM)
    schedule.endMinute = endMinute
  }

  private func roundedToFive(_ value: Int) -> Int {
    let remainder = value % 5
    let down = value - remainder
    let up = min(value + (5 - remainder), 55)
    // Choose the nearer multiple; tie rounds up
    if remainder == 0 { return value }
    if value - down < up - value { return down }
    return up
  }

  private func setDisplay(from24Hour hour24: Int, forStart: Bool) {
    let converted = from24ToDisplay(hour24)
    if forStart {
      startDisplayHour = converted.hour
      startIsPM = converted.isPM
    } else {
      endDisplayHour = converted.hour
      endIsPM = converted.isPM
    }
  }

  private func from24ToDisplay(_ hour24: Int) -> (hour: Int, isPM: Bool) {
    let isPM = hour24 >= 12
    var hour = hour24 % 12
    if hour == 0 { hour = 12 }
    return (hour, isPM)
  }

  private func hour12To24(_ hour12: Int, isPM: Bool) -> Int {
    if hour12 == 12 { return isPM ? 12 : 0 }
    return isPM ? hour12 + 12 : hour12
  }

  private func shortLabel(for day: Weekday) -> String {
    switch day {
    case .sunday: return "Su"
    case .monday: return "Mo"
    case .tuesday: return "Tu"
    case .wednesday: return "We"
    case .thursday: return "Th"
    case .friday: return "Fr"
    case .saturday: return "Sa"
    }
  }

  private func formattedTimeString(hour: Int, minute: Int, isPM: Bool) -> String {
    "\(hour):\(String(format: "%02d", minute)) \(isPM ? "PM" : "AM")"
  }

  private func toggleStartPicker() {
    withAnimation(.easeInOut) {
      showStartPicker.toggle()
      if showStartPicker { showEndPicker = false }
    }
  }

  private func toggleEndPicker() {
    withAnimation(.easeInOut) {
      showEndPicker.toggle()
      if showEndPicker { showStartPicker = false }
    }
  }

  private func resetToDefault() {
    // Reset to default values: empty days, 9AM-5PM
    selectedDays = []
    startDisplayHour = 9
    startMinute = 0
    startIsPM = false
    endDisplayHour = 5
    endMinute = 0
    endIsPM = true
  }
}

#Preview {
  @Previewable @State var isPresented: Bool = true
  @Previewable @State var schedule: BlockedProfileSchedule = .init(
    days: [],
    startHour: 9,
    startMinute: 0,
    endHour: 11,
    endMinute: 0,
    updatedAt: Date()
  )

  return SchedulePicker(schedule: $schedule, isPresented: $isPresented)
}
