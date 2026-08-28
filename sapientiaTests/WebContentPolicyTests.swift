import ManagedSettings
import XCTest

@testable import sapientia

/// The web-content filter policy, and the Private Browsing hole it closes.
///
/// A tester reached a blocked site by opening a private tab. The domain had
/// been typed, so it *did* reach `webContent.blockedByFilter` — the block held
/// in a normal tab and failed in a private one.
///
/// `.specific` is the only `FilterPolicy` with no counterpart in Screen Time's
/// Web Content settings, whose levels are Unrestricted, Limit Adult Websites
/// and Only Approved Websites. A bare blocklist leaves the level effectively
/// unrestricted, and Safari only withdraws Private Browsing at a *restricted*
/// level. `.auto` is the lowest such level, so the office's blocks now go
/// through it.
final class WebContentPolicyTests: XCTestCase {

  private let blocked: Set<WebDomain> = [
    WebDomain(domain: "reddit.com"), WebDomain(domain: "x.com"),
  ]

  // MARK: - The regression

  /// The exact reported case: domains listed, adult filtering left off.
  func testBlockingDomainsUsesAutoSoPrivateBrowsingIsUnavailable() {
    let policy = WebContentPolicy.filterPolicy(
      allowOnlyDomains: false, blocksAdultContent: false, domains: blocked)

    XCTAssertEqual(policy, .auto(blocked))
  }

  /// Guards the fix directly: `.specific` must never be produced, whatever the
  /// combination of flags, because Private Browsing survives it.
  func testSpecificIsNeverUsed() {
    for allowOnly in [true, false] {
      for adult in [true, false] {
        for domains in [blocked, []] as [Set<WebDomain>] {
          let policy = WebContentPolicy.filterPolicy(
            allowOnlyDomains: allowOnly, blocksAdultContent: adult, domains: domains)
          if case .specific = policy {
            XCTFail(
              "specific leaves Private Browsing available "
                + "(allowOnly: \(allowOnly), adult: \(adult), domains: \(domains.count))")
          }
        }
      }
    }
  }

  // MARK: - The other modes are unchanged

  func testAllowOnlyModeStillBlocksEverythingElse() {
    let policy = WebContentPolicy.filterPolicy(
      allowOnlyDomains: true, blocksAdultContent: false, domains: blocked)
    XCTAssertEqual(policy, .all(except: blocked))
  }

  /// Allow-only wins even if adult blocking is somehow also set: it is already
  /// the stricter level, and the form clears the adult toggle when it is on.
  func testAllowOnlyModeTakesPrecedenceOverAdultBlocking() {
    let policy = WebContentPolicy.filterPolicy(
      allowOnlyDomains: true, blocksAdultContent: true, domains: blocked)
    XCTAssertEqual(policy, .all(except: blocked))
  }

  func testAdultBlockingWithNoDomainsStillFilters() {
    let policy = WebContentPolicy.filterPolicy(
      allowOnlyDomains: false, blocksAdultContent: true, domains: [])
    XCTAssertEqual(policy, .auto([]))
  }

  func testAdultBlockingCarriesTheDomainsToo() {
    let policy = WebContentPolicy.filterPolicy(
      allowOnlyDomains: false, blocksAdultContent: true, domains: blocked)
    XCTAssertEqual(policy, .auto(blocked))
  }

  // MARK: - Nothing to enforce

  /// A profile that blocks no websites must not restrict web content at all —
  /// escalating here would filter the whole internet for someone who only
  /// blocked apps.
  func testNoDomainsAndNoAdultBlockingLeavesWebContentAlone() {
    let policy = WebContentPolicy.filterPolicy(
      allowOnlyDomains: false, blocksAdultContent: false, domains: [])
    XCTAssertNil(policy)
  }

  // MARK: - Apple's ceiling

  /// Apple caps each policy at 50 domains, which is why
  /// `DomainValidation.maxDomains` is 50. If that constant ever rises past the
  /// cap the excess would be dropped silently by the system.
  func testTheDomainLimitMatchesApplesCeiling() {
    XCTAssertLessThanOrEqual(DomainValidation.maxDomains, WebContentPolicy.appleDomainLimit)
  }
}
