import Dispatch
import Foundation

/// Drives the play loop: schedules pattern N for playback, generates pattern
/// N+1 in parallel, swaps to N+1 at the boundary. If generation isn't ready
/// when the loop ends, replays the last good pattern so audio never gaps.
public actor Conductor {
    private let engine: MusicEngine
    private let generator: any VariationGenerating
    private var current: MusicPattern
    private var pendingGenre: MusicGenre?

    public init(
        engine: MusicEngine = MusicEngine(),
        generator: any VariationGenerating = VariationGenerator(),
        seed: MusicPattern = .basePattern
    ) {
        self.engine = engine
        self.generator = generator
        self.current = seed
        self.pendingGenre = nil
    }

    /// Convenience for spinning up with a specific genre. Equivalent to
    /// constructing a `VariationGenerator(genre:)` and seeding with the
    /// genre's base pattern.
    public init(genre: MusicGenre) {
        self.engine = MusicEngine()
        self.generator = VariationGenerator(genre: genre)
        self.current = genre.basePattern
        self.pendingGenre = nil
    }

    /// Queue a genre switch. Takes effect at the next loop boundary so the
    /// currently-playing bar finishes cleanly.
    public func switchGenre(_ genre: MusicGenre) {
        pendingGenre = genre
    }

    public func run() async throws {
        try engine.start()
        // Small lead-in so the first note isn't scheduled in the past after
        // engine startup latency.
        var startAt = engine.now() + .milliseconds(100)
        while !Task.isCancelled {
            if let next = pendingGenre {
                await generator.setGenre(next)
                current = next.basePattern
                pendingGenre = nil
            }
            let endAt = engine.play(current, startAt: startAt)
            let playing = current
            let pending = Task { [generator] in
                try await generator.variation(of: playing)
            }
            try await Task.sleep(until: endAt)
            let variation = (try? await pending.value) ?? playing
            // If a genre switch was requested mid-loop, discard the in-flight
            // variation — the next iteration will seed from the new genre.
            if pendingGenre == nil {
                current = variation
            }
            startAt = endAt
        }
    }
}

extension Task where Success == Never, Failure == Never {
    /// Suspend until the given `DispatchTime` deadline.
    static func sleep(until deadline: DispatchTime) async throws {
        let now = DispatchTime.now()
        guard deadline > now else { return }
        let ns = deadline.uptimeNanoseconds - now.uptimeNanoseconds
        try await Task.sleep(nanoseconds: ns)
    }
}
