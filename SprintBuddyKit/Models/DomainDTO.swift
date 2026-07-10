import Foundation

public enum DayStatus: String, Codable, CaseIterable { case working, leave, holiday, weekend }
public enum UpdateType: String, Codable, CaseIterable { case done, doing, blocker }

public struct UpdateDTO: Codable, Equatable {
    public var id: String
    public var type: UpdateType
    public var text: String

    public init(id: String, type: UpdateType, text: String) {
        self.id = id; self.type = type; self.text = text
    }
}

public struct DayDTO: Codable, Equatable {
    public var status: DayStatus
    public var privateNote: String
    public var updates: [UpdateDTO]

    public init(status: DayStatus, privateNote: String = "", updates: [UpdateDTO] = []) {
        self.status = status; self.privateNote = privateNote; self.updates = updates
    }
    enum CodingKeys: String, CodingKey { case status, privateNote, updates, note }
    public init(from dec: Decoder) throws {
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
    public func encode(to enc: Encoder) throws {
        var c = enc.container(keyedBy: CodingKeys.self)
        try c.encode(status, forKey: .status)
        try c.encode(privateNote, forKey: .privateNote)
        try c.encode(updates, forKey: .updates)
    }
}

public struct SprintDTO: Codable, Equatable {
    public var id: String
    public var name: String
    public var description: String
    public var start: String
    public var weeks: Int
    public var days: [String: DayDTO]

    public init(id: String, name: String, description: String = "", start: String, weeks: Int, days: [String: DayDTO]) {
        self.id = id; self.name = name; self.description = description
        self.start = start; self.weeks = weeks; self.days = days
    }
    enum CodingKeys: String, CodingKey { case id, name, description, start, weeks, days }
    public init(from dec: Decoder) throws {
        let c = try dec.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        start = try c.decode(String.self, forKey: .start)
        weeks = try c.decode(Int.self, forKey: .weeks)
        days = try c.decode([String: DayDTO].self, forKey: .days)
    }
    public var orderedDates: [String] { days.keys.sorted() }
}
