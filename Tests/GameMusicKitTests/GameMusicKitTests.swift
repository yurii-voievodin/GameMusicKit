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
