import XCTest

@testable import sapientia

final class DomainValidationTests: XCTestCase {

  func testValidDomains() {
    XCTAssertTrue(DomainValidation.isValid("reddit.com"))
    XCTAssertTrue(DomainValidation.isValid("news.ycombinator.com"))
    XCTAssertTrue(DomainValidation.isValid("x.com"))
  }

  func testInvalidDomains() {
    XCTAssertFalse(DomainValidation.isValid(""))
    XCTAssertFalse(DomainValidation.isValid("nodot"))
    XCTAssertFalse(DomainValidation.isValid(".leadingdot.com"))
    XCTAssertFalse(DomainValidation.isValid("trailingdot.com."))
    XCTAssertFalse(DomainValidation.isValid("double..dot.com"))
  }

  func testNormalizeLowercasesAndTrims() {
    XCTAssertEqual(DomainValidation.normalize("  Reddit.COM "), "reddit.com")
  }
}
