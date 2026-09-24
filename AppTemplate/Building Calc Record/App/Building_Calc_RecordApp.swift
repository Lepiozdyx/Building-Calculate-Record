import SwiftData
import SwiftUI

struct Building_Calc_RecordApp: View {
    @State private var settings = SettingsStore()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([CalculationRecord.self, CustomMaterial.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some View {
        RootView()
            .environment(settings)
            .task {
                SeedService.applyIfNeeded(
                    context: sharedModelContainer.mainContext,
                    settings: settings
                )
                if settings.tipOfTheDay {
                    await NotificationScheduler.shared.updateTipSchedule(enabled: true)
                }
            }
            .modelContainer(sharedModelContainer)
    }
}
