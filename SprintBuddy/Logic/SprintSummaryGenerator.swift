//
//  SprintSummaryGenerator.swift
//  SprintBuddy
//
//  Builds a concise sprint recap with Apple's on-device Foundation Models
//  framework. Private notes are intentionally excluded from the prompt.
//

import Foundation
import SprintBuddyKit
import CryptoKit

#if canImport(FoundationModels)
import FoundationModels
#endif

enum SprintSummaryResult {
    case success(String)
    case unavailable(String)
    case failure(String)
}

enum SprintSummaryGenerator {
    /// Bump this whenever the summary instructions or input shape change so
    /// earlier generated wording is never shown under new rules.
    private static let cacheVersion = "workstream-summary-v2-status-safe"

    static func generate(for sprint: SprintDTO) async -> SprintSummaryResult {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return await generateOnDevice(for: sprint)
        }
        #endif
        return .unavailable("On-device summaries require macOS 26 or later with Apple Intelligence available.")
    }

    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private static func generateOnDevice(for sprint: SprintDTO) async -> SprintSummaryResult {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            return .unavailable("Apple Intelligence isn’t ready on this Mac. Turn it on in System Settings, allow the model download to finish, then try again.")
        }

        do {
            let sections = [
                try await section(title: "Delivered", status: .done, sprint: sprint),
                try await section(title: "In progress", status: .doing, sprint: sprint),
                try await section(title: "Blocked", status: .blocker, sprint: sprint),
            ]
            return .success(sections.joined(separator: "\n\n"))
        } catch {
            return .failure("The on-device model couldn’t create a summary just now. Please try again.")
        }
    }
    #endif

    #if canImport(FoundationModels)
    /// Each status is summarized independently. That makes the status in the
    /// source data authoritative instead of asking the model to classify it.
    private static func section(title: String, status: UpdateType, sprint: SprintDTO) async throws -> String {
        let updates = updates(for: sprint, status: status)
        guard !updates.isEmpty else { return "## \(title)\n- Nothing logged." }

        let session = LanguageModelSession(instructions: """
        You summarize one individual's work updates. Every input item is definitively marked with the same status; never infer or change its status. Do not invent, evaluate, or add context.
        """)
        let response = try await session.respond(to: """
        Write only the \(title) section for a sprint summary. All source items below are definitively \(UpdateMeta.label(status).uppercased()).

        Combine related items into 1–3 concise workstream-level Markdown bullets. Do not list dates, chronology, or every task individually. Do not use "team", "we", "our", "they", task totals, percentages, performance judgments, generic praise, or the phrase "worked on". Return bullets only—no heading and no introductory text.

        Sprint: \(sprint.name)
        Focus: \(sprint.description.trimmingCharacters(in: .whitespacesAndNewlines))
        Source items:
        \(updates.joined(separator: "\n"))
        """)

        return "## \(title)\n\(markdownBullets(from: response.content))"
    }

    private static func updates(for sprint: SprintDTO, status: UpdateType) -> [String] {
        sprint.orderedDates.flatMap { iso in
            (sprint.days[iso]?.updates ?? [])
                .filter { $0.type == status }
                .map { "- [\(UpdateMeta.label(status).uppercased())] \($0.text)" }
        }
    }

    private static func markdownBullets(from response: String) -> String {
        let sectionTitles = ["delivered", "in progress", "blocked", "done", "doing", "blocker"]
        let cleaned = response.components(separatedBy: .newlines).compactMap { line -> String? in
            let text = line
                .replacingOccurrences(of: "^\\s*(?:[-*•]|\\d+[.)])\\s*", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, !sectionTitles.contains(text.lowercased()) else { return nil }
            return "- \(text)"
        }
        return cleaned.prefix(3).joined(separator: "\n")
    }
    #endif

    /// Canonical, status-tagged source used only for cache invalidation.
    private static func prompt(for sprint: SprintDTO) -> String {
        var lines = [
            "Sprint: \(sprint.name)",
            "Focus: \(sprint.description.trimmingCharacters(in: .whitespacesAndNewlines))",
        ]

        for type in [UpdateType.done, .doing, .blocker] {
            lines.append("\(UpdateMeta.label(type)) updates:")
            lines.append(contentsOf: updates(for: sprint, status: type))
        }

        return lines.joined(separator: "\n")
    }

    /// A stable fingerprint of exactly the data supplied to the model, plus
    /// the prompt version. `prompt(for:)` never includes private notes.
    static func cacheFingerprint(for sprint: SprintDTO) -> String {
        let input = "\(cacheVersion)\n\(prompt(for: sprint))"
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
