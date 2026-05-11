import Foundation

/// A musical style: a seed pattern, the scale to mutate within, value ranges
/// for clamping, and the instructions handed to the language model.
public struct MusicGenre: Sendable, Equatable {
    public let name: String
    public let basePattern: MusicPattern
    public let scaleNotes: [Int]
    public let tempoRange: ClosedRange<Int>
    public let velocityRange: ClosedRange<Int>
    public let durationRange: ClosedRange<Double>
    public let instructions: String

    public init(
        name: String,
        basePattern: MusicPattern,
        scaleNotes: [Int],
        tempoRange: ClosedRange<Int>,
        velocityRange: ClosedRange<Int>,
        durationRange: ClosedRange<Double>,
        instructions: String
    ) {
        self.name = name
        self.basePattern = basePattern
        self.scaleNotes = scaleNotes
        self.tempoRange = tempoRange
        self.velocityRange = velocityRange
        self.durationRange = durationRange
        self.instructions = instructions
    }
}

extension MusicGenre {
    /// Soft, austere descending A-minor arpeggio. The original GameMusicKit
    /// genre; remains the library default for backwards compatibility.
    public static let sadAMinor = MusicGenre(
        name: "Sad A-Minor",
        basePattern: .basePattern,
        scaleNotes: [57, 59, 60, 62, 64, 65, 67, 69],
        tempoRange: 60...70,
        velocityRange: 40...80,
        durationRange: 0.3...0.6,
        instructions: """
            You are a music variation engine for a sad, austere 2D game.
            Given a MIDI note pattern in JSON, return a slightly modified version.
            Change only 1–2 notes or durations. Keep it in A minor (notes from \
            57, 59, 60, 62, 64, 65, 67, 69). Keep tempo the same. Keep velocity \
            in 40–80 and durations in 0.3–0.6. Return the same number of notes.
            """
    )

    /// Bright, anthemic C-major figure for triumphant moments.
    public static let heroicCMajor = MusicGenre(
        name: "Heroic C-Major",
        basePattern: MusicPattern(
            notes: [60, 64, 67, 72, 67, 64, 67, 60].map {
                MusicNote(midiNote: $0, duration: 0.3, velocity: 90)
            },
            tempo: 120
        ),
        scaleNotes: [60, 62, 64, 65, 67, 69, 71, 72],
        tempoRange: 110...130,
        velocityRange: 70...110,
        durationRange: 0.2...0.5,
        instructions: """
            You are a music variation engine for a heroic, anthemic 2D game.
            Given a MIDI note pattern in JSON, return a slightly modified version.
            Change only 1–2 notes or durations. Keep it in C major (notes from \
            60, 62, 64, 65, 67, 69, 71, 72). Keep tempo the same. Keep velocity \
            in 70–110 and durations in 0.2–0.5. Return the same number of notes.
            """
    )

    /// Slow, floating D-Dorian phrase for exploration and ambient scenes.
    public static let mysteriousDorian = MusicGenre(
        name: "Mysterious D-Dorian",
        basePattern: MusicPattern(
            notes: [62, 65, 69, 72, 69, 67, 65, 62].map {
                MusicNote(midiNote: $0, duration: 0.6, velocity: 65)
            },
            tempo: 88
        ),
        scaleNotes: [62, 64, 65, 67, 69, 71, 72, 74],
        tempoRange: 80...95,
        velocityRange: 45...85,
        durationRange: 0.4...1.0,
        instructions: """
            You are a music variation engine for a mysterious, ambient 2D game.
            Given a MIDI note pattern in JSON, return a slightly modified version.
            Change only 1–2 notes or durations. Keep it in D Dorian (notes from \
            62, 64, 65, 67, 69, 71, 72, 74). Keep tempo the same. Keep velocity \
            in 45–85 and durations in 0.4–1.0. Return the same number of notes.
            """
    )

    /// Quick, restless E-minor figure for chases and tense encounters.
    public static let tenseEMinor = MusicGenre(
        name: "Tense E-Minor",
        basePattern: MusicPattern(
            notes: [64, 62, 60, 59, 60, 62, 64, 67].map {
                MusicNote(midiNote: $0, duration: 0.25, velocity: 75)
            },
            tempo: 110
        ),
        scaleNotes: [52, 54, 55, 57, 59, 60, 62, 64],
        tempoRange: 100...120,
        velocityRange: 60...100,
        durationRange: 0.15...0.4,
        instructions: """
            You are a music variation engine for a tense, dramatic 2D game.
            Given a MIDI note pattern in JSON, return a slightly modified version.
            Change only 1–2 notes or durations. Keep it in E minor (notes from \
            52, 54, 55, 57, 59, 60, 62, 64). Keep tempo the same. Keep velocity \
            in 60–100 and durations in 0.15–0.4. Return the same number of notes.
            """
    )

    /// Bouncy C major pentatonic loop for playful, lighthearted moments.
    public static let playfulPentatonic = MusicGenre(
        name: "Playful Pentatonic",
        basePattern: MusicPattern(
            notes: [60, 64, 67, 64, 69, 67, 64, 60].map {
                MusicNote(midiNote: $0, duration: 0.25, velocity: 80)
            },
            tempo: 130
        ),
        scaleNotes: [60, 62, 64, 67, 69, 72],
        tempoRange: 120...140,
        velocityRange: 65...95,
        durationRange: 0.2...0.4,
        instructions: """
            You are a music variation engine for a playful, bouncy 2D game.
            Given a MIDI note pattern in JSON, return a slightly modified version.
            Change only 1–2 notes or durations. Keep it in C major pentatonic \
            (notes from 60, 62, 64, 67, 69, 72). Keep tempo the same. Keep \
            velocity in 65–95 and durations in 0.2–0.4. Return the same number of notes.
            """
    )

    /// All built-in genres, in a stable order suitable for cycling demos.
    public static let allBuiltIn: [MusicGenre] = [
        .sadAMinor,
        .heroicCMajor,
        .mysteriousDorian,
        .tenseEMinor,
        .playfulPentatonic,
    ]
}
