import Foundation
import FoundationModels

@Generable
public struct MusicNote: Codable, Equatable, Sendable {
    @Guide(description: "MIDI note number, 0–127")
    public var midiNote: Int

    @Guide(description: "Duration in seconds, 0.1–2.0")
    public var duration: Double

    @Guide(description: "Velocity 40–80 for soft, grim feel")
    public var velocity: Int

    public init(midiNote: Int, duration: Double, velocity: Int) {
        self.midiNote = midiNote
        self.duration = duration
        self.velocity = velocity
    }
}

@Generable
public struct MusicPattern: Codable, Equatable, Sendable {
    public var notes: [MusicNote]

    @Guide(description: "Tempo in BPM, 60–70")
    public var tempo: Int

    public init(notes: [MusicNote], tempo: Int) {
        self.notes = notes
        self.tempo = tempo
    }
}

extension MusicPattern {
    /// Descending A-minor arpeggio: the seed pattern for the loop.
    public static let basePattern = MusicPattern(
        notes: [57, 60, 64, 60, 57, 55, 52, 55].map {
            MusicNote(midiNote: $0, duration: 0.4, velocity: 55)
        },
        tempo: 65
    )

    /// Total duration of the pattern in seconds.
    public var duration: TimeInterval {
        notes.reduce(0) { $0 + $1.duration }
    }

    /// Clamp every field into the supported range. Defends against malformed
    /// model output even though `@Guide` constrains generation.
    public func sanitized() -> MusicPattern {
        MusicPattern(
            notes: notes.map { note in
                MusicNote(
                    midiNote: note.midiNote.clamped(to: 0...127),
                    duration: note.duration.clamped(to: 0.1...2.0),
                    velocity: note.velocity.clamped(to: 40...80)
                )
            },
            tempo: tempo.clamped(to: 60...70)
        )
    }

    public func asJSON() throws -> String {
        let data = try JSONEncoder().encode(self)
        return String(decoding: data, as: UTF8.self)
    }
}

extension Comparable {
    fileprivate func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
