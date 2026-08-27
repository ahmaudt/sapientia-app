import SwiftUI

/// The observance grid on screen 25: seven columns of three cells — one row
/// per hour, Terce, Sext, None — over a blueprint card.
struct HoursWeekGrid: View {
  let week: KeptHoursWeek

  private let columns = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

  var body: some View {
    BlueprintCard(padding: SapientiaTheme.space4) {
      VStack(alignment: .leading, spacing: 0) {
        Text("This week")
          .font(.sapientiaHeading(12))
          .kerning(1.2)
          .textCase(.uppercase)
          .foregroundColor(SapientiaTheme.accent)

        HStack(spacing: 3) {
          ForEach(Array(week.days.enumerated()), id: \.offset) { _, day in
            VStack(spacing: 3) {
              ForEach(Array(day.cells.enumerated()), id: \.offset) { _, cell in
                cellView(cell)
              }
            }
          }
        }
        .padding(.top, SapientiaTheme.space3)

        HStack(spacing: 3) {
          ForEach(columns, id: \.self) { label in
            Text(label)
              .font(.sapientiaHeading(11))
              .kerning(1.1)
              .textCase(.uppercase)
              .foregroundColor(SapientiaTheme.text.opacity(0.45))
              .frame(maxWidth: .infinity)
          }
        }
        .padding(.top, SapientiaTheme.space2)

        Text("Rows are Terce, Sext, None. \(week.caption)")
          .font(.sapientiaBody(13))
          .lineSpacing(3)
          .foregroundColor(SapientiaTheme.text.opacity(0.55))
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, SapientiaTheme.space3)
      }
    }
  }

  @ViewBuilder
  private func cellView(_ cell: KeptHourCell) -> some View {
    switch cell {
    case .kept:
      Rectangle()
        .fill(SapientiaTheme.accent)
        .frame(height: 12)
    case .notKept:
      Rectangle()
        .fill(Color.clear)
        .frame(height: 12)
        .border(SapientiaTheme.divider, width: 1)
    case .notRequired:
      // Nothing was owed. Fainter than an unkept cell so a quiet Sunday or a
      // switched-off hour never reads as a failure.
      Rectangle()
        .fill(Color.clear)
        .frame(height: 12)
        .border(SapientiaTheme.divider.opacity(0.35), width: 1)
    }
  }
}
