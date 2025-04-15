import Foundation
import Combine

class MockCameraManager: CameraManagerProtocol {
    var isSessionRunningPublisher: AnyPublisher<Bool, Never> {
        Just(isSessionRunning).eraseToAnyPublisher()
    }

    var isSessionRunning: Bool = false

    var permissionGranted: Bool = true
    var shouldThrowOnCapture: Bool = false
    var mockCapturedPhotoPath: String? = "/mock/path/photo.jpg"

    private(set) var didRequestPermission = false
    private(set) var didConfigureSession = false
    private(set) var didStartSession = false
    private(set) var didStopSession = false
    private(set) var didCapturePhoto = false

    func requestPermission() async -> Bool {
        didRequestPermission = true
        return permissionGranted
    }

    func configureSession() {
        didConfigureSession = true
    }

    func startSession() {
        didStartSession = true
        isSessionRunning = true
    }

    func stopSession() {
        didStopSession = true
        isSessionRunning = false
    }

    func capturePhoto() async throws -> String? {
        didCapturePhoto = true

        if shouldThrowOnCapture {
            throw CameraManagerError.savingImageFailed
        }

        return mockCapturedPhotoPath
    }
}
