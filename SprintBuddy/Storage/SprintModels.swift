import Foundation
import SwiftData

@Model final class Sprint {
    var id: String = ""
    var name: String = ""
    var focus: String = ""
    var startISO: String = ""
    var weeks: Int = 2
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \Day.sprint) var days: [Day] = []

    init(id: String, name: String, focus: String, startISO: String, weeks: Int, createdAt: Date = Date()) {
        self.id = id; self.name = name; self.focus = focus
        self.startISO = startISO; self.weeks = weeks; self.createdAt = createdAt
    }

    func toDTO() -> SprintDTO {
        var dayMap: [String: DayDTO] = [:]
        for d in days {
            let ups = d.updates.sorted { $0.sortIndex < $1.sortIndex }
                .map { UpdateDTO(id: $0.id, type: $0.type, text: $0.text) }
            dayMap[d.dateISO] = DayDTO(status: d.status, privateNote: d.privateNote, updates: ups)
        }
        return SprintDTO(id: id, name: name, description: focus, start: startISO, weeks: weeks, days: dayMap)
    }

    static func from(_ dto: SprintDTO) -> Sprint {
        let s = Sprint(id: dto.id, name: dto.name, focus: dto.description, startISO: dto.start, weeks: dto.weeks)
        for iso in dto.orderedDates {
            let dd = dto.days[iso]!
            let day = Day(dateISO: iso, status: dd.status, privateNote: dd.privateNote)
            for (i, u) in dd.updates.enumerated() {
                day.updates.append(DayUpdate(id: u.id, type: u.type, text: u.text, sortIndex: i))
            }
            s.days.append(day)
        }
        return s
    }
}

@Model final class Day {
    var dateISO: String = ""
    var statusRaw: String = DayStatus.working.rawValue
    var privateNote: String = ""
    @Relationship(deleteRule: .cascade, inverse: \DayUpdate.day) var updates: [DayUpdate] = []
    var sprint: Sprint?

    init(dateISO: String, status: DayStatus, privateNote: String = "") {
        self.dateISO = dateISO; self.statusRaw = status.rawValue; self.privateNote = privateNote
    }
    var status: DayStatus {
        get { DayStatus(rawValue: statusRaw) ?? .working }
        set { statusRaw = newValue.rawValue }
    }
}

@Model final class DayUpdate {
    var id: String = UUID().uuidString
    var typeRaw: String = UpdateType.done.rawValue
    var text: String = ""
    var sortIndex: Int = 0
    var day: Day?

    init(id: String, type: UpdateType, text: String, sortIndex: Int) {
        self.id = id; self.typeRaw = type.rawValue; self.text = text; self.sortIndex = sortIndex
    }
    var type: UpdateType {
        get { UpdateType(rawValue: typeRaw) ?? .doing }
        set { typeRaw = newValue.rawValue }
    }
}
