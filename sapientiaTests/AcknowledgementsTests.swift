import XCTest

@testable import sapientia

/// The MIT and OFL licenses require their notices to travel with the binary.
/// These tests guard that the acknowledgements screen reproduces them.
final class AcknowledgementsTests: XCTestCase {

  private func credit(_ name: String) -> Acknowledgement? {
    Acknowledgements.all.first { $0.name == name }
  }

  func testFoqosMITNoticeIsReproducedInFull() {
    guard let foqos = credit("Foqos") else {
      return XCTFail("Foqos acknowledgement missing")
    }
    XCTAssertEqual(foqos.licenseName, "MIT License")
    let text = foqos.licenseText ?? ""
    XCTAssertTrue(
      text.contains("Copyright (c) 2024 Ali Waseem"),
      "MIT requires the original copyright line to be preserved")
    XCTAssertTrue(
      text.contains("Permission is hereby granted"),
      "MIT permission grant must be present")
    XCTAssertTrue(
      text.contains("WITHOUT WARRANTY OF ANY KIND"),
      "MIT warranty disclaimer must be present")
  }

  func testFontsOFLNoticeIsPresent() {
    guard let barlow = credit("Barlow & Barlow Condensed") else {
      return XCTFail("Barlow acknowledgement missing")
    }
    XCTAssertEqual(barlow.licenseName, "SIL Open Font License 1.1")
    XCTAssertTrue((barlow.licenseText ?? "").contains("SIL Open Font License"))
  }

  func testEveryCreditLinksToItsSource() {
    XCTAssertFalse(Acknowledgements.all.isEmpty)
    for credit in Acknowledgements.all {
      XCTAssertNotNil(credit.url, "\(credit.name) should link to its source")
      XCTAssertNotNil(URL(string: credit.url ?? ""), "\(credit.name) url must be valid")
    }
  }
}
