import SwiftUI
import CoreData

struct CameraScreenView: View {
    @StateObject private var viewModel = CameraScreenViewModel()

    var body: some View {
        VStack {
            if !viewModel.isPermissionGranted {
                Text("Camera permission is required.")
                    .padding()
                    .onAppear {
                        Task {
                            await viewModel.requestCameraPermission()
                        }
                    }
            } else {
                CameraPreview(isSessionRunning: $viewModel.isSessionRunning, session: CameraManager.shared.session)
                    .frame(height: 300)
                    .padding()

                HStack {
                    Button("Start Camera") {
                        viewModel.startCameraSession()
                    }
                    .disabled(viewModel.isSessionRunning)

                    Button("Stop Camera") {
                        viewModel.stopCameraSession()
                    }
                    .disabled(!viewModel.isSessionRunning)

                    Button("Capture Photo") {
                        Task {
                            await viewModel.capturePhoto()
                        }
                    }
                }

                if let imagePath = viewModel.imagePath {
                    Image(uiImage: UIImage(contentsOfFile: imagePath)!)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
            }
        }
        .onAppear {
            if !viewModel.isPermissionGranted {
                Task {
                    await viewModel.requestCameraPermission()
                }
            }
        }
    }
}

#Preview {
    CameraScreenView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
