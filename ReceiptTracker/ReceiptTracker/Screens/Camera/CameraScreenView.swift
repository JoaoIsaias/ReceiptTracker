import SwiftUI
import CoreData

struct CameraScreenView: View {
    @StateObject private var viewModel = CameraScreenViewModel()
    
    @State private var capturedPhotoPath: String? = nil
    @State private var shouldNavigate = false
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
                            
                            
                            HStack {
                                CustomCaptureButton {
                                    Task {
                                        capturedPhotoPath = await viewModel.capturePhoto()
                                        viewModel.stopCameraSession()
                                        
                                        if capturedPhotoPath != nil {
                                            shouldNavigate = true
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    .navigationDestination(isPresented: $shouldNavigate) {
                        DetailsScreenView(photoPath: capturedPhotoPath ?? "")
                    }
                }
            }
        }
        .onAppear {
            Task {
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
        .onChange(of: shouldNavigate) {
            if !shouldNavigate { //SwiftUI automatically changes shouldNavigate to false when back button from navigation is clicked
                viewModel.startCameraSession()
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
