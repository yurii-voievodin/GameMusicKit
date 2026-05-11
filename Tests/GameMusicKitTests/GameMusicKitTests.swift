import Foundation
import Testing
@testable import GameMusicKit

@Test func basePatternMatchesBrief() {
    let p = MusicPattern.basePattern
    #expect(p.notes.map(\.midiNote) == [57, 60, 64, 60, 57, 55, 52, 55])
    #expect(p.notes.allSatisfy { $0.duration == 0.4 })
    #expect(p.notes.allSatisfy { $0.velocity == 55 })
    #expect(p.tempo == 65)
    #expect(abs(p.duration - 3.2) < 1e-9)
}

@Test func sanitizedClampsOutOfRangeFields() {
    let dirty = MusicPattern(
        notes: [
            MusicNote(midiNote: 999, duration: 5.0, velocity: 200),
            MusicNote(midiNote: -10, duration: 0.0, velocity: 10),
        ],
        tempo: 200
    )
    let clean = dirty.sanitized()
    #expect(clean.notes[0].midiNote == 127)
    #expect(clean.notes[0].duration == 2.0)
    #expect(clean.notes[0].velocity == 80)
    #expect(clean.notes[1].midiNote == 0)
    #expect(clean.notes[1].duration == 0.1)
    #expect(clean.notes[1].velocity == 40)
    #expect(clean.tempo == 70)
}

@Test func patternRoundTripsThroughJSON() throws {
    let original = MusicPattern.basePattern
    let json = try original.asJSON()
    let decoded = try JSONDecoder().decode(MusicPattern.self, from: Data(json.utf8))
    #expect(decoded == original)
}

@Test func deterministicMutatorChangesOneNoteOnly() {
    var m = DeterministicMutator()
    let original = MusicPattern.basePattern
    let mutated = m.mutate(original)
    let diffs = zip(original.notes, mutated.notes).filter { $0.0 != $0.1 }
    #expect(diffs.count == 1)
    #expect(mutated.notes.count == original.notes.count)
    #expect(mutated.tempo == original.tempo)
}

@Test func defaultGenreMatchesLegacyBasePattern() {
    #expect(MusicGenre.sadAMinor.basePattern == MusicPattern.basePattern)
    #expect(MusicGenre.sadAMinor.tempoRange == 60...70)
    #expect(MusicGenre.sadAMinor.velocityRange == 40...80)
    #expect(MusicGenre.sadAMinor.durationRange == 0.3...0.6)
}

@Test func allBuiltInGenresBasePatternsAreInRange() {
    for genre in MusicGenre.allBuiltIn {
        #expect(genre.tempoRange.contains(genre.basePattern.tempo), "tempo out of range in \(genre.name)")
        for note in genre.basePattern.notes {
            #expect(genre.velocityRange.contains(note.velocity), "velocity out of range in \(genre.name)")
            #expect(genre.durationRange.contains(note.duration), "duration out of range in \(genre.name)")
            #expect(genre.scaleNotes.contains(note.midiNote), "note \(note.midiNote) not in scale for \(genre.name)")
        }
    }
}

@Test func sanitizedForGenreClampsToGenreRanges() {
    let dirty = MusicPattern(
        notes: [
            MusicNote(midiNote: 200, duration: 5.0, velocity: 200),
            MusicNote(midiNote: -5, duration: 0.0, velocity: 0),
        ],
        tempo: 9999
    )
    let clean = dirty.sanitized(for: .heroicCMajor)
    #expect(clean.notes[0].midiNote == 127)
    #expect(clean.notes[0].duration == 0.5)
    #expect(clean.notes[0].velocity == 110)
    #expect(clean.notes[1].midiNote == 0)
    #expect(clean.notes[1].duration == 0.2)
    #expect(clean.notes[1].velocity == 70)
    #expect(clean.tempo == 130)
}

@Test func deterministicMutatorRespectsGenreScale() {
    var m = DeterministicMutator(genre: .heroicCMajor)
    let mutated = m.mutate(MusicGenre.heroicCMajor.basePattern)
    let scale = MusicGenre.heroicCMajor.scaleNotes
    #expect(mutated.notes.allSatisfy { scale.contains($0.midiNote) })
    #expect(MusicGenre.heroicCMajor.tempoRange.contains(mutated.tempo))
}

@Test func variationGeneratorSwitchesGenreRanges() async throws {
    let generator = VariationGenerator(genre: .sadAMinor)
    await generator.setGenre(.heroicCMajor)
    let seed = MusicGenre.heroicCMajor.basePattern
    let result = try await generator.variation(of: seed)
    #expect(result.notes.count == seed.notes.count)
    #expect(MusicGenre.heroicCMajor.tempoRange.contains(result.tempo))
    #expect(result.notes.allSatisfy { MusicGenre.heroicCMajor.velocityRange.contains($0.velocity) })
    #expect(result.notes.allSatisfy { MusicGenre.heroicCMajor.durationRange.contains($0.duration) })
}
