import SwiftUI
import CoreData

struct CameraView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            Text("ReceiptTracker")
        }
    }
}

#Preview {
    CameraView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
