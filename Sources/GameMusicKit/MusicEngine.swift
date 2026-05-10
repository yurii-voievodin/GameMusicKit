@preconcurrency import AVFoundation
import Dispatch
import Foundation

/// Schedules `MusicPattern`s on an `AVAudioUnitSampler` using absolute
/// `DispatchTime` deadlines so successive patterns concatenate without gap.
public final class MusicEngine: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private let queue = DispatchQueue(label: "GameMusicKit.MusicEngine.scheduler", qos: .userInteractive)

    public init() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
    }

    /// Output volume in range 0.0 – 1.0. Applied on the main mixer node.
    public var volume: Float {
        get { engine.mainMixerNode.outputVolume }
        set { engine.mainMixerNode.outputVolume = max(0, min(1, newValue)) }
    }

    public func start() throws {
        engine.prepare()
        try engine.start()
    }

    public func stop() {
        engine.stop()
    }

    /// Reference instant on the same monotonic clock used by `play`.
    public func now() -> DispatchTime { .now() }

    /// Schedules `pattern` to begin at `startAt` and returns the instant at
    /// which the last note's stop event fires — feed that back as `startAt`
    /// for the next loop to chain seamlessly.
    @discardableResult
    public func play(_ pattern: MusicPattern, startAt: DispatchTime) -> DispatchTime {
        var cursor = startAt
        for note in pattern.notes {
            let onAt = cursor
            let durationNs = UInt64(max(0, note.duration) * 1_000_000_000)
            let offAt = onAt + .nanoseconds(Int(durationNs))
            let midi = UInt8(clamping: note.midiNote)
            let vel = UInt8(clamping: note.velocity)
            let s = sampler
            queue.asyncAfter(deadline: onAt) {
                s.startNote(midi, withVelocity: vel, onChannel: 0)
            }
            queue.asyncAfter(deadline: offAt) {
                s.stopNote(midi, onChannel: 0)
            }
            cursor = offAt
        }
        return cursor
    }
}
