import SwiftUI

/// Home screen card: the day in the Ordinariate kalendar with its Collect.
struct FeastCard: View {
  let day: LiturgicalDay
  @State private var isCollectExpanded = false

  var body: some View {
    BlueprintCard(padding: 0) {
      VStack(alignment: .leading, spacing: 0) {
        Text("Ordinariate calendar")
          .font(.sapientiaHeading(12))
          .kerning(1.2)
          .textCase(.uppercase)
          .foregroundColor(SapientiaTheme.accent)

        Text(day.dayName)
          .font(.sapientiaHeading(30))
          .foregroundColor(SapientiaTheme.text)
          .padding(.top, SapientiaTheme.space2)

        if let commemoration = day.commemorationText {
          Text(commemoration)
            .font(.sapientiaBody(15))
            .foregroundColor(SapientiaTheme.text.opacity(0.62))
            .padding(.top, SapientiaTheme.space1)
        }

        Rectangle()
          .fill(SapientiaTheme.divider)
          .frame(height: 1)
          .padding(.vertical, SapientiaTheme.space4)

        Text(day.collect.text)
          .font(.sapientiaBody(15))
          .lineSpacing(4)
          .foregroundColor(SapientiaTheme.text)
          .lineLimit(isCollectExpanded ? nil : 2)

        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            isCollectExpanded.toggle()
          }
        } label: {
          Text(isCollectExpanded ? "Fold the Collect" : "Read the Collect")
            .font(.sapientiaHeading(15))
            .kerning(1.2)
            .textCase(.uppercase)
            .foregroundColor(SapientiaTheme.accent700)
        }
        .buttonStyle(.plain)
        .padding(.top, SapientiaTheme.space3)
      }
      .padding(.vertical, SapientiaTheme.space6)
      .padding(.horizontal, SapientiaTheme.space4)
    }
  }
}

#Preview {
  FeastCard(
    day: LiturgicalDay(
      dayName: "Saturday after Trinity IX",
      season: .trinitytide,
      commemorationText: "The memorial of S. Dominic, Priest",
      collect: Collect(
        title: "S. Dominic, Priest",
        text:
          "O God, who hast vouchsafed to enlighten thy Church with the merits and teaching of blessed Dominic thy Confessor: grant, we pray thee; that by his intercession we may fail not of thy succour in all things temporal, and continually prosper in all spiritual advancement. Through Jesus Christ thy Son our Lord. Amen."
      )
    )
  )
  .padding()
}
