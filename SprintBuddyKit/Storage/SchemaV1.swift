import Foundation
import SwiftData

/// Frozen copy of the models as shipped through v1.3. Never edit these: the
/// migration plan matches on-disk stores against this exact shape. Model
/// changes go in `SprintModels.swift` plus a new schema version and stage.
public enum SprintBuddySchemaV1: VersionedSchema {
    public static var versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] { [Sprint.self, Day.self, DayUpdate.self] }

    @Model public final class Sprint {
        public var id: String = ""
        public var name: String = ""
        public var focus: String = ""
        public var startISO: String = ""
        public var weeks: Int = 2
        public var createdAt: Date = Date()
        @Relationship(deleteRule: .cascade, inverse: \Day.sprint) public var days: [Day] = []

        public init() {}
    }

    @Model public final class Day {
        public var dateISO: String = ""
        public var statusRaw: String = "working"
        public var privateNote: String = ""
        @Relationship(deleteRule: .cascade, inverse: \DayUpdate.day) public var updates: [DayUpdate] = []
        public var sprint: Sprint?

        public init() {}
    }

    @Model public final class DayUpdate {
        public var id: String = UUID().uuidString
        public var typeRaw: String = "done"
        public var text: String = ""
        public var sortIndex: Int = 0
        public var day: Day?

        public init() {}
    }
}
