import Foundation
import FoundationModels

public protocol VariationGenerating: Sendable {
    func variation(of pattern: MusicPattern) async throws -> MusicPattern
    func setGenre(_ genre: MusicGenre) async
}

extension VariationGenerating {
    /// Default no-op so existing conformers don't have to react to genre changes.
    public func setGenre(_ genre: MusicGenre) async {}
}

/// Wraps `LanguageModelSession` to mutate a `MusicPattern` by 1–2 notes per call.
/// Falls back to a deterministic local mutation when Foundation Models is
/// unavailable (no entitlement, simulator, restricted device).
public actor VariationGenerator: VariationGenerating {
    private var session: LanguageModelSession?
    private var fallback: DeterministicMutator
    private var genre: MusicGenre

    public init(genre: MusicGenre = .sadAMinor) {
        self.genre = genre
        self.fallback = DeterministicMutator(genre: genre)
        self.session = Self.makeSession(for: genre)
    }

    public func setGenre(_ genre: MusicGenre) {
        guard genre != self.genre else { return }
        self.genre = genre
        self.fallback = DeterministicMutator(genre: genre)
        self.session = Self.makeSession(for: genre)
    }

    public func variation(of pattern: MusicPattern) async throws -> MusicPattern {
        guard let session else {
            return fallback.mutate(pattern)
        }
        let prompt = "Current pattern: \(try pattern.asJSON())"
        do {
            let response = try await session.respond(to: prompt, generating: MusicPattern.self)
            let result = response.content.sanitized(for: genre)
            return result.notes.count == pattern.notes.count ? result : fallback.mutate(pattern)
        } catch {
            return fallback.mutate(pattern)
        }
    }

    private static func makeSession(for genre: MusicGenre) -> LanguageModelSession? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return LanguageModelSession(instructions: genre.instructions)
        case .unavailable:
            return nil
        }
    }
}

/// Deterministic scale walk: shifts one note to a neighbouring scale degree on
/// each call. Keeps the demo audible without Foundation Models.
struct DeterministicMutator {
    private let genre: MusicGenre
    private var step = 0

    init(genre: MusicGenre = .sadAMinor) {
        self.genre = genre
    }

    mutating func mutate(_ pattern: MusicPattern) -> MusicPattern {
        guard !pattern.notes.isEmpty else { return pattern }
        let index = step % pattern.notes.count
        step &+= 1
        var notes = pattern.notes
        let current = notes[index].midiNote
        let scale = genre.scaleNotes
        let scaleIndex = scale.firstIndex(of: current) ?? 0
        let neighbour = scale[(scaleIndex + 1) % scale.count]
        notes[index].midiNote = neighbour
        return MusicPattern(notes: notes, tempo: pattern.tempo).sanitized(for: genre)
    }
}
