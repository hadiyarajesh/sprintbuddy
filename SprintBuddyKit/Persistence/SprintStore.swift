import Foundation
import SwiftData

public struct SprintStore {
    /// Save the context, logging (rather than silently swallowing) any failure,
    /// and signal the other process so its UI picks up the change. No
    /// `hasChanges` guard: SwiftData's autosave may have already persisted the
    /// mutation, and the signal must still go out.
    public static func save(_ context: ModelContext) {
        do {
            try context.save()
            DataSync.postDidSave()
        } catch {
            NSLog("[SprintBuddy] ModelContext save failed: \(error)")
        }
    }

    @discardableResult
    public static func createSprint(name: String, focus: String, startISO: String, weeks: Int,
                                    saturdayIsWorkingDay: Bool = false,
                                    in context: ModelContext) -> Sprint {
        let dto = SprintDTO(id: "s-\(UUID().uuidString)",
                            name: name, description: focus, start: startISO, weeks: weeks,
                            days: SprintMath.generateDays(start: startISO, weeks: weeks,
                                                          saturdayIsWorkingDay: saturdayIsWorkingDay))
        let sprint = Sprint.from(dto)
        context.insert(sprint)
        return sprint
    }

    /// Applies edited sprint details. Re-dating keeps every day still inside
    /// the new range untouched (status, updates, note), adds fresh days for
    /// the new dates, and deletes days that fall outside it.
    public static func updateSprint(_ sprint: Sprint, name: String, focus: String, startISO: String, weeks: Int,
                                    saturdayIsWorkingDay: Bool = false, today: String,
                                    in context: ModelContext) {
        sprint.name = name
        sprint.focus = focus
        guard startISO != sprint.startISO || weeks != sprint.weeks else { return }

        let wanted = SprintMath.generateDays(start: startISO, weeks: weeks, saturdayIsWorkingDay: saturdayIsWorkingDay)
        for day in sprint.days where wanted[day.dateISO] == nil {
            context.delete(day)
        }
        sprint.days.removeAll { wanted[$0.dateISO] == nil }
        let kept = Set(sprint.days.map(\.dateISO))
        for iso in wanted.keys.sorted() where !kept.contains(iso) {
            sprint.days.append(Day(dateISO: iso, status: wanted[iso]!.status))
        }
        sprint.startISO = startISO
        sprint.weeks = weeks
        // A manual pin that now matches what the new dates give is dropped, so
        // the sprint goes back to following its dates.
        if let pinned = sprint.archiveOverride {
            sprint.archiveOverride = SprintMath.archiveOverride(pinned, for: sprint.toDTO(), today: today)
        }
    }

    public static func setArchived(_ archived: Bool, _ sprint: Sprint, today: String) {
        sprint.archiveOverride = SprintMath.archiveOverride(archived, for: sprint.toDTO(), today: today)
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
