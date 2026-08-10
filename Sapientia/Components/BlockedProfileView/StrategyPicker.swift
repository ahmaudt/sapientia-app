import SwiftUI

/// Screen 11 — How it ends. Grouped radio rows: each ending method shows its
/// name and description inline, selected by a radio dot (per flow 11). The
/// old two-step details sheet is gone; the description moved into the row.
struct StrategyPicker: View {
  let strategies: [BlockingStrategy]
  @Binding var selectedStrategy: BlockingStrategy?
  @Binding var isPresented: Bool

  private var sections: [StrategyPickerSection] {
    BlockingStrategyPickerCategory.allCases.compactMap { category in
      let categoryStrategies = strategies.filter { $0.pickerCategory == category }
      guard !categoryStrategies.isEmpty else { return nil }
      return StrategyPickerSection(
        title: category.title,
        description: category.description,
        strategies: categoryStrategies
      )
    }
  }

  var body: some View {
    BlueprintStage(
      title: "How it ends",
      leadingLabel: "Cancel",
      leadingAction: { isPresented = false },
      trailingLabel: "Done",
      trailingAction: { isPresented = false }
    ) {
      VStack(alignment: .leading, spacing: SapientiaTheme.space6) {
        ForEach(sections) { section in
          VStack(alignment: .leading, spacing: 0) {
            SectionHeaderLabel(title: section.title)
            ForEach(section.strategies.indices, id: \.self) { index in
              let strategy = section.strategies[index]
              SapientiaRadioRow(
                title: strategy.name,
                subtitle: strategy.description,
                isSelected: selectedStrategy?.getIdentifier() == strategy.getIdentifier()
              ) {
                selectedStrategy = strategy
                isPresented = false
              }
              Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
            }
          }
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var selectedStrategy: BlockingStrategy? = NFCBlockingStrategy()
  @Previewable @State var isPresented = true

  StrategyPicker(
    strategies: StrategyManager.availableStrategies,
    selectedStrategy: $selectedStrategy,
    isPresented: $isPresented
  )
}
