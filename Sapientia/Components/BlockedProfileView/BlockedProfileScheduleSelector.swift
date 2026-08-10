import SwiftUI

/// The "Schedule" row in the rule editor (flow 07): a blueprint row showing
/// the current schedule with an Edit action opening the Schedule stage.
struct BlockedProfileScheduleSelector: View {
  var schedule: BlockedProfileSchedule
  var buttonAction: () -> Void
  var disabled: Bool = false
  var disabledText: String?

  private var daysCount: Int { schedule.days.count }

  var body: some View {
    BlueprintListRow(
      title: "Schedule",
      caption: daysCount == 0 ? "Off" : schedule.summaryText,
      onTap: disabled ? nil : buttonAction
    ) {
      if !disabled {
        BlueprintRowAction(label: daysCount == 0 ? "Set" : "Edit", action: buttonAction)
      }
    }

    if let disabledText, disabled {
      Text(disabledText)
        .font(.sapientiaBody(13))
        .foregroundColor(SapientiaTheme.accent700)
        .padding(.top, 4)
    }
  }
}

#Preview {
  VStack(spacing: 0) {
    BlockedProfileScheduleSelector(
      schedule: .init(
        days: [.monday, .wednesday, .friday], startHour: 9, startMinute: 0,
        endHour: 17, endMinute: 0, updatedAt: Date()),
      buttonAction: {}
    )
  }
  .padding()
  .background(SapientiaTheme.background)
}
