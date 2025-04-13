import SwiftUI
import CoreData

struct DetailsScreenView: View {
    let photoPath: String
    
    var body: some View {
        Text("Details Screen")
    }
}

#Preview {
    DetailsScreenView(photoPath: "").environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
