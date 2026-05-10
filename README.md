# GameMusicKit

Proof-of-concept adaptive game music for Apple platforms. Loops a soft, sad
A-minor MIDI pattern through `AVAudioEngine` + `AVAudioUnitSampler` and asks
**Apple Foundation Models** (on-device, iOS/macOS 26+) for a 1–2 note
variation each loop.

## How it works

1. `MusicPattern` — a `@Generable` struct of MIDI notes + tempo.
2. `MusicEngine` — schedules each note against an absolute `DispatchTime`
   so successive loops chain back-to-back with no audible gap.
3. `VariationGenerator` — `LanguageModelSession` mutates the current
   pattern (1–2 notes, stays in A-minor). Falls back to a deterministic
   scale walk if Foundation Models is unavailable.
4. `Conductor` — double-buffered loop: while loop *N* plays, loop *N+1*
   is generated in parallel; if generation isn't ready in time, the
   previous pattern replays.

## Run

Requires macOS 26+ on Apple silicon (Foundation Models is unavailable in
the Simulator).

```sh
swift run GameMusicKitDemo
```

Listen for a descending A-minor arpeggio at ~65 BPM with one or two notes
shifting on each loop, and no clicks at the loop boundaries.

## Tests

```sh
swift test
```
