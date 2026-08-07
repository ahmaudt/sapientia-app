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
      dayName: "Friday after Trinity IX",
      season: .trinitytide,
      commemorationText: "Commemoration of S. Sixtus II, Bishop & Martyr",
      collect: Collect(
        title: "Trinity IX",
        text:
          "Grant to us, Lord, we beseech thee, the spirit to think and do always such things as are right; that we, who cannot do any thing that is good without thee, may by thee be enabled to live according to thy will; through Jesus Christ our Lord. Amen."
      )
    )
  )
  .padding()
}
