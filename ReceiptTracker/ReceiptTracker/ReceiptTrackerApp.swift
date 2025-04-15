import SwiftUI
import Toasts

@main
struct ReceiptTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            let context = PersistenceController.shared.container.viewContext

            if CommandLine.arguments.contains("-UITest") {
                CameraScreenView(viewModel: MockCameraScreenViewModel())
                    .environment(\.managedObjectContext, context)
            } else {
                CameraScreenView()
                    .environment(\.managedObjectContext, context)
                    .installToast(position: .bottom)
            }
                
        }
    }
}
