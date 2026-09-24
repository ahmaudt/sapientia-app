import SwiftUI

/// Screen 16 — How long. The duration chosen before a timed session begins,
/// on the accent-900 ground the rites share: a kicker, the span as a large
/// Barlow numeral between two square steppers, the common presets, and what
/// the choice commits you to.
///
/// Presented full-screen (`startViewUsesFullScreen`), not as a detent sheet.
struct TimerDurationView: View {
  @Environment(\.dismiss) private var dismiss

  let profileName: String
  let onDurationSelected: (StrategyTimerData) -> Void

  @State private var minutes: Int = 60
  @State private var hideStopButton = false

  private static let liftFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }()

  var body: some View {
    BlueprintStage(
      title: profileName,
      field: .dark,
      leadingLabel: "Cancel",
      leadingAction: { dismiss() },
      scrolls: false
    ) {
      chooser
    } bottom: {
      commitment
    }
  }

  // MARK: - Chooser

  private var chooser: some View {
    VStack(spacing: SapientiaTheme.space8) {
      Spacer(minLength: 0)

      Text("How long is it held")
        .font(.sapientiaHeading(13))
        .kerning(13 * 0.16)
        .textCase(.uppercase)
        .foregroundColor(SapientiaTheme.accent300)

      HStack(spacing: SapientiaTheme.space6) {
        stepper("minus", delta: -TimerDuration.stepMinutes)
        span
        stepper("plus", delta: TimerDuration.stepMinutes)
      }

      presets

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, SapientiaTheme.space6)
  }

  private var span: some View {
    VStack(spacing: SapientiaTheme.space2) {
      Text(TimerDuration.clockText(minutes))
        .font(.sapientiaHeading(68))
        .foregroundColor(SapientiaTheme.paper)
        .contentTransition(.numericText())
      Text("Hours · minutes")
        .font(.sapientiaHeading(13))
        .kerning(1.0)
        .textCase(.uppercase)
        .foregroundColor(SapientiaTheme.onDark(0.55))
    }
    .frame(minWidth: 150)
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: minutes)
  }

  /// Square 52×52 outline button — the design's `.btn-icon` on a dark field.
  private func stepper(_ symbol: String, delta: Int) -> some View {
    let enabled = TimerDuration.stepped(minutes, by: delta) != minutes

    return Button {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        minutes = TimerDuration.stepped(minutes, by: delta)
      }
    } label: {
      Image(systemName: symbol)
        .font(.system(size: 20, weight: .regular))
        .foregroundColor(SapientiaTheme.onDark(enabled ? 0.9 : 0.3))
        .frame(width: 52, height: 52)
        .contentShape(Rectangle())
        .border(SapientiaTheme.onDark(enabled ? 0.45 : 0.18), width: 1)
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: minutes)
  }

  private var presets: some View {
    HStack(spacing: SapientiaTheme.space2) {
      ForEach(TimerDuration.presetMinutes, id: \.self) { preset in
        let selected = minutes == preset
        Button {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            minutes = preset
          }
        } label: {
          Text(TimerDuration.compactText(preset))
            .font(.sapientiaBody(13))
            .padding(.vertical, SapientiaTheme.space2)
            .padding(.horizontal, SapientiaTheme.space3)
            .foregroundColor(
              selected ? SapientiaTheme.accent800 : SapientiaTheme.paper
            )
            .background(selected ? SapientiaTheme.accent100 : Color.clear)
            .border(selected ? Color.clear : SapientiaTheme.onDark(0.35), width: 1)
        }
        .buttonStyle(.plain)
      }
    }
    .sensoryFeedback(.selection, trigger: minutes)
  }

  // MARK: - Commitment

  private var commitment: some View {
    VStack(alignment: .leading, spacing: SapientiaTheme.space4) {
      Rectangle()
        .fill(SapientiaTheme.onDark(0.16))
        .frame(height: 1)

      Toggle(isOn: $hideStopButton) {
        VStack(alignment: .leading, spacing: 2) {
          Text("Hide Stop Button")
            .font(.sapientiaBody(15))
            .foregroundColor(SapientiaTheme.paper)
          Text("Prevent early stopping during timer sessions")
            .font(.sapientiaBody(13))
            .foregroundColor(SapientiaTheme.onDark(0.6))
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .toggleStyle(BlueprintToggleStyle.onDark)

      Text(
        TimerDuration.consequence(
          endTime: liftTimeText,
          canStopEarly: !hideStopButton)
      )
      .font(.sapientiaBody(14))
      .foregroundColor(SapientiaTheme.onDark(0.6))
      .fixedSize(horizontal: false, vertical: true)

      Button("Begin") { handleConfirm() }
        .buttonStyle(BlueprintPrimaryButtonStyle.onDark)
    }
    .padding(.top, SapientiaTheme.space6)
  }

  private var liftTimeText: String {
    Self.liftFormatter.string(from: TimerDuration.liftsAt(minutes, from: Date()))
  }

  private func handleConfirm() {
    onDurationSelected(
      StrategyTimerData(
        durationInMinutes: minutes,
        hideStopButton: hideStopButton))
    dismiss()
  }
}

#Preview {
  Color.clear
    .fullScreenCover(isPresented: .constant(true)) {
      TimerDurationView(
        profileName: "Deep Work",
        onDurationSelected: { data in
          print("Selected \(data.durationInMinutes) minutes")
        }
      )
    }
}
