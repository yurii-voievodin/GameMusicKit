import GameMusicKit
import SwiftUI

@main
struct GameMusicKitDemoApp: App {
    var body: some Scene {
        WindowGroup("GameMusicKit Demo") {
            ContentView()
                .frame(minWidth: 360, minHeight: 200)
        }
        .windowResizability(.contentSize)
    }
}

@MainActor
final class PlayerModel: ObservableObject {
    @Published var isPlaying = false
    @Published var genreName: String = MusicGenre.sadAMinor.name {
        didSet {
            guard oldValue != genreName, let g = genre(named: genreName) else { return }
            let c = conductor
            Task { await c?.switchGenre(g) }
        }
    }

    private var conductor: Conductor?
    private var task: Task<Void, Never>?

    var genres: [MusicGenre] { MusicGenre.allBuiltIn }

    func toggle() {
        isPlaying ? stop() : start()
    }

    private func start() {
        guard let g = genre(named: genreName) else { return }
        let c = Conductor(genre: g)
        conductor = c
        isPlaying = true
        task = Task {
            try? await c.run()
        }
    }

    private func stop() {
        task?.cancel()
        task = nil
        conductor = nil
        isPlaying = false
    }

    private func genre(named name: String) -> MusicGenre? {
        MusicGenre.allBuiltIn.first { $0.name == name }
    }
}

struct ContentView: View {
    @StateObject private var model = PlayerModel()

    var body: some View {
        VStack(spacing: 24) {
            Picker("Genre", selection: $model.genreName) {
                ForEach(model.genres, id: \.name) { g in
                    Text(g.name).tag(g.name)
                }
            }
            .pickerStyle(.menu)

            Button(action: model.toggle) {
                Label(model.isPlaying ? "Pause" : "Play",
                      systemImage: model.isPlaying ? "pause.fill" : "play.fill")
                    .frame(minWidth: 100)
            }
            .keyboardShortcut(.space, modifiers: [])
            .controlSize(.large)
        }
        .padding(32)
    }
}
