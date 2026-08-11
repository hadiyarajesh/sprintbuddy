//
//  SprintSummaryCache.swift
//  SprintBuddy
//
//  Stores only derived local summaries. The hash is built from the exact
//  summary input, so private notes never participate in the cache identity.
//

import Foundation
import SprintBuddyKit

enum SprintSummaryCache {
    private struct Entry: Codable {
        let fingerprint: String
        let markdown: String
    }

    static func summary(for sprint: SprintDTO) -> String? {
        let fingerprint = SprintSummaryGenerator.cacheFingerprint(for: sprint)
        guard let entry = entries()[sprint.id], entry.fingerprint == fingerprint else { return nil }
        return entry.markdown
    }

    static func store(_ markdown: String, for sprint: SprintDTO) {
        var stored = entries()
        stored[sprint.id] = Entry(
            fingerprint: SprintSummaryGenerator.cacheFingerprint(for: sprint),
            markdown: markdown
        )
        guard let data = try? JSONEncoder().encode(stored) else { return }
        AppGroup.defaults.set(data, forKey: PrefKey.sprintSummaryCache)
    }

    private static func entries() -> [String: Entry] {
        guard let data = AppGroup.defaults.data(forKey: PrefKey.sprintSummaryCache) else { return [:] }
        return (try? JSONDecoder().decode([String: Entry].self, from: data)) ?? [:]
    }
}
