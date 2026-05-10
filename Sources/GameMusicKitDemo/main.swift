import Foundation
import GameMusicKit

print("GameMusicKit demo — playing seed pattern, asking Foundation Models for variations.")
print("Listen for: descending A-minor arpeggio, ~65 BPM, with 1–2 notes shifting each loop.")
print("Ctrl-C to stop.")

let conductor = Conductor()
try await conductor.run()
