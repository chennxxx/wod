import SwiftData
import SwiftUI

@main
struct WODTrackApp: App {
    private let container: ModelContainer = {
        let schema = Schema([WODRecord.self, SkillStatus.self, SkillTrainingEntry.self])
        let configuration = ModelConfiguration("WODTrackStore_v3", schema: schema)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
