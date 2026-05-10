import Foundation
import FoundationModels

public protocol VariationGenerating: Sendable {
    func variation(of pattern: MusicPattern) async throws -> MusicPattern
}

/// Wraps `LanguageModelSession` to mutate a `MusicPattern` by 1–2 notes per call.
/// Falls back to a deterministic local mutation when Foundation Models is
/// unavailable (no entitlement, simulator, restricted device).
public actor VariationGenerator: VariationGenerating {
    private let session: LanguageModelSession?
    private var fallback: DeterministicMutator

    public init() {
        switch SystemLanguageModel.default.availability {
        case .available:
            self.session = LanguageModelSession(instructions: """
                You are a music variation engine for a sad, austere 2D game.
                Given a MIDI note pattern in JSON, return a slightly modified version.
                Change only 1–2 notes or durations. Keep it in A minor (notes from \
                57, 59, 60, 62, 64, 65, 67, 69). Keep tempo the same. Keep velocity \
                in 40–80 and durations in 0.3–0.6. Return the same number of notes.
                """)
        case .unavailable:
            self.session = nil
        }
        self.fallback = DeterministicMutator()
    }

    public func variation(of pattern: MusicPattern) async throws -> MusicPattern {
        guard let session else {
            return fallback.mutate(pattern)
        }
        let prompt = "Current pattern: \(try pattern.asJSON())"
        do {
            let response = try await session.respond(to: prompt, generating: MusicPattern.self)
            let result = response.content.sanitized()
            return result.notes.count == pattern.notes.count ? result : fallback.mutate(pattern)
        } catch {
            return fallback.mutate(pattern)
        }
    }
}

/// Deterministic A-minor scale walk: shifts one note to a neighbouring scale
/// degree on each call. Keeps the demo audible without Foundation Models.
struct DeterministicMutator {
    private let scale = [57, 59, 60, 62, 64, 65, 67, 69]
    private var step = 0

    mutating func mutate(_ pattern: MusicPattern) -> MusicPattern {
        guard !pattern.notes.isEmpty else { return pattern }
        let index = step % pattern.notes.count
        step &+= 1
        var notes = pattern.notes
        let current = notes[index].midiNote
        let scaleIndex = scale.firstIndex(of: current) ?? 0
        let neighbour = scale[(scaleIndex + 1) % scale.count]
        notes[index].midiNote = neighbour
        return MusicPattern(notes: notes, tempo: pattern.tempo).sanitized()
    }
}
