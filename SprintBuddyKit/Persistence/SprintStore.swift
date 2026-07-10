import Foundation
import SwiftData

public struct SprintStore {
    /// Save the context, logging (rather than silently swallowing) any failure.
    public static func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            NSLog("[SprintBuddy] ModelContext save failed: \(error)")
        }
    }

    @discardableResult
    public static func createSprint(name: String, focus: String, startISO: String, weeks: Int,
                                    in context: ModelContext) -> Sprint {
        let dto = SprintDTO(id: "s-\(UUID().uuidString)",
                            name: name, description: focus, start: startISO, weeks: weeks,
                            days: SprintMath.generateDays(start: startISO, weeks: weeks))
        let sprint = Sprint.from(dto)
        context.insert(sprint)
        return sprint
    }

    public static func replaceAll(with dtos: [SprintDTO], in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Sprint>())) ?? []
        existing.forEach { context.delete($0) }
        dtos.forEach { context.insert(Sprint.from($0)) }
    }

    public static func exportData(_ sprints: [Sprint]) throws -> Data {
        // Defensive: never write duplicate sprint ids into the export file, so a
        // corrupted/duplicated store can't produce an inflated import count.
        var seen = Set<String>()
        let unique = sprints.compactMap { sprint -> SprintDTO? in
            guard seen.insert(sprint.id).inserted else { return nil }
            return sprint.toDTO()
        }
        return try SprintBuddyCodec.encode(unique)
    }
}
