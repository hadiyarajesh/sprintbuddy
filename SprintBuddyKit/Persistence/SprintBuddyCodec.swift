import Foundation

public enum SprintBuddyCodec {
    struct Export: Codable { var app: String; var schema: Int; var exportedAt: String; var sprints: [SprintDTO] }
    public enum ImportError: Error, Equatable { case notJSON, notSprintBuddy }

    /// Encodes the export payload. Throws on failure so callers never write an
    /// empty/partial "backup" silently.
    public static func encode(_ sprints: [SprintDTO]) throws -> Data {
        // The `app` field is informational only — decode never checks its value,
        // so files exported under the old "ScrumBuddy" name still import fine.
        let payload = Export(app: "SprintBuddy", schema: 5,
                             exportedAt: ISO8601DateFormatter().string(from: Date()),
                             sprints: sprints)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted]
        return try enc.encode(payload)
    }

    public static func decode(_ data: Data) -> Result<[SprintDTO], ImportError> {
        // Distinguish "not JSON at all" from "valid JSON of the wrong shape".
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            return .failure(.notJSON)
        }
        guard let obj = json as? [String: Any] else {
            return .failure(.notSprintBuddy)
        }
        guard let rawSprints = obj["sprints"] as? [[String: Any]], !rawSprints.isEmpty else {
            return .failure(.notSprintBuddy)
        }
        let ok = rawSprints.allSatisfy { $0["id"] != nil && $0["start"] != nil && $0["days"] is [String: Any] }
        guard ok else { return .failure(.notSprintBuddy) }
        guard let export = try? JSONDecoder().decode(Export.self, from: data) else {
            return .failure(.notSprintBuddy)
        }
        return .success(export.sprints)
    }
}
