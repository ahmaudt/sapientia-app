import ManagedSettings

/// Chooses the Screen Time web-content policy for a profile.
///
/// Lives here rather than in its own file because `AppBlockerUtil` is compiled
/// into the widget, device-monitor and shield-action extensions as well as the
/// app; a separate file would have to be added to each target's membership
/// exceptions to stay in scope.
enum WebContentPolicy {

  /// Apple blocks at most 50 domains per policy and allows at most 50
  /// exceptions. `DomainValidation.maxDomains` is held at this ceiling; past
  /// it the system drops the excess without reporting anything.
  static let appleDomainLimit = 50

  /// - Parameters:
  ///   - allowOnlyDomains: the profile permits only its listed domains.
  ///   - blocksAdultContent: the profile's "Block Adult Websites" switch.
  ///   - domains: the domains the profile blocks (or permits, in allow-only).
  /// - Returns: the policy to install, or `nil` to leave web content alone.
  static func filterPolicy(
    allowOnlyDomains: Bool,
    blocksAdultContent: Bool,
    domains: Set<WebDomain>
  ) -> WebContentSettings.FilterPolicy? {
    // Allow-only is already the strictest level: everything but the list.
    if allowOnlyDomains {
      return .all(except: domains)
    }

    // Anything to enforce goes through `.auto`, never `.specific`.
    //
    // Screen Time's Web Content has three levels — Unrestricted, Limit Adult
    // Websites, Only Approved Websites — and Safari withdraws Private
    // Browsing only at a restricted one. `.specific` is a bare blocklist with
    // no corresponding level, so the restriction reads as unrestricted and
    // private tabs slip past it: a tester reached a listed site that way.
    // `.auto` is the lowest restricted level, so blocks now go through it.
    //
    // The cost is real and deliberate: `.auto` also applies Apple's
    // adult-content filter, which a profile with "Block Adult Websites" off
    // did not ask for. There is no restricted level without it — that filter
    // *is* what "Limit Adult Websites" means — so the alternatives were to
    // invert to an allow-list or leave the hole open.
    if blocksAdultContent || !domains.isEmpty {
      return .auto(domains)
    }

    // Blocks no websites at all: leave web content untouched. Escalating here
    // would filter the whole internet for someone who only blocked apps.
    return nil
  }
}

class AppBlockerUtil {
  let store = ManagedSettingsStore(
    named: ManagedSettingsStore.Name("sapientiaAppRestrictions")
  )

  func activateRestrictions(for profile: SharedData.ProfileSnapshot) {
    let selection = profile.selectedActivity
    applyRestrictions(
      for: profile,
      applicationTokens: selection.applicationTokens,
      categoryTokens: selection.categoryTokens,
      categoryApplicationExceptions: []
    )
  }

  func activateSoftUnblockRestrictions(
    for profile: SharedData.ProfileSnapshot,
    unblockedApplicationTokens: Set<ApplicationToken>,
    unblockedCategoryTokens: Set<ActivityCategoryToken>
  ) {
    let selection = profile.selectedActivity
    let applicationTokens: Set<ApplicationToken>
    let categoryTokens: Set<ActivityCategoryToken>

    if profile.enableAllowMode {
      applicationTokens = selection.applicationTokens.union(unblockedApplicationTokens)
      categoryTokens = selection.categoryTokens
    } else {
      applicationTokens = selection.applicationTokens.subtracting(unblockedApplicationTokens)
      categoryTokens = selection.categoryTokens.subtracting(unblockedCategoryTokens)
    }

    applyRestrictions(
      for: profile,
      applicationTokens: applicationTokens,
      categoryTokens: categoryTokens,
      categoryApplicationExceptions: unblockedApplicationTokens
    )
  }

  private func applyRestrictions(
    for profile: SharedData.ProfileSnapshot,
    applicationTokens: Set<ApplicationToken>,
    categoryTokens: Set<ActivityCategoryToken>,
    categoryApplicationExceptions: Set<ApplicationToken>
  ) {
    print("Starting restrictions...")

    let selection = profile.selectedActivity
    let allowOnlyApps = profile.enableAllowMode
    let allowOnlyDomains = profile.enableAllowModeDomains
    let strict = profile.enableStrictMode
    let enableSafariBlocking = profile.enableSafariBlocking
    let enableAdultContentBlocking = profile.enableAdultContentBlocking == true
    let domains = getWebDomains(from: profile)

    let webTokens = selection.webDomainTokens

    if allowOnlyApps {
      store.shield.applicationCategories = .all(except: applicationTokens)

      if enableSafariBlocking {
        store.shield.webDomainCategories = .all(except: webTokens)
      }

    } else {
      store.shield.applications = applicationTokens.isEmpty ? nil : applicationTokens
      store.shield.applicationCategories =
        categoryTokens.isEmpty
        ? nil
        : .specific(
          categoryTokens,
          except: categoryApplicationExceptions
        )

      if enableSafariBlocking {
        store.shield.webDomainCategories = .specific(selection.categoryTokens)
        store.shield.webDomains = webTokens
      }
    }

    store.webContent.blockedByFilter = WebContentPolicy.filterPolicy(
      allowOnlyDomains: allowOnlyDomains,
      blocksAdultContent: enableAdultContentBlocking,
      domains: domains
    )

    store.application.denyAppRemoval = strict
    store.application.denyAppInstallation = profile.enableBlockAppInstallation
  }

  func deactivateRestrictions() {
    print("Stoping restrictions...")

    store.shield.applications = nil
    store.shield.applicationCategories = nil
    store.shield.webDomains = nil
    store.shield.webDomainCategories = nil

    store.application.denyAppRemoval = false
    store.application.denyAppInstallation = false

    store.webContent.blockedByFilter = nil

    store.clearAllSettings()
  }

  func deactivateRestrictionsForBreak(for profile: SharedData.ProfileSnapshot) {
    print("Stopping restrictions for break (strict mode: \(profile.enableStrictMode))...")

    store.shield.applications = nil
    store.shield.applicationCategories = nil
    store.shield.webDomains = nil
    store.shield.webDomainCategories = nil

    store.webContent.blockedByFilter = nil
    store.application.denyAppInstallation = false

    if !profile.enableStrictMode {
      store.application.denyAppRemoval = false
    }
  }

  func getWebDomains(from profile: SharedData.ProfileSnapshot) -> Set<WebDomain> {
    if let domains = profile.domains {
      return Set(domains.map { WebDomain(domain: $0) })
    }

    return []
  }
}
