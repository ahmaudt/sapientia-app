import XCTest

@testable import sapientia

final class IntroFlowTests: XCTestCase {

  func testBeginRequestsAuthorization() {
    var requested = 0
    let model = IntroViewModel(onRequestAuthorization: { requested += 1 })
    model.begin()
    XCTAssertEqual(requested, 1)
  }

  func testAlreadyHaveTagAlsoRequestsAuthorization() {
    // Screen Time approval is required regardless of how the user enters;
    // "I already have a tag" is a shortcut past the pitch, not past the
    // permission.
    var requested = 0
    let model = IntroViewModel(onRequestAuthorization: { requested += 1 })
    model.alreadyHaveTag()
    XCTAssertEqual(requested, 1)
  }

  func testOnboardingStepsMatchDesign() {
    XCTAssertEqual(IntroViewModel.steps.count, 3)
    XCTAssertEqual(IntroViewModel.steps[0].title, "Choose what to set aside")
    XCTAssertEqual(IntroViewModel.steps[1].title, "Pair a tag or a code")
    XCTAssertEqual(IntroViewModel.steps[2].title, "Meet the hour with a prayer")
  }
}
