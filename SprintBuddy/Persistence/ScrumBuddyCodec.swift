import Foundation

enum ScrumBuddyCodec {
    struct Export: Codable { var app: String; var schema: Int; var exportedAt: String; var sprints: [SprintDTO] }
    enum ImportError: Error, Equatable { case notJSON, notScrumBuddy }

    static func encode(_ sprints: [SprintDTO]) -> Data {
        let payload = Export(app: "ScrumBuddy", schema: 5,
                             exportedAt: ISO8601DateFormatter().string(from: Date()),
                             sprints: sprints)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted]
        return (try? enc.encode(payload)) ?? Data()
    }

    static func decode(_ data: Data) -> Result<[SprintDTO], ImportError> {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .failure(.notJSON)
        }
        guard let rawSprints = obj["sprints"] as? [[String: Any]], !rawSprints.isEmpty else {
            return .failure(.notScrumBuddy)
        }
        let ok = rawSprints.allSatisfy { $0["id"] != nil && $0["start"] != nil && $0["days"] is [String: Any] }
        guard ok else { return .failure(.notScrumBuddy) }
        guard let export = try? JSONDecoder().decode(Export.self, from: data) else {
            return .failure(.notScrumBuddy)
        }
        return .success(export.sprints)
    }
}
