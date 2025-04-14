import SwiftUI
import CoreData
import Toasts

struct GalleryScreenView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentToast) var presentToast
    
    @StateObject private var viewModel = GalleryScreenViewModel()
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(viewModel.photoPaths.enumerated()), id: \.offset) { index, path in
                        ThumbnailImageView(path: path)
                            .onTapGesture {
                                //Open Details Screen
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deletePhoto(at: index, context: viewContext)
                                    
                                    presentToast(ToastValue(message: "Receipt/Invoice deleted!"))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding()
            }
            .onAppear {
                Task {
                    await viewModel.fetchAllPhotoPaths(context: viewContext)
                }
            }
        }
}

#Preview {
    GalleryScreenView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
