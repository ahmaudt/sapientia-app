import SwiftUI

// Home's "The Little Hours" section: the day's three hours under the feast
// card, with the office owed now made actionable in one tap.

enum LittleHoursSectionModel {

  /// Delegates to `LittleHoursRowModel` rather than deriving state again, so
  /// Home and The Hours screen can never disagree about which hour is due.
  static func rows(
    on day: Date,
    now: Date,
    store: KeptHoursStore,
    calendar: Calendar = .current
  ) -> [LittleHourRow] {
    LittleHoursRowModel.rows(on: day, now: now, store: store, calendar: calendar)
  }

  /// The line beneath the section header: how the day stands, and what is
  /// owed next.
  static func summary(
    on day: Date,
    now: Date,
    store: KeptHoursStore,
    calendar: Calendar = .current
  ) -> String {
    let all = rows(on: day, now: now, store: store, calendar: calendar)
    let enabled = all.filter { $0.state != .disabled }
    guard !enabled.isEmpty else { return "No hours are set." }

    let kept = enabled.filter { $0.state == .kept }

    if kept.count == enabled.count {
      switch enabled.count {
      case 1: return "The hour is kept."
      case 2: return "Both hours kept."
      default: return "All \(spelled(enabled.count)) hours kept."
      }
    }

    let progress =
      kept.isEmpty
      ? "None kept yet"
      : "\(spelled(kept.count, capitalized: true)) of \(spelled(enabled.count)) kept"

    // The office owed now, else the next one to come.
    if let current = enabled.first(where: { $0.state == .current }) {
      return "\(progress) · \(shortName(current)) now"
    }
    if let next = enabled.first(where: { $0.state == .upcoming }) {
      return "\(progress) · \(shortName(next)) at \(next.trailingLabel)"
    }
    return progress
  }

  /// "Midmorning — Terce" → "Terce".
  private static func shortName(_ row: LittleHourRow) -> String {
    row.title.components(separatedBy: " — ").last ?? row.title
  }

  private static func spelled(_ value: Int, capitalized: Bool = false) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    formatter.locale = Locale(identifier: "en_US")
    let words = formatter.string(from: NSNumber(value: value)) ?? String(value)
    guard capitalized, let first = words.first else { return words }
    return first.uppercased() + words.dropFirst()
  }
}

struct LittleHoursSection: View {
  var day: Date = Date()
  var store: KeptHoursStore = KeptHoursStore()
  var calendar: Calendar = .current
  let onOpenHours: () -> Void
  let onPrayHour: (LittleHour) -> Void

  var body: some View {
    // Home is the screen most likely to be open when an hour arrives.
    TimelineView(.periodic(from: .now, by: 60)) { context in
      let rows = LittleHoursSectionModel.rows(
        on: day, now: context.date, store: store, calendar: calendar)

      VStack(alignment: .leading, spacing: 0) {
        header

        Text(
          LittleHoursSectionModel.summary(
            on: day, now: context.date, store: store, calendar: calendar)
        )
        .font(.sapientiaBody(13))
        .foregroundColor(SapientiaTheme.text.opacity(0.55))
        .padding(.top, SapientiaTheme.space3)

        ForEach(rows, id: \.hour) { row in
          compactRow(row)
        }
      }
    }
  }

  private var header: some View {
    HStack(alignment: .firstTextBaseline) {
      Text("The Little Hours")
        .sapientiaKicker()
      Spacer()
      Button(action: onOpenHours) {
        Text("All hours")
          .font(.sapientiaHeading(13))
          .kerning(1.0)
          .textCase(.uppercase)
          .foregroundColor(SapientiaTheme.accent700)
      }
      .buttonStyle(.plain)
    }
    .padding(.bottom, SapientiaTheme.space3)
    .overlay(alignment: .bottom) {
      Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
    }
  }

  private func compactRow(_ row: LittleHourRow) -> some View {
    Button {
      onPrayHour(row.hour)
    } label: {
      HStack(alignment: .center, spacing: SapientiaTheme.space3) {
        Text(row.title)
          .font(.sapientiaBody(17))
          .foregroundColor(
            row.state == .disabled
              ? SapientiaTheme.text.opacity(0.45)
              : SapientiaTheme.text)
        Spacer(minLength: SapientiaTheme.space3)
        trailing(row)
      }
      .padding(.vertical, SapientiaTheme.space3)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .overlay(alignment: .bottom) {
      Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
    }
  }

  @ViewBuilder
  private func trailing(_ row: LittleHourRow) -> some View {
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
        .font(.sapientiaHeading(13))
        .kerning(1.1)
        .textCase(.uppercase)
        .foregroundColor(SapientiaTheme.accent700)
        .padding(.vertical, 4)
        .padding(.horizontal, SapientiaTheme.space3)
        .border(SapientiaTheme.accent, width: 1)
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
