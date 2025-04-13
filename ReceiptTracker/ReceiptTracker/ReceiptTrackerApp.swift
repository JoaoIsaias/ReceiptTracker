import SwiftUI
import Toasts

@main
struct ReceiptTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .installToast(position: .bottom)
        }
    }
}
