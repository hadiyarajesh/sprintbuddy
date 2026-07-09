import Foundation
import SwiftData

struct SprintStore {
    @discardableResult
    static func createSprint(name: String, focus: String, startISO: String, weeks: Int,
                             in context: ModelContext) -> Sprint {
        let dto = SprintDTO(id: "s\(Int(Date().timeIntervalSince1970 * 1000))",
                            name: name, description: focus, start: startISO, weeks: weeks,
                            days: SprintMath.generateDays(start: startISO, weeks: weeks))
        let sprint = Sprint.from(dto)
        context.insert(sprint)
        return sprint
    }

    static func replaceAll(with dtos: [SprintDTO], in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Sprint>())) ?? []
        existing.forEach { context.delete($0) }
        dtos.forEach { context.insert(Sprint.from($0)) }
    }

    static func exportData(_ sprints: [Sprint]) -> Data {
        ScrumBuddyCodec.encode(sprints.map { $0.toDTO() })
    }
}
