import SwiftUI
import Toasts

@main
struct ReceiptTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            let context = PersistenceController.shared.container.viewContext

            if CommandLine.arguments.contains("-UITestCameraScreen") {
                CameraScreenView(viewModel: MockCameraScreenViewModel())
                    .environment(\.managedObjectContext, context)
                    .installToast(position: .bottom)
            } else if CommandLine.arguments.contains("-UITestGalleryScreen") {
                NavigationStack {
                    GalleryScreenView(viewModel: MockGalleryScreenViewModel())
                    .environment(\.managedObjectContext, context)
                    .installToast(position: .bottom)
                }
            } else if CommandLine.arguments.contains("-UITestDetailsScreen") {
                DetailsScreenView(viewModel: MockDetailsScreenViewModel(), photoPath: Bundle.main.path(forResource: "testImage", ofType: "jpg"))
                    .environment(\.managedObjectContext, context)
                    .installToast(position: .bottom)
            } else { // non-testing start
                CameraScreenView()
                    .environment(\.managedObjectContext, context)
                    .installToast(position: .bottom)
            }
                
        }
    }
}
