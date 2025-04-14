import SwiftUI
import CoreData

struct CameraScreenView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var viewModel = CameraScreenViewModel()
    
    @State private var capturedPhotoPath: String? = nil
    
    @State private var shouldNavigateToDetails = false
    @State private var shouldNavigateToGallery = false
    
    @State private var showPermissionAlert = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        if viewModel.isCameraPermissionGranted == nil {
                            EmptyView()
                        } else if viewModel.isCameraPermissionGranted == false {
                            Text("Camera permission is required.")
                                .foregroundStyle(.white)
                                .padding()
                            
                            Button("Go to Settings") {
                                openSettings()
                            }
                            .padding()
                        } else {
                            CameraPreview(isSessionRunning: $viewModel.isCameraSessionRunning, session: viewModel.getCameraSession())
                                .frame(height: UIScreen.main.bounds.height*0.6)
                            
                            ZStack {
                                HStack() {
                                    if let path = viewModel.lastPhotoPath {
                                        if let image = UIImage(contentsOfFile: path) {
                                            Button(action: {
                                                shouldNavigateToGallery = true
                                            }) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 60, height: 60)
                                                    .clipped()
                                                    .cornerRadius(8)
                                                    .padding([.leading, .bottom], 16)
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                                
                                
                                CustomCaptureButton {
                                    Task {
                                        capturedPhotoPath = await viewModel.capturePhoto()
                                        viewModel.stopCameraSession()
                                        
                                        if capturedPhotoPath != nil {
                                            shouldNavigateToDetails = true
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    .navigationDestination(isPresented: $shouldNavigateToDetails) {
                        DetailsScreenView(photoPath: capturedPhotoPath ?? "")
                    }
                    .navigationDestination(isPresented: $shouldNavigateToGallery) {
                        GalleryScreenView()
                    }
                }
            }
        }
        .onChange(of: shouldNavigateToDetails) {
            Task {
                if !shouldNavigateToDetails { //SwiftUI automatically changes shouldNavigate to false when back button from navigation is clicked
                    viewModel.startCameraSession()
                    await viewModel.fetchLatestPhotoPath(context: viewContext)
                }
            }
        }
        .onChange(of: shouldNavigateToGallery) {
            Task {
                if !shouldNavigateToGallery {
                    viewModel.startCameraSession()
                    await viewModel.fetchLatestPhotoPath(context: viewContext)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchLatestPhotoPath(context: viewContext)
                
                if viewModel.isCameraPermissionGranted == nil {
                    await viewModel.requestCameraPermission()
                }
                
                if viewModel.isCameraPermissionGranted == true {
                    viewModel.startCameraSession()
                    showPermissionAlert = false
                } else {
                    showPermissionAlert = true
                }
            }
        }
        .alert(isPresented: $showPermissionAlert) {
            Alert(
                title: Text("Camera Access Denied"),
                message: Text("Please enable camera access in Settings to use this feature."),
                primaryButton: .default(Text("Go to Settings")) {
                    openSettings()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

struct CustomCaptureButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .foregroundColor(.white)
                .frame(width: 70, height: 70, alignment: .center)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.8), lineWidth: 2)
                        .frame(width: 60, height: 60, alignment: .center)
                )
        }
    }
}

#Preview {
    CameraScreenView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
