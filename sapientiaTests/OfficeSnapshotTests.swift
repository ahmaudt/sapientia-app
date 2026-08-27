import SwiftUI
import UIKit
import XCTest

@testable import sapientia

/// Renders the office screens to PNGs so their layout can be inspected, and
/// asserts the long texts are laid out in full rather than clipped.
///
/// This exists because the longest collects are the exact failure mode that
/// shipped once already in `b5daecb`, where a flexible sibling squeezed its
/// neighbours and SwiftUI silently collapsed `Text` to one line. Assertions
/// here compare each block's laid-out height against the height that text
/// *needs*, which is what truncation actually destroys.
final class OfficeSnapshotTests: XCTestCase {

  /// Where the PNGs land. Written on every run; ignored if the directory
  /// cannot be created, so this never fails a CI machine.
  private let outputDirectory = URL(fileURLWithPath: "/tmp/lh-shots", isDirectory: true)

  /// iPhone 17 logical points, and the narrowest device the app supports.
  private let wide = CGSize(width: 402, height: 874)
  private let narrow = CGSize(width: 320, height: 568)

  private var calendar: Calendar!
  private var sequence: OfficeSequence!

  /// A Friday, as the mockups depict.
  private let friday: Date = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
    var components = DateComponents()
    components.year = 2026
    components.month = 8
    components.day = 7
    components.hour = 12
    return calendar.date(from: components)!
  }()

  override func setUp() {
    super.setUp()
    calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
    sequence = OfficeSequence(calendar: calendar)
    try? FileManager.default.createDirectory(
      at: outputDirectory, withIntermediateDirectories: true)
  }

  override func tearDown() {
    sequence = nil
    calendar = nil
    super.tearDown()
  }

  // MARK: - Rendering

  /// Lay a view out at `width` with unbounded height and render it.
  @discardableResult
  @MainActor
  private func render<V: View>(_ view: V, width: CGFloat, named name: String) -> CGSize {
    let host = UIHostingController(rootView: view.frame(width: width).background(Color.black))
    host.view.backgroundColor = .black
    let fitting = host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
    host.view.frame = CGRect(origin: .zero, size: fitting)
    host.view.layoutIfNeeded()

    let renderer = UIGraphicsImageRenderer(size: fitting)
    let image = renderer.image { _ in
      host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
    }
    if let data = image.pngData() {
      try? data.write(to: outputDirectory.appendingPathComponent("\(name).png"))
    }
    return fitting
  }

  /// The height a string needs at a width, as the layout engine measures it.
  private func neededHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
    (text as NSString).boundingRect(
      with: CGSize(width: width, height: .greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font],
      context: nil
    ).height
  }

  // MARK: - The pages render at their full height

  @MainActor
  func testEveryPageOfEveryHourRendersAtFullWidth() {
    for hour in LittleHour.allCases {
      let pages = sequence.pages(for: hour, on: friday)
      XCTAssertFalse(pages.isEmpty, "\(hour.rawValue) produced no pages")
      for (index, page) in pages.enumerated() {
        let size = render(
          OfficePageView(page: page).padding(SapientiaTheme.space8),
          width: wide.width,
          named: "snap-\(hour.rawValue)-\(index)")
        XCTAssertGreaterThan(size.height, 0, "\(hour.rawValue) page \(index) laid out empty")
      }
    }
  }

  /// None's collect is the longest single text in the office and the one most
  /// likely to be clipped.
  @MainActor
  func testNonesCollectIsLaidOutInFullOnTheNarrowestDevice() {
    guard case .chapterAndCollect(let final) = sequence.pages(for: .nones, on: friday).last else {
      return XCTFail("no final page for None")
    }
    let collect = final.collects[0].text
    XCTAssertTrue(collect.count > 300, "expected the long collect; got \(collect.count) characters")

    render(
      OfficePageView(page: .chapterAndCollect(final)).padding(SapientiaTheme.space8),
      width: narrow.width,
      named: "snap-none-final-narrow")

    // Measure the collect *block itself*, not the whole page. An earlier
    // version of this test compared the page height against one block's and
    // passed while the collect was visibly truncated to
    // "who livest and reignest…" — the page is tall for other reasons.
    let inner = narrow.width - SapientiaTheme.space8 * 2
    let section = OfficeFinalSection(kind: .collect, title: "The Collect", body: collect)
    let rendered = render(
      section.view.frame(width: inner), width: inner, named: "snap-none-collect-only")

    // Barlow Condensed is narrower than the system font at the same size, so
    // the system measurement is a conservative floor: real layout should need
    // at least a large fraction of it. Truncation collapses the block far
    // below this.
    let floorHeight =
      neededHeight(collect, font: UIFont.systemFont(ofSize: 23), width: inner) * 0.6
    XCTAssertGreaterThan(
      rendered.height, floorHeight,
      "None's collect is being clipped: laid out \(rendered.height)pt, needs at least \(floorHeight)pt"
    )
  }

  /// Screens 25 and 29 in full. Rendered rather than driven through the UI:
  /// the result is deterministic and does not depend on tap coordinates.
  @MainActor
  func testTheHoursAndRemindersScreensRender() {
    let store = KeptHoursStore(calendar: calendar)
    store.reset()
    defer { store.reset() }
    // Screen 25's example state: Terce prayed at 9:04.
    var components = DateComponents()
    components.year = 2026
    components.month = 8
    components.day = 7
    components.hour = 9
    components.minute = 4
    store.record(.terce, on: friday, at: calendar.date(from: components)!)

    let hours = render(
      TheHoursView(day: friday, store: store, calendar: calendar)
        .frame(width: wide.width, height: wide.height),
      width: wide.width,
      named: "snap-25-the-hours")
    XCTAssertGreaterThan(hours.height, 0)

    let reminders = render(
      PrayerRemindersView().frame(width: wide.width, height: wide.height),
      width: wide.width,
      named: "snap-29-reminders")
    XCTAssertGreaterThan(reminders.height, 0)
  }

  @MainActor
  func testTheAngelusRendersAtFullHeight() {
    guard case .devotion(let devotion, let note) = sequence.pages(for: .sext, on: friday).first
    else {
      return XCTFail("Sext should open with a devotion")
    }
    let size = render(
      OfficePageView(page: .devotion(devotion, note: note)).padding(SapientiaTheme.space8),
      width: wide.width,
      named: "snap-angelus")

    // Fourteen versicles plus a collect cannot fit in one screen height; if it
    // measures that short, lines are being dropped.
    XCTAssertGreaterThan(size.height, wide.height, "the Angelus laid out too short to be complete")
  }
}
