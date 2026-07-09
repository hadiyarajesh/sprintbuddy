import Foundation

enum DayStatus: String, Codable, CaseIterable { case working, leave, holiday, weekend }
enum UpdateType: String, Codable, CaseIterable { case done, doing, blocker }

struct UpdateDTO: Codable, Equatable {
    var id: String
    var type: UpdateType
    var text: String
}

struct DayDTO: Codable, Equatable {
    var status: DayStatus
    var privateNote: String
    var updates: [UpdateDTO]

    init(status: DayStatus, privateNote: String = "", updates: [UpdateDTO] = []) {
        self.status = status; self.privateNote = privateNote; self.updates = updates
    }
    enum CodingKeys: String, CodingKey { case status, privateNote, updates, note }
    init(from dec: Decoder) throws {
        let c = try dec.container(keyedBy: CodingKeys.self)
        status = (try? c.decode(DayStatus.self, forKey: .status)) ?? .working
        privateNote = (try? c.decode(String.self, forKey: .privateNote)) ?? ""
        if let ups = try? c.decode([UpdateDTO].self, forKey: .updates) {
            updates = ups
        } else if let note = try? c.decode(String.self, forKey: .note) {
            updates = note.split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .map { UpdateDTO(id: UUID().uuidString, type: .done, text: $0) }
        } else { updates = [] }
    }
    func encode(to enc: Encoder) throws {
        var c = enc.container(keyedBy: CodingKeys.self)
        try c.encode(status, forKey: .status)
        try c.encode(privateNote, forKey: .privateNote)
        try c.encode(updates, forKey: .updates)
    }
}

struct SprintDTO: Codable, Equatable {
    var id: String
    var name: String
    var description: String
    var start: String
    var weeks: Int
    var days: [String: DayDTO]

    init(id: String, name: String, description: String = "", start: String, weeks: Int, days: [String: DayDTO]) {
        self.id = id; self.name = name; self.description = description
        self.start = start; self.weeks = weeks; self.days = days
    }
    enum CodingKeys: String, CodingKey { case id, name, description, start, weeks, days }
    init(from dec: Decoder) throws {
        let c = try dec.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        start = try c.decode(String.self, forKey: .start)
        weeks = try c.decode(Int.self, forKey: .weeks)
        days = try c.decode([String: DayDTO].self, forKey: .days)
    }
    var orderedDates: [String] { days.keys.sorted() }
}
