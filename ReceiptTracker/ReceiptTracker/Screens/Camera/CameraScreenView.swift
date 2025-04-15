import SwiftUI
import CoreData

struct CameraScreenView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var viewModel: CameraScreenViewModel
    
    @State private var capturedPhotoPath: String? = nil
    
    @State private var shouldNavigateToDetails = false
    @State private var shouldNavigateToGallery = false
    
    @State private var showPermissionAlert = false
    
    init(viewModel: CameraScreenViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? CameraScreenViewModel())
    }
    
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
                                .accessibilityIdentifier("CameraScreenPermissionText")
                            
                            Button("Go to Settings") {
                                openSettings()
                            }
                            .padding()
                            .accessibilityIdentifier("CameraScreenSettingsButton")
                        } else {
                            CameraPreview(isSessionRunning: $viewModel.isCameraSessionRunning, session: viewModel.getCameraSession())
                                .frame(height: UIScreen.main.bounds.height*0.6)
                            
                            ZStack {
                                HStack() {
                                    if let path = viewModel.lastPhotoPath {
                                        ThumbnailImageView(path: path, width: 60, height: 60)
                                            .onTapGesture {
                                                shouldNavigateToGallery = true
                                                viewModel.lastPhotoPath = nil //Helps SwiftUI loading lastPhotoPath correctly when returning to view
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
                                            viewModel.lastPhotoPath = nil
                                        }
                                    }
                                }
                                .accessibilityIdentifier("CameraScreenCaptureButton")
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

#Preview {
    CameraScreenView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
