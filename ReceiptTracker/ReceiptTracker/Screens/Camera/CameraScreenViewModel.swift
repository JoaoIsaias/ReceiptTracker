import Foundation
import AVFoundation
import Combine

@MainActor
class CameraScreenViewModel: ObservableObject {
    @Published var isCameraPermissionGranted: Bool? = nil
    @Published var isCameraSessionRunning = false
    
    private let cameraManager: CameraManagerProtocol

    init(cameraManager: CameraManagerProtocol = CameraManager.shared) {
        self.cameraManager = cameraManager
        
        cameraManager.isSessionRunningPublisher
            .receive(on: DispatchQueue.main) // Make sure to update UI on the main thread
            .assign(to: &$isCameraSessionRunning)
    }
    
    func getCameraSession() -> AVCaptureSession? {
        if let cameraManager = cameraManager as? CameraManager {
            return cameraManager.session
        } else {
            return nil
        }
    }

    func requestCameraPermission() async {
        isCameraPermissionGranted = await cameraManager.requestPermission()
    }

    func startCameraSession() {
        cameraManager.startSession()
    }

    func stopCameraSession() {
        cameraManager.stopSession()
    }

    func capturePhoto() async -> String? {
        do {
            return try await cameraManager.capturePhoto()
        } catch {
            print("Error capturing photo: \(error)")
            return nil
        }
    }
}

