import SwiftUI
import CoreData

struct GalleryScreenView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
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
                        if let image = UIImage(contentsOfFile: path) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(8)
                                .onTapGesture {
                                    //Open Details Screen
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.deletePhoto(at: index, context: viewContext)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
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
