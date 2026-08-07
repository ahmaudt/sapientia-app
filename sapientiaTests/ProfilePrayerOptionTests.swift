import FamilyControls
import SwiftData
import XCTest

@testable import sapientia

final class ProfilePrayerOptionTests: XCTestCase {

  private func makeContext() throws -> ModelContext {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: BlockedProfileSession.self,
      BlockedProfiles.self,
      configurations: configuration
    )
    return ModelContext(container)
  }

  func testPrayBeforeUnblockingDefaultsToFalse() throws {
    let context = try makeContext()
    let profile = try BlockedProfiles.createProfile(in: context, name: "Deep Work")
    XCTAssertNil(profile.prayBeforeUnblocking)
    XCTAssertFalse(profile.prayBeforeUnblockingResolved)
  }

  func testPrayBeforeUnblockingPersistsThroughUpdate() throws {
    let context = try makeContext()
    let profile = try BlockedProfiles.createProfile(
      in: context, name: "Deep Work", prayBeforeUnblocking: true)
    XCTAssertTrue(profile.prayBeforeUnblockingResolved)

    let updated = try BlockedProfiles.updateProfile(
      profile, in: context, prayBeforeUnblocking: false)
    XCTAssertFalse(updated.prayBeforeUnblockingResolved)
  }

  func testSnapshotCarriesPrayBeforeUnblocking() throws {
    let context = try makeContext()
    let profile = try BlockedProfiles.createProfile(
      in: context, name: "Deep Work", prayBeforeUnblocking: true)
    let snapshot = BlockedProfiles.getSnapshot(for: profile)
    XCTAssertEqual(snapshot.prayBeforeUnblocking, true)
  }

  func testSnapshotDecodingToleratesMissingField() throws {
    // Snapshots persisted by older app versions have no prayBeforeUnblocking
    // key: encode a current snapshot, strip the key, decode.
    let context = try makeContext()
    let profile = try BlockedProfiles.createProfile(
      in: context, name: "Old", prayBeforeUnblocking: true)
    let snapshot = BlockedProfiles.getSnapshot(for: profile)

    let data = try JSONEncoder().encode(snapshot)
    var json =
      try JSONSerialization.jsonObject(with: data) as! [String: Any]
    json.removeValue(forKey: "prayBeforeUnblocking")
    let legacyData = try JSONSerialization.data(withJSONObject: json)

    let decoded = try JSONDecoder().decode(
      SharedData.ProfileSnapshot.self, from: legacyData)
    XCTAssertNil(decoded.prayBeforeUnblocking)
  }
}
