import SwiftUI

/// Screen 25 — the day's three hours, with the week's observance beneath.
struct TheHoursView: View {
  var day: Date = Date()
  var store: KeptHoursStore = KeptHoursStore()
  var calendar: Calendar = .current
  var liturgy: OrdinariateCalendar = OrdinariateCalendar()

  @Environment(\.dismiss) private var dismiss
  @State private var hourToPray: LittleHour?
  @State private var showReminders = false
  /// Bumped after an Amen so the rows and grid re-read the store.
  @State private var refreshToken = 0

  var body: some View {
    BlueprintStage(
      title: "The Hours",
      leadingLabel: "Home",
      leadingAction: { dismiss() },
      trailingLabel: "Remind",
      trailingAction: { showReminders = true }
    ) {
      // A minute is fine-grained enough for hours that turn over on the hour,
      // and keeps the screen live if it is left open as one arrives.
      TimelineView(.periodic(from: .now, by: 60)) { context in
        content(now: context.date)
      }
      .id(refreshToken)
    }
    .fullScreenCover(item: $hourToPray) { hour in
      OfficeReaderView(
        hour: hour,
        day: day,
        completion: OfficeCompletion(store: store),
        liturgy: liturgy,
        calendar: calendar
      )
      .onDisappear { refreshToken += 1 }
    }
    .fullScreenCover(isPresented: $showReminders) {
      PrayerRemindersView()
        .onDisappear { refreshToken += 1 }
    }
  }

  private func content(now: Date) -> some View {
    VStack(alignment: .leading, spacing: SapientiaTheme.space6) {
      header

      VStack(alignment: .leading, spacing: 0) {
        SectionHeaderLabel(title: "The Little Hours")
        ForEach(rows(now: now), id: \.hour) { row in
          LittleHourRowView(row: row) { hourToPray = row.hour }
        }
      }

      HoursWeekGrid(
        week: KeptHoursAggregator.aggregate(
          weekOf: day, store: store, calendar: calendar))

      Text(
        "The hours are not tied to the clock. A reminder names the hour; the office waits until you come to it."
      )
      .font(.sapientiaBody(13))
      .lineSpacing(3)
      .foregroundColor(SapientiaTheme.text.opacity(0.55))
      .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: SapientiaTheme.space1) {
      Text(dateHeading)
        .sapientiaKicker()
      Text(liturgy.day(for: day).dayName)
        .font(.sapientiaHeading(30))
        .foregroundColor(SapientiaTheme.text)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var dateHeading: String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = "EEEE · d MMMM"
    return formatter.string(from: day)
  }

  private func rows(now: Date) -> [LittleHourRow] {
    LittleHoursRowModel.rows(on: day, now: now, store: store, calendar: calendar)
  }
}

// MARK: - One row

struct LittleHourRowView: View {
  let row: LittleHourRow
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(alignment: .center, spacing: SapientiaTheme.space4) {
        VStack(alignment: .leading, spacing: 2) {
          Text(row.title)
            .font(.sapientiaHeading(20))
            .foregroundColor(SapientiaTheme.text)
          Text(row.caption)
            .font(.sapientiaBody(13))
            .foregroundColor(
              row.state == .current
                ? SapientiaTheme.accent700
                : SapientiaTheme.text.opacity(0.55))
        }
        Spacer(minLength: SapientiaTheme.space3)
        trailing
      }
      .padding(.vertical, SapientiaTheme.space4)
      .padding(.horizontal, row.state == .current ? SapientiaTheme.space4 : 0)
      .background(row.state == .current ? SapientiaTheme.accent100 : Color.clear)
      // The current row bleeds to the card edge, as screen 25 draws it.
      .padding(.horizontal, row.state == .current ? -SapientiaTheme.space4 : 0)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .overlay(alignment: .bottom) {
      Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
    }
  }

  @ViewBuilder
  private var trailing: some View {
    switch row.state {
    case .kept:
      Text(row.trailingLabel)
        .font(.sapientiaBody(11))
        .foregroundColor(SapientiaTheme.accent800)
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(SapientiaTheme.accent100)
    case .current:
      Text("Pray")
        .font(.sapientiaHeading(14))
        .kerning(1.1)
        .textCase(.uppercase)
        .foregroundColor(SapientiaTheme.accent700)
        .padding(.vertical, SapientiaTheme.space2)
        .padding(.horizontal, SapientiaTheme.space3 * 1.2)
        .border(SapientiaTheme.divider, width: 1)
    case .upcoming:
      Text(row.trailingLabel)
        .font(.sapientiaBody(15))
        .foregroundColor(SapientiaTheme.text.opacity(0.45))
    case .disabled:
      Text(row.trailingLabel)
        .font(.sapientiaBody(15))
        .foregroundColor(SapientiaTheme.text.opacity(0.28))
    }
  }
}

// Lets `LittleHour` drive `.fullScreenCover(item:)`.
extension LittleHour: Identifiable {
  var id: String { rawValue }
}

#Preview {
  TheHoursView()
}
