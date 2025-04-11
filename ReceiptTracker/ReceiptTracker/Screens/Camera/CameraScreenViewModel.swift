import Foundation
import AVFoundation

@MainActor
class CameraScreenViewModel: ObservableObject {
    @Published var imagePath: String? = nil
    @Published var isSessionRunning: Bool = false
    @Published var isPermissionGranted: Bool = false
    
    private let cameraManager: CameraManagerProtocol

    init(cameraManager: CameraManagerProtocol = CameraManager.shared) {
        self.cameraManager = cameraManager
    }
    
    func requestCameraPermission() async {
        isPermissionGranted = await cameraManager.requestPermission()
    }
    
    func startCameraSession() {
        cameraManager.startSession()
        isSessionRunning = cameraManager.isSessionRunning
    }

    func stopCameraSession() {
        cameraManager.stopSession()
        isSessionRunning = cameraManager.isSessionRunning
    }
    
    func capturePhoto() async {
        do {
            if let path = try await cameraManager.capturePhoto() {
                imagePath = path
            }
        } catch {
            print("Error capturing photo: \(error)")
        }
    }
}
